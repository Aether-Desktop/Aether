//! Installation payload source.
//!
//! Release binaries embed the QML shell, applications, themes, scripts and
//! defaults. Development builds can point at a checkout with `--source`, which
//! is also how the integration tests exercise a real tree.

use crate::fsutil;
use crate::paths::is_inside;
use crate::report::{LogLevel, Reporter};
use anyhow::{bail, Context, Result};
use include_dir::{include_dir, Dir};
use std::fs;
use std::path::{Component, Path, PathBuf};

static EMBEDDED_SHELL: Dir<'static> = include_dir!("$CARGO_MANIFEST_DIR/../shell");
static EMBEDDED_APPS: Dir<'static> = include_dir!("$CARGO_MANIFEST_DIR/../apps");
static EMBEDDED_THEMES: Dir<'static> = include_dir!("$CARGO_MANIFEST_DIR/../themes");
static EMBEDDED_CONFIG: Dir<'static> = include_dir!("$CARGO_MANIFEST_DIR/../config");
static EMBEDDED_SCRIPTS: Dir<'static> = include_dir!("$CARGO_MANIFEST_DIR/../scripts");
static EMBEDDED_HYPR: Dir<'static> = include_dir!("$CARGO_MANIFEST_DIR/../hypr");
static EMBEDDED_ASSETS: Dir<'static> = include_dir!("$CARGO_MANIFEST_DIR/../assets");
static EMBEDDED_DOCS: Dir<'static> = include_dir!("$CARGO_MANIFEST_DIR/../docs");

const VERSION_TEXT: &str = include_str!("../../VERSION");
const LICENSE_TEXT: &str = include_str!("../../LICENSE");
const README_TEXT: &str = include_str!("../../README.md");

pub const PAYLOAD_DIRS: [&str; 8] = [
    "shell", "apps", "themes", "config", "scripts", "hypr", "assets", "docs",
];

pub const PAYLOAD_FILES: [&str; 3] = ["VERSION", "LICENSE", "README.md"];

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Source {
    Embedded,
    Directory(PathBuf),
}

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub struct CopyStats {
    pub files: usize,
    pub bytes: u64,
}

impl Source {
    pub fn discover(explicit: Option<PathBuf>) -> Result<Self> {
        if let Some(path) = explicit {
            let path = fs::canonicalize(&path)
                .with_context(|| format!("source directory not found: {}", path.display()))?;
            if !is_repo_root(&path) {
                bail!(
                    "{} is not an AETHER source tree (missing shell/, config/ or themes/)",
                    path.display()
                );
            }
            return Ok(Source::Directory(path));
        }
        if let Some(value) = std::env::var_os("AETHER_SOURCE_DIR") {
            let path = PathBuf::from(value);
            let path = fs::canonicalize(&path).with_context(|| {
                format!(
                    "AETHER_SOURCE_DIR does not exist: {}",
                    path.display()
                )
            })?;
            if !is_repo_root(&path) {
                bail!(
                    "AETHER_SOURCE_DIR={} is not an AETHER source tree",
                    path.display()
                );
            }
            return Ok(Source::Directory(path));
        }
        for start in search_roots() {
            for ancestor in start.ancestors().take(6) {
                if is_repo_root(ancestor) {
                    return Ok(Source::Directory(
                        fs::canonicalize(ancestor).unwrap_or_else(|_| ancestor.to_path_buf()),
                    ));
                }
            }
        }
        Ok(Source::Embedded)
    }

    pub fn label(&self) -> String {
        match self {
            Source::Embedded => "embedded payload".into(),
            Source::Directory(path) => path.display().to_string(),
        }
    }

    pub fn read(&self, rel: &str) -> Result<Vec<u8>> {
        match self {
            Source::Embedded => embedded_read(rel),
            Source::Directory(root) => {
                let path = safe_join(root, rel)?;
                fs::read(&path).with_context(|| format!("could not read {}", path.display()))
            }
        }
    }

    pub fn read_to_string(&self, rel: &str) -> Result<String> {
        let bytes = self.read(rel)?;
        String::from_utf8(bytes).with_context(|| format!("{rel} is not valid UTF-8"))
    }

    pub fn exists(&self, rel: &str) -> bool {
        match self {
            Source::Embedded => embedded_read(rel).is_ok(),
            Source::Directory(root) => safe_join(root, rel)
                .map(|path| path.exists())
                .unwrap_or(false),
        }
    }

    pub fn copy_tree(
        &self,
        rel: &str,
        dest: &Path,
        dry_run: bool,
        reporter: &mut dyn Reporter,
    ) -> Result<CopyStats> {
        match self {
            Source::Embedded => {
                let dir = embedded_dir(rel)
                    .with_context(|| format!("embedded payload is missing {rel}"))?;
                let mut stats = CopyStats::default();
                copy_embedded(dir, dest, dry_run, &mut stats)?;
                reporter.line(
                    if dry_run {
                        LogLevel::DryRun
                    } else {
                        LogLevel::Success
                    },
                    &format!(
                        "{} {} ({} files, {})",
                        if dry_run { "would copy" } else { "copied" },
                        rel,
                        stats.files,
                        crate::distro::human_bytes(stats.bytes)
                    ),
                );
                Ok(stats)
            }
            Source::Directory(root) => {
                let src = safe_join(root, rel)?;
                if !src.is_dir() {
                    bail!("payload directory not found: {}", src.display());
                }
                let mut stats = CopyStats::default();
                copy_directory(&src, dest, dry_run, &mut stats)?;
                reporter.line(
                    if dry_run {
                        LogLevel::DryRun
                    } else {
                        LogLevel::Success
                    },
                    &format!(
                        "{} {} ({} files, {})",
                        if dry_run { "would copy" } else { "copied" },
                        rel,
                        stats.files,
                        crate::distro::human_bytes(stats.bytes)
                    ),
                );
                Ok(stats)
            }
        }
    }

