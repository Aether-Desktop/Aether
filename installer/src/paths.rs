//! XDG-aware install paths.
//!
//! AETHER installs per-user by default. Every path is derived from environment
//! variables so the installer can be tested against a temporary prefix without
//! touching the real home directory.

use anyhow::{bail, Context, Result};
use std::env;
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Paths {
    pub home: PathBuf,
    pub prefix: PathBuf,
    pub data_dir: PathBuf,
    pub bin_dir: PathBuf,
    pub config_home: PathBuf,
    pub config_dir: PathBuf,
    pub state_dir: PathBuf,
    pub applications_dir: PathBuf,
    pub icons_dir: PathBuf,
    pub log_dir: PathBuf,
}

impl Paths {
    /// Build paths from the current environment. `prefix` defaults to
    /// `$HOME/.local`.
    pub fn from_env(prefix: Option<PathBuf>) -> Result<Self> {
        let home = env::var_os("HOME")
            .map(PathBuf::from)
            .filter(|p| !p.as_os_str().is_empty())
            .context("HOME is not set")?;
        let prefix = match prefix {
            Some(p) => expand_tilde(&p, &home),
            None => home.join(".local"),
        };
        if !prefix.is_absolute() {
            bail!(
                "install prefix must be absolute (got {})",
                prefix.display()
            );
        }
        let config_home = env_path("XDG_CONFIG_HOME").unwrap_or_else(|| home.join(".config"));
        let state_home = env_path("XDG_STATE_HOME").unwrap_or_else(|| home.join(".local/state"));
        let data_home = env_path("XDG_DATA_HOME").unwrap_or_else(|| home.join(".local/share"));
        Ok(Self {
            home,
            data_dir: prefix.join("share/aether"),
            bin_dir: prefix.join("bin"),
            config_home: config_home.clone(),
            config_dir: config_home.join("aether"),
            state_dir: state_home.join("aether"),
            applications_dir: data_home.join("applications"),
            icons_dir: data_home.join("icons/hicolor/scalable/apps"),
            log_dir: state_home.join("aether/logs"),
            prefix,
        })
    }

    /// Construct an isolated set of paths below `root`. Only used by tests.
    pub fn for_test(root: &Path) -> Self {
        Self {
            home: root.join("home"),
            prefix: root.join("prefix"),
            data_dir: root.join("prefix/share/aether"),
            bin_dir: root.join("prefix/bin"),
            config_home: root.join("config"),
            config_dir: root.join("config/aether"),
            state_dir: root.join("state/aether"),
            applications_dir: root.join("data/applications"),
            icons_dir: root.join("data/icons/hicolor/scalable/apps"),
            log_dir: root.join("state/aether/logs"),
        }
    }

    pub fn hypr_dir(&self) -> PathBuf {
        self.config_home.join("hypr")
    }
}

fn env_path(name: &str) -> Option<PathBuf> {
    env::var_os(name)
        .map(PathBuf::from)
        .filter(|p| !p.as_os_str().is_empty())
}

pub fn expand_tilde(path: &Path, home: &Path) -> PathBuf {
    let text = path.to_string_lossy();
    if text == "~" {
        return home.to_path_buf();
    }
    if let Some(rest) = text.strip_prefix("~/") {
        return home.join(rest);
    }
    path.to_path_buf()
}

/// Ensure a directory exists, with a dry-run aware wrapper kept in the caller.
pub fn ensure_dir(path: &Path) -> Result<()> {
    std::fs::create_dir_all(path)
        .with_context(|| format!("could not create directory {}", path.display()))
}

/// Check that `candidate` is inside `root` after lexical normalisation. Used
/// before any recursive removal.
pub fn is_inside(candidate: &Path, root: &Path) -> bool {
    let candidate = normalize(candidate);
    let root = normalize(root);
    candidate != root && candidate.starts_with(&root)
}

pub fn normalize(path: &Path) -> PathBuf {
    let mut out = PathBuf::new();
    for component in path.components() {
        match component {
            std::path::Component::ParentDir => {
                out.pop();
            }
            std::path::Component::CurDir => {}
            other => out.push(other.as_os_str()),
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn tilde_expansion() {
        let home = Path::new("/home/tester");
        assert_eq!(expand_tilde(Path::new("~/x"), home), home.join("x"));
        assert_eq!(expand_tilde(Path::new("~"), home), home);
        assert_eq!(expand_tilde(Path::new("/opt/x"), home), PathBuf::from("/opt/x"));
    }

    #[test]
    fn detects_nested_paths_without_prefix_confusion() {
        assert!(is_inside(
            Path::new("/home/u/.local/share/aether/shell"),
            Path::new("/home/u/.local/share/aether")
        ));
        assert!(!is_inside(
            Path::new("/home/u/.local/share/aether-evil"),
            Path::new("/home/u/.local/share/aether")
        ));
        assert!(!is_inside(
            Path::new("/home/u/.local/share/aether"),
            Path::new("/home/u/.local/share/aether")
        ));
    }
}
