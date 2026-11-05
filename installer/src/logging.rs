//! Installer log files.
//!
//! Every run writes a complete log to `$XDG_STATE_HOME/aether/logs`. The TUI
//! shows the same lines; the file is the source of truth after the screen is
//! gone.

use crate::report::LogLevel;
use anyhow::{Context, Result};
use std::fs::{self, File, OpenOptions};
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};

#[derive(Clone)]
pub struct Logger {
    path: PathBuf,
    file: Arc<Mutex<File>>,
}

impl Logger {
    pub fn create(log_dir: &Path, mode: &str) -> Result<Self> {
        let result = Self::create_in(log_dir, mode);
        match result {
            Ok(logger) => Ok(logger),
            Err(_) => {
                // A read-only or broken state directory must not prevent the
                // installer from showing an error. Keep the log in /tmp.
                let fallback = std::env::temp_dir().join("aether-installer-logs");
                Self::create_in(&fallback, mode)
                    .context("could not create a log file in the state directory or /tmp")
            }
        }
    }

    fn create_in(log_dir: &Path, mode: &str) -> Result<Self> {
        fs::create_dir_all(log_dir)
            .with_context(|| format!("could not create {}", log_dir.display()))?;
        let stamp = chrono::Local::now().format("%Y%m%d-%H%M%S");
        let mut path = log_dir.join(format!("aether-{mode}-{stamp}.log"));
        let mut counter = 1;
        while path.exists() {
            path = log_dir.join(format!("aether-{mode}-{stamp}-{counter}.log"));
            counter += 1;
        }
        let file = OpenOptions::new()
            .create_new(true)
            .write(true)
            .open(&path)
            .with_context(|| format!("could not create {}", path.display()))?;
        let logger = Self {
            path,
            file: Arc::new(Mutex::new(file)),
        };
        logger.line(
            LogLevel::Info,
            &format!(
                "AETHER installer {} ({}) started {}",
                crate::version(),
                mode,
                chrono::Local::now().to_rfc3339()
            ),
        );
        logger.line(
            LogLevel::Info,
            "commands are executed without a shell; passwords are never logged",
        );
        Ok(logger)
    }

    pub fn path(&self) -> &Path {
        &self.path
    }

    pub fn line(&self, level: LogLevel, message: &str) {
        let label = match level {
            LogLevel::Info => "INFO",
            LogLevel::Success => " OK ",
            LogLevel::Warn => "WARN",
            LogLevel::Error => "FAIL",
            LogLevel::Command => "EXEC",
            LogLevel::DryRun => "DRY ",
        };
        if let Ok(mut file) = self.file.lock() {
            let _ = writeln!(file, "[{label}] {message}");
            let _ = file.flush();
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn creates_a_unique_log_file() {
        let dir = tempfile::tempdir().unwrap();
        let first = Logger::create(dir.path(), "install").unwrap();
        let second = Logger::create(dir.path(), "install").unwrap();
        assert_ne!(first.path(), second.path());
        first.line(LogLevel::Info, "hello");
        let text = fs::read_to_string(first.path()).unwrap();
        assert!(text.contains("hello"));
        assert!(text.contains("AETHER installer"));
    }
}
