//! Filesystem primitives shared by the installer.
//!
//! All writes are atomic (temporary file in the target directory followed by a
//! rename). Any file that AETHER replaces is copied to a timestamped backup
//! first, including configuration files and Hyprland's main config.

use anyhow::{Context, Result};
use chrono::Local;
use std::fs;
use std::io::Write;
use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

pub fn timestamp() -> String {
    Local::now().format("%Y%m%d-%H%M%S").to_string()
}

pub fn atomic_write(path: &Path, bytes: &[u8], mode: Option<u32>) -> Result<()> {
    let parent = path
        .parent()
        .with_context(|| format!("cannot determine parent of {}", path.display()))?;
    fs::create_dir_all(parent)
        .with_context(|| format!("could not create {}", parent.display()))?;
    let file_name = path
        .file_name()
        .map(|n| n.to_string_lossy().to_string())
        .unwrap_or_else(|| "aether".into());
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_nanos())
        .unwrap_or(0);
    let temp = parent.join(format!(
        ".{file_name}.aether-tmp-{}-{nanos}",
        std::process::id()
    ));
    let result = (|| -> Result<()> {
        let mut file = fs::File::create(&temp)
            .with_context(|| format!("could not create temporary file {}", temp.display()))?;
        file.write_all(bytes)
            .with_context(|| format!("could not write {}", temp.display()))?;
        file.sync_all()
            .with_context(|| format!("could not flush {}", temp.display()))?;
        if let Some(mode) = mode {
            fs::set_permissions(&temp, fs::Permissions::from_mode(mode))
                .with_context(|| format!("could not set permissions on {}", temp.display()))?;
        }
        fs::rename(&temp, path)
            .with_context(|| format!("could not replace {}", path.display()))?;
        Ok(())
    })();
    if result.is_err() {
        let _ = fs::remove_file(&temp);
    }
    result
}

/// Copy `path` into `backup_dir`, returning the created backup path.
pub fn backup_file(path: &Path, backup_dir: &Path) -> Result<Option<PathBuf>> {
    if !path.exists() {
        return Ok(None);
    }
    fs::create_dir_all(backup_dir)
        .with_context(|| format!("could not create backup directory {}", backup_dir.display()))?;
    let name = path
        .file_name()
        .map(|n| n.to_string_lossy().to_string())
        .unwrap_or_else(|| "file".into());
    let stamp = timestamp();
    let mut target = backup_dir.join(format!("{name}.{stamp}.bak"));
    let mut counter = 1;
    while target.exists() {
        target = backup_dir.join(format!("{name}.{stamp}-{counter}.bak"));
        counter += 1;
    }
    fs::copy(path, &target).with_context(|| {
        format!(
            "could not back up {} to {}",
            path.display(),
            target.display()
        )
    })?;
    Ok(Some(target))
}

/// Move a file aside only if it is not a symlink into AETHER. Returns the
/// backup location when a file was preserved.
pub fn backup_if_regular(path: &Path, backup_dir: &Path) -> Result<Option<PathBuf>> {
    match fs::symlink_metadata(path) {
        Ok(meta) if meta.file_type().is_symlink() => Ok(None),
        Ok(meta) if meta.is_file() => backup_file(path, backup_dir),
        _ => Ok(None),
    }
}

pub fn remove_file_if_exists(path: &Path) -> Result<bool> {
    match fs::remove_file(path) {
        Ok(()) => Ok(true),
        Err(err) if err.kind() == std::io::ErrorKind::NotFound => Ok(false),
        Err(err) => Err(err).with_context(|| format!("could not remove {}", path.display())),
    }
}

pub fn make_executable(path: &Path) -> Result<()> {
    let mut permissions = fs::metadata(path)
        .with_context(|| format!("could not inspect {}", path.display()))?
        .permissions();
    permissions.set_mode(permissions.mode() | 0o755);
    fs::set_permissions(path, permissions)
        .with_context(|| format!("could not make {} executable", path.display()))
}

pub fn read_json(path: &Path) -> Result<Option<serde_json::Value>> {
    if !path.exists() {
        return Ok(None);
    }
    let text = fs::read_to_string(path)
        .with_context(|| format!("could not read {}", path.display()))?;
    if text.trim().is_empty() {
        return Ok(None);
    }
    let value = serde_json::from_str(&text)
        .with_context(|| format!("{} does not contain valid JSON", path.display()))?;
    Ok(Some(value))
}

pub fn write_json(path: &Path, value: &serde_json::Value) -> Result<()> {
    let mut text = serde_json::to_string_pretty(value)?;
    text.push('\n');
    atomic_write(path, text.as_bytes(), None)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn atomic_write_replaces_content() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("a/b/file.txt");
        atomic_write(&path, b"one\n", None).unwrap();
        assert_eq!(fs::read_to_string(&path).unwrap(), "one\n");
        atomic_write(&path, b"two\n", None).unwrap();
        assert_eq!(fs::read_to_string(&path).unwrap(), "two\n");
    }

    #[test]
    fn backup_is_timestamped_and_unique() {
        let dir = tempfile::tempdir().unwrap();
        let file = dir.path().join("config.json");
        let backups = dir.path().join("backups");
        fs::write(&file, "a").unwrap();
        let first = backup_file(&file, &backups).unwrap().unwrap();
        let second = backup_file(&file, &backups).unwrap().unwrap();
        assert!(first.exists());
        assert!(second.exists());
        assert_ne!(first, second);
        assert!(first.to_string_lossy().contains(".bak"));
    }
}
