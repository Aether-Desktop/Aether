//! Desktop integration: command links, desktop entries and the application icon.

use crate::fsutil;
use crate::paths::Paths;
use crate::report::{LogLevel, Reporter};
use crate::source::Source;
use anyhow::{Context, Result};
use std::fs;
use std::os::unix::fs::symlink;
use std::path::{Path, PathBuf};

pub const MANAGED_MARKER: &str = "X-AETHER-Managed=true";

#[derive(Debug, Clone, Copy)]
pub struct DesktopApp {
    pub file: &'static str,
    pub name: &'static str,
    pub exec: &'static str,
    pub comment: &'static str,
    pub categories: &'static str,
}

pub const DESKTOP_APPS: [DesktopApp; 7] = [
    DesktopApp {
        file: "aether-settings.desktop",
        name: "AETHER Settings",
        exec: "aether settings",
        comment: "Configure your AETHER desktop",
        categories: "Settings;DesktopSettings;",
    },
    DesktopApp {
        file: "aether-music.desktop",
        name: "AETHER Music",
        exec: "aether music",
        comment: "Play local and streaming music",
        categories: "AudioVideo;Audio;Player;",
    },
    DesktopApp {
        file: "aether-monitor.desktop",
        name: "AETHER System Monitor",
        exec: "aether monitor",
        comment: "Inspect system resources and history",
        categories: "System;Monitor;",
    },
    DesktopApp {
        file: "aether-wallpaper.desktop",
        name: "AETHER Wallpaper",
        exec: "aether wallpaper",
        comment: "Choose a wallpaper and extract its accent",
        categories: "Settings;DesktopSettings;",
    },
    DesktopApp {
        file: "aether-power.desktop",
        name: "AETHER Power",
        exec: "aether power",
        comment: "Lock, suspend, log out or shut down",
        categories: "System;PowerManagement;",
    },
    DesktopApp {
        file: "aether-files.desktop",
        name: "AETHER Files",
        exec: "aether files %U",
        comment: "Browse and preview files",
        categories: "System;FileManager;",
    },
    DesktopApp {
        file: "aether-launcher.desktop",
        name: "AETHER Launcher",
        exec: "aether launcher",
        comment: "Open the AETHER launcher",
        categories: "Utility;",
    },
];

pub fn desktop_entry(app: &DesktopApp) -> String {
    format!(
        "[Desktop Entry]\n\
         Type=Application\n\
         Version=1.0\n\
         Name={}\n\
         Comment={}\n\
         Exec={}\n\
         Icon=aether\n\
         Terminal=false\n\
         Categories={}\n\
         Keywords=AETHER;Desktop;\n\
         StartupNotify=true\n\
         {}\n",
        app.name, app.comment, app.exec, app.categories, MANAGED_MARKER
    )
}

pub struct IntegrationOutcome {
    pub link: PathBuf,
    pub entries: Vec<PathBuf>,
    pub icon: Option<PathBuf>,
    pub warnings: Vec<String>,
}