    pub fn copy_file(
        &self,
        rel: &str,
        dest: &Path,
        mode: Option<u32>,
        dry_run: bool,
        reporter: &mut dyn Reporter,
    ) -> Result<()> {
        let bytes = self.read(rel)?;
        if dry_run {
            reporter.line(
                LogLevel::DryRun,
                &format!("would write {}", dest.display()),
            );
            return Ok(());
        }
        fsutil::atomic_write(dest, &bytes, mode)?;
        reporter.line(LogLevel::Success, &format!("wrote {}", dest.display()));
        Ok(())
    }
}

fn search_roots() -> Vec<PathBuf> {
    let mut roots = Vec::new();
    if let Ok(cwd) = std::env::current_dir() {
        roots.push(cwd);
    }
    if let Ok(exe) = std::env::current_exe() {
        if let Some(parent) = exe.parent() {
            roots.push(parent.to_path_buf());
        }
    }
    roots
}

pub fn is_repo_root(path: &Path) -> bool {
    path.join("shell/shell.qml").is_file()
        && path.join("config/config.default.json").is_file()
        && path.join("themes/index.json").is_file()
}

fn safe_join(root: &Path, rel: &str) -> Result<PathBuf> {
    let rel_path = Path::new(rel);
    if rel_path.is_absolute()
        || rel_path
            .components()
            .any(|c| matches!(c, Component::ParentDir | Component::RootDir | Component::Prefix(_)))
    {
        bail!("refusing unsafe payload path: {rel}");
    }
    let joined = root.join(rel_path);
    if !is_inside(&joined, root) && joined != root {
        bail!("payload path escapes source root: {rel}");
    }
    Ok(joined)
}

fn embedded_dir(rel: &str) -> Option<&'static Dir<'static>> {
    match rel {
        "shell" => Some(&EMBEDDED_SHELL),
        "apps" => Some(&EMBEDDED_APPS),
        "themes" => Some(&EMBEDDED_THEMES),
        "config" => Some(&EMBEDDED_CONFIG),
        "scripts" => Some(&EMBEDDED_SCRIPTS),
        "hypr" => Some(&EMBEDDED_HYPR),
        "assets" => Some(&EMBEDDED_ASSETS),
        "docs" => Some(&EMBEDDED_DOCS),
        _ => None,
    }
}

fn embedded_file(rel: &str) -> Option<&'static [u8]> {
    match rel {
        "VERSION" => Some(VERSION_TEXT.as_bytes()),
        "LICENSE" => Some(LICENSE_TEXT.as_bytes()),
        "README.md" => Some(README_TEXT.as_bytes()),
        "themes/index.json" => EMBEDDED_THEMES
            .get_file("index.json")
            .map(|f| f.contents()),
        _ => {
            let (dir, rest) = rel.split_once('/')?;
            embedded_dir(dir)?.get_file(rest).map(|f| f.contents())
        }
    }
}

fn embedded_read(rel: &str) -> Result<Vec<u8>> {
    embedded_file(rel)
        .map(|bytes| bytes.to_vec())
        .with_context(|| format!("embedded payload does not contain {rel}"))
}

fn copy_embedded(
    dir: &Dir<'_>,
    dest: &Path,
    dry_run: bool,
    stats: &mut CopyStats,
) -> Result<()> {
    if !dry_run {
        fs::create_dir_all(dest)
            .with_context(|| format!("could not create {}", dest.display()))?;
    }
    for entry in dir.entries() {
        match entry {
            include_dir::DirEntry::Dir(sub) => {
                let name = sub.path().file_name().unwrap_or_default();
                copy_embedded(sub, &dest.join(name), dry_run, stats)?;
            }
            include_dir::DirEntry::File(file) => {
                let name = file.path().file_name().unwrap_or_default();
                let target = dest.join(name);
                if !dry_run {
                    fsutil::atomic_write(&target, file.contents(), Some(0o644))?;
                }
                stats.files += 1;
                stats.bytes += file.contents().len() as u64;
            }
        }
    }
    Ok(())
}

fn copy_directory(
    src: &Path,
    dest: &Path,
    dry_run: bool,
    stats: &mut CopyStats,
) -> Result<()> {
    if !dry_run {
        fs::create_dir_all(dest)
            .with_context(|| format!("could not create {}", dest.display()))?;
    }
    let entries = fs::read_dir(src).with_context(|| format!("could not list {}", src.display()))?;
    let mut entries = entries
        .collect::<std::result::Result<Vec<_>, _>>()
        .with_context(|| format!("could not list {}", src.display()))?;
    entries.sort_by_key(|e| e.file_name());
    for entry in entries {
        let path = entry.path();
        let meta = fs::symlink_metadata(&path)?;
        if meta.file_type().is_symlink() {
            continue;
        }
        if meta.is_dir() {
            copy_directory(&path, &dest.join(entry.file_name()), dry_run, stats)?;
        } else if meta.is_file() {
            let bytes = fs::read(&path)
                .with_context(|| format!("could not read {}", path.display()))?;
            if !dry_run {
                let target = dest.join(entry.file_name());
                let mode = if is_executable(&meta) { Some(0o755) } else { Some(0o644) };
                fsutil::atomic_write(&target, &bytes, mode)?;
            }
            stats.files += 1;
            stats.bytes += bytes.len() as u64;
        }
    }
    Ok(())
}

fn is_executable(meta: &fs::Metadata) -> bool {
    use std::os::unix::fs::PermissionsExt;
    meta.permissions().mode() & 0o111 != 0
}