pub fn install(
    source: &Source,
    paths: &Paths,
    dry_run: bool,
    reporter: &mut dyn Reporter,
) -> Result<IntegrationOutcome> {
    let backups = paths.state_dir.join("backups");
    let link = paths.bin_dir.join("aether");
    let script = paths.data_dir.join("scripts/aether");
    let mut warnings = Vec::new();

    if dry_run {
        reporter.line(
            LogLevel::DryRun,
            &format!("would link {} -> {}", link.display(), script.display()),
        );
    } else {
        fs::create_dir_all(&paths.bin_dir)
            .with_context(|| format!("could not create {}", paths.bin_dir.display()))?;
        replace_link(&link, &script, &backups, &mut warnings)?;
        reporter.line(
            LogLevel::Success,
            &format!("linked {} -> {}", link.display(), script.display()),
        );
    }

    let mut entries = Vec::new();
    if dry_run {
        reporter.line(
            LogLevel::DryRun,
            &format!(
                "would write {} desktop entries to {}",
                DESKTOP_APPS.len(),
                paths.applications_dir.display()
            ),
        );
        for app in DESKTOP_APPS {
            entries.push(paths.applications_dir.join(app.file));
        }
    } else {
        fs::create_dir_all(&paths.applications_dir).with_context(|| {
            format!("could not create {}", paths.applications_dir.display())
        })?;
        for app in DESKTOP_APPS {
            let target = paths.applications_dir.join(app.file);
            let content = desktop_entry(&app);
            if target.exists() {
                let existing = fs::read_to_string(&target).unwrap_or_default();
                if existing != content {
                    fsutil::backup_file(&target, &backups)?;
                }
            }
            fsutil::atomic_write(&target, content.as_bytes(), None)?;
            entries.push(target);
        }
        reporter.line(
            LogLevel::Success,
            &format!(
                "wrote {} desktop entries to {}",
                entries.len(),
                paths.applications_dir.display()
            ),
        );
    }

    let icon = install_icon(source, paths, dry_run, reporter)?;
    Ok(IntegrationOutcome {
        link,
        entries,
        icon,
        warnings,
    })
}

fn replace_link(
    link: &Path,
    target: &Path,
    backups: &Path,
    warnings: &mut Vec<String>,
) -> Result<()> {
    if let Ok(meta) = fs::symlink_metadata(link) {
        if meta.file_type().is_symlink() {
            if let Ok(existing) = fs::read_link(link) {
                if existing == target {
                    return Ok(());
                }
                warnings.push(format!(
                    "replaced existing symlink {} (was {})",
                    link.display(),
                    existing.display()
                ));
                fsutil::remove_file_if_exists(link)?;
            }
        } else if meta.is_file() {
            let backup = fsutil::backup_file(link, backups)?;
            fsutil::remove_file_if_exists(link)?;
            warnings.push(format!(
                "backed up existing {} to {}",
                link.display(),
                backup
                    .map(|p| p.display().to_string())
                    .unwrap_or_default()
            ));
        }
    }
    let temp = link.with_file_name(format!(
        ".aether-link-{}-{}",
        std::process::id(),
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_nanos())
            .unwrap_or(0)
    ));
    let _ = fs::remove_file(&temp);
    symlink(target, &temp)
        .with_context(|| format!("could not create symlink {}", temp.display()))?;
    fs::rename(&temp, link)
        .with_context(|| format!("could not install symlink {}", link.display()))?;
    Ok(())
}

fn install_icon(
    source: &Source,
    paths: &Paths,
    dry_run: bool,
    reporter: &mut dyn Reporter,
) -> Result<Option<PathBuf>> {
    let bytes = source.read("assets/branding/aether-mark.svg")?;
    let target = paths.icons_dir.join("aether.svg");
    if dry_run {
        reporter.line(
            LogLevel::DryRun,
            &format!("would install application icon to {}", target.display()),
        );
        return Ok(Some(target));
    }
    fs::create_dir_all(&paths.icons_dir)
        .with_context(|| format!("could not create {}", paths.icons_dir.display()))?;
    let mut managed = vec![
        b"<!-- AETHER managed icon -->\n".as_slice(),
        bytes.as_slice(),
    ]
    .concat();
    if !managed.ends_with(b"\n") {
        managed.push(b'\n');
    }
    if target.exists() {
        let existing = fs::read(&target).unwrap_or_default();
        if existing != managed {
            fsutil::backup_file(&target, &paths.state_dir.join("backups"))?;
        }
    }
    fsutil::atomic_write(&target, &managed, Some(0o644))?;
    reporter.line(
        LogLevel::Success,
        &format!("installed application icon at {}", target.display()),
    );
    Ok(Some(target))
}

pub fn remove(
    source: &Source,
    paths: &Paths,
    dry_run: bool,
    reporter: &mut dyn Reporter,
) -> Result<()> {
    let script = paths.data_dir.join("scripts/aether");
    let link = paths.bin_dir.join("aether");
    match fs::read_link(&link) {
        Ok(target) if target == script => {
            if dry_run {
                reporter.line(
                    LogLevel::DryRun,
                    &format!("would remove command link {}", link.display()),
                );
            } else {
                fsutil::remove_file_if_exists(&link)?;
                reporter.line(
                    LogLevel::Success,
                    &format!("removed command link {}", link.display()),
                );
            }
        }
        Ok(_) => reporter.line(
            LogLevel::Info,
            &format!("left {} alone: it does not point into AETHER", link.display()),
        ),
        Err(_) => {}
    }

    let mut removed = 0;
    for app in DESKTOP_APPS {
        let target = paths.applications_dir.join(app.file);
        let Ok(text) = fs::read_to_string(&target) else {
            continue;
        };
        if !text.contains(MANAGED_MARKER) {
            reporter.line(
                LogLevel::Info,
                &format!("left user-edited desktop entry {}", target.display()),
            );
            continue;
        }
        if dry_run {
            reporter.line(
                LogLevel::DryRun,
                &format!("would remove desktop entry {}", target.display()),
            );
        } else {
            fsutil::remove_file_if_exists(&target)?;
        }
        removed += 1;
    }
    if removed > 0 {
        reporter.line(
            if dry_run {
                LogLevel::DryRun
            } else {
                LogLevel::Success
            },
            &format!("{} {removed} desktop entries", if dry_run { "would remove" } else { "removed" }),
        );
    }

    let icon = paths.icons_dir.join("aether.svg");
    if let Ok(existing) = fs::read(&icon) {
        let expected = source
            .read("assets/branding/aether-mark.svg")
            .map(|bytes| {
                let mut managed = b"<!-- AETHER managed icon -->\n".to_vec();
                managed.extend_from_slice(&bytes);
                if !managed.ends_with(b"\n") {
                    managed.push(b'\n');
                }
                managed
            })
            .unwrap_or_default();
        if existing == expected {
            if dry_run {
                reporter.line(
                    LogLevel::DryRun,
                    &format!("would remove application icon {}", icon.display()),
                );
            } else {
                fsutil::remove_file_if_exists(&icon)?;
                reporter.line(
                    LogLevel::Success,
                    &format!("removed application icon {}", icon.display()),
                );
            }
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::paths::Paths;
    use crate::report::BufferReporter;

    #[test]
    fn desktop_entry_is_marked_and_points_at_aether() {
        let text = desktop_entry(&DESKTOP_APPS[0]);
        assert!(text.contains("Exec=aether settings"));
        assert!(text.contains(MANAGED_MARKER));
        assert!(text.contains("Icon=aether"));
    }

    #[test]
    fn installs_and_removes_managed_link_and_entries() {
        let dir = tempfile::tempdir().unwrap();
        let paths = Paths::for_test(dir.path());
        let source = Source::discover(Some(
            std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join(".."),
        ))
        .unwrap();
        fs::create_dir_all(paths.data_dir.join("scripts")).unwrap();
        fs::write(paths.data_dir.join("scripts/aether"), "#!/bin/sh\n").unwrap();
        let mut reporter = BufferReporter::default();
        let outcome = install(&source, &paths, false, &mut reporter).unwrap();
        assert_eq!(outcome.entries.len(), DESKTOP_APPS.len());
        assert_eq!(
            fs::read_link(&outcome.link).unwrap(),
            paths.data_dir.join("scripts/aether")
        );
        assert!(outcome.icon.unwrap().exists());

        let mut reporter = BufferReporter::default();
        remove(&source, &paths, false, &mut reporter).unwrap();
        assert!(!outcome.link.exists());
        assert!(!outcome.entries[0].exists());
    }
}
