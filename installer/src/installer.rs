//! Install, repair and uninstall execution.
//!
//! The executor is deliberately independent of the TUI so every destructive
//! operation can be tested against a temporary prefix. No step uses a shell;
//! external programs are invoked with explicit argument vectors.

use crate::config::{build_config, ThemeCatalog};
use crate::distro::{self, Detection};
use crate::fsutil;
use crate::hyprland;
use crate::integration;
use crate::paths;
use crate::plan::{Component, InstallPlan, Mode};
use crate::report::{LogLevel, Reporter};
use anyhow::{bail, Context, Result};
use serde_json::json;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::atomic::{AtomicBool, Ordering};

#[derive(Debug, Clone)]
pub struct RunReport {
    pub mode: Mode,
    pub success: bool,
    pub dry_run: bool,
    pub cancelled: bool,
    pub steps_completed: usize,
    pub total_steps: usize,
    pub log_path: Option<PathBuf>,
    pub errors: Vec<String>,
    pub warnings: Vec<String>,
    pub data_dir: PathBuf,
    pub config_dir: PathBuf,
    pub theme: String,
    pub version: String,
}

impl RunReport {
    pub fn summary(&self) -> String {
        if self.dry_run {
            format!(
                "Dry run finished: {} of {} steps checked",
                self.steps_completed, self.total_steps
            )
        } else if self.cancelled {
            "Installation was cancelled; review the log before retrying".into()
        } else if self.success {
            format!("{} completed successfully", self.mode.label())
        } else {
            format!("{} did not complete", self.mode.label())
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum StepKind {
    Prepare,
    CorePayload,
    Apps,
    Assets,
    Docs,
    HyprStatic,
    Config,
    Scripts,
    Integration,
    HyprApply,
    Packages,
    Marker,
    Verify,
    RemoveIntegration,
    RemoveHypr,
    RemoveData,
    RemoveConfig,
}

impl StepKind {
    fn label(self) -> &'static str {
        match self {
            StepKind::Prepare => "Prepare directories",
            StepKind::CorePayload => "Install shell, themes and defaults",
            StepKind::Apps => "Install application suite",
            StepKind::Assets => "Install wallpapers and branding",
            StepKind::Docs => "Install documentation",
            StepKind::HyprStatic => "Install Hyprland keybind config",
            StepKind::Config => "Merge user configuration",
            StepKind::Scripts => "Install helper scripts",
            StepKind::Integration => "Create command links and desktop entries",
            StepKind::HyprApply => "Apply Hyprland visual settings",
            StepKind::Packages => "Install missing system packages",
            StepKind::Marker => "Write installation marker",
            StepKind::Verify => "Verify installation",
            StepKind::RemoveIntegration => "Remove command links and desktop entries",
            StepKind::RemoveHypr => "Remove AETHER Hyprland include",
            StepKind::RemoveData => "Remove AETHER program files",
            StepKind::RemoveConfig => "Remove user configuration",
        }
    }

    fn critical(self) -> bool {
        !matches!(
            self,
            StepKind::Packages | StepKind::HyprStatic | StepKind::HyprApply
        )
    }
}

struct Runner<'a> {
    plan: &'a InstallPlan,
    detection: &'a Detection,
    reporter: &'a mut dyn Reporter,
    report: RunReport,
}

pub fn execute(
    plan: &InstallPlan,
    detection: &Detection,
    reporter: &mut dyn Reporter,
    cancel: &AtomicBool,
    log_path: Option<PathBuf>,
    version: &str,
) -> RunReport {
    let steps = build_steps(plan);
    let mut report = RunReport {
        mode: plan.mode,
        success: false,
        dry_run: plan.dry_run,
        cancelled: false,
        steps_completed: 0,
        total_steps: steps.len(),
        log_path,
        errors: Vec::new(),
        warnings: Vec::new(),
        data_dir: plan.paths.data_dir.clone(),
        config_dir: plan.paths.config_dir.clone(),
        theme: plan.theme.clone(),
        version: version.to_string(),
    };
    if let Some(issue) = detection.blocking_issue(plan.force_unsupported) {
        report.errors.push(issue.clone());
        reporter.line(LogLevel::Error, &issue);
        reporter.finish(&report);
        return report;
    }

    let mut runner = Runner {
        plan,
        detection,
        reporter,
        report,
    };
    for (index, step) in steps.iter().enumerate() {
        if cancel.load(Ordering::Relaxed) {
            let message = "cancelled by user; no further steps were started".to_string();
            runner.reporter.line(LogLevel::Warn, &message);
            runner.report.warnings.push(message);
            runner.report.cancelled = true;
            break;
        }
        runner
            .reporter
            .step(index + 1, steps.len(), step.label());
        runner
            .reporter
            .line(LogLevel::Info, &format!("== {} ==", step.label()));
        let result = runner.run_step(*step, steps.len());
        match result {
            Ok(()) => {
                runner.report.steps_completed += 1;
            }
            Err(error) => {
                let message = format!("{}: {error:#}", step.label());
                runner.reporter.line(LogLevel::Error, &message);
                runner.report.errors.push(message);
                if step.critical() {
                    break;
                }
                runner.report.warnings.push(format!(
                    "non-critical step failed: {}",
                    step.label()
                ));
            }
        }
    }
    runner.report.success = runner.report.errors.is_empty() && !runner.report.cancelled;
    let report = runner.report;
    reporter.finish(&report);
    report
}

fn build_steps(plan: &InstallPlan) -> Vec<StepKind> {
    let mut steps = Vec::new();
    if plan.mode == Mode::Uninstall {
        steps.push(StepKind::RemoveIntegration);
        if plan.has(Component::Hyprland) {
            steps.push(StepKind::RemoveHypr);
        }
        steps.push(StepKind::RemoveData);
        if !plan.keep_config {
            steps.push(StepKind::RemoveConfig);
        }
        return steps;
    }
    steps.push(StepKind::Prepare);
    steps.push(StepKind::CorePayload);
    if plan.has(Component::Apps) {
        steps.push(StepKind::Apps);
    }
    if plan.has(Component::Wallpapers) {
        steps.push(StepKind::Assets);
    }
    steps.push(StepKind::Scripts);
    steps.push(StepKind::Docs);
    if plan.has(Component::Hyprland) {
        steps.push(StepKind::HyprStatic);
    }
    steps.push(StepKind::Config);
    if plan.has(Component::Integration) {
        steps.push(StepKind::Integration);
    }
    if plan.has(Component::Hyprland) {
        steps.push(StepKind::HyprApply);
    }
    if plan.has(Component::Packages) {
        steps.push(StepKind::Packages);
    }
    steps.push(StepKind::Marker);
    steps.push(StepKind::Verify);
    steps
}

impl Runner<'_> {
    fn run_step(&mut self, step: StepKind, total: usize) -> Result<()> {
        match step {
            StepKind::Prepare => self.prepare(),
            StepKind::CorePayload => self.core_payload(),
            StepKind::Apps => self.copy_dir("apps", &self.plan.paths.data_dir.join("apps")),
            StepKind::Assets => self.copy_dir("assets", &self.plan.paths.data_dir.join("assets")),
            StepKind::Docs => self.copy_dir_optional("docs", &self.plan.paths.data_dir.join("docs")),
            StepKind::HyprStatic => {
                let path = hyprland::install_static(
                    &self.plan.source,
                    &self.plan.paths,
                    self.plan.dry_run,
                    self.reporter,
                )?;
                self.reporter
                    .line(LogLevel::Info, &format!("AETHER keybinds: {}", path.display()));
                Ok(())
            }
            StepKind::Config => self.write_config(),
            StepKind::Scripts => self.install_scripts(),
            StepKind::Integration => self.integrate(),
            StepKind::HyprApply => self.apply_hyprland(total),
            StepKind::Packages => self.install_packages(),
            StepKind::Marker => self.write_marker(),
            StepKind::Verify => self.verify(),
            StepKind::RemoveIntegration => integration::remove(
                &self.plan.source,
                &self.plan.paths,
                self.plan.dry_run,
                self.reporter,
            ),
            StepKind::RemoveHypr => hyprland::remove_managed_include(
                &self.plan.paths.hypr_dir().join("hyprland.conf"),
                &self.plan.paths.hypr_dir().join("aether/backups"),
                self.plan.dry_run,
                self.reporter,
            )
            .map(|_| ()),
            StepKind::RemoveData => self.remove_data(),
            StepKind::RemoveConfig => self.remove_config(),
        }
    }

    fn prepare(&mut self) -> Result<()> {
        let dirs = [
            self.plan.paths.data_dir.clone(),
            self.plan.paths.config_dir.clone(),
            self.plan.paths.state_dir.clone(),
            self.plan.paths.state_dir.join("backups"),
        ];
        for dir in dirs {
            if self.plan.dry_run {
                self.reporter
                    .line(LogLevel::DryRun, &format!("would create {}", dir.display()));
            } else {
                paths::ensure_dir(&dir)?;
            }
        }
        Ok(())
    }

    fn copy_dir(&mut self, rel: &str, dest: &Path) -> Result<()> {
        let stats = self
            .plan
            .source
            .copy_tree(rel, dest, self.plan.dry_run, self.reporter)?;
        if stats.files == 0 {
            bail!("payload directory {rel} is empty");
        }
        Ok(())
    }

    fn copy_dir_optional(&mut self, rel: &str, dest: &Path) -> Result<()> {
        let stats = self
            .plan
            .source
            .copy_tree(rel, dest, self.plan.dry_run, self.reporter)?;
        if stats.files == 0 {
            self.reporter.line(
                LogLevel::Info,
                &format!("no {rel} files in this payload; skipped"),
            );
        }
        Ok(())
    }

    fn core_payload(&mut self) -> Result<()> {
        let data = self.plan.paths.data_dir.clone();
        self.copy_dir("shell", &data.join("shell"))?;
        self.copy_dir("themes", &data.join("themes"))?;
        self.copy_dir("config", &data.join("config"))?;
        for file in crate::source::PAYLOAD_FILES {
            self.plan.source.copy_file(
                file,
                &data.join(file),
                None,
                self.plan.dry_run,
                self.reporter,
            )?;
        }
        Ok(())
    }

    fn install_scripts(&mut self) -> Result<()> {
        let scripts = self.plan.paths.data_dir.join("scripts");
        self.copy_dir("scripts", &scripts)?;
        if self.plan.dry_run {
            self.reporter.line(
                LogLevel::DryRun,
                "would make AETHER helper scripts executable",
            );
            return Ok(());
        }
        for name in [
            "aether",
            "aether-hyprland",
            "aether-stats",
            "aether-terminal",
            "aether-wallpaper",
        ] {
            fsutil::make_executable(&scripts.join(name))?;
        }
        self.reporter
            .line(LogLevel::Success, "made helper scripts executable");
        Ok(())
    }

    fn write_config(&mut self) -> Result<()> {
        let catalog = ThemeCatalog::load(&self.plan.source)?;
        if catalog.get(&self.plan.theme).is_none() {
            bail!("selected theme '{}' is not in themes/index.json", self.plan.theme);
        }
        let request = crate::config::ConfigRequest {
            source: &self.plan.source,
            theme: &self.plan.theme,
            manage_hyprland: self.plan.manage_hyprland,
        };
        let outcome = crate::config::write_user_config(
            &request,
            &self.plan.paths.config_dir,
            self.plan.dry_run,
            self.reporter,
        )?;
        if let Some(path) = outcome.config_path {
            self.reporter
                .line(LogLevel::Info, &format!("configuration: {}", path.display()));
        }
        Ok(())
    }

    fn integrate(&mut self) -> Result<()> {
        let outcome = integration::install(
            &self.plan.source,
            &self.plan.paths,
            self.plan.dry_run,
            self.reporter,
        )?;
        self.report.warnings.extend(outcome.warnings);
        Ok(())
    }

    fn apply_hyprland(&mut self, _total: usize) -> Result<()> {
        let default_text = self
            .plan
            .source
            .read_to_string("config/config.default.json")?;
        let default: serde_json::Value = serde_json::from_str(&default_text)?;
        let config_path = self.plan.paths.config_dir.join("config.json");
        let config = fsutil::read_json(&config_path)?.unwrap_or(default);
        let merged = build_config(
            config.clone(),
            Some(config),
            &self.plan.theme,
            self.plan.manage_hyprland,
        );
        let settings = hyprland::settings_from_config(&merged);
        let catalog = ThemeCatalog::load(&self.plan.source)?;
        let theme = catalog
            .get(&self.plan.theme)
            .with_context(|| format!("theme '{}' not found", self.plan.theme))?;
        let colors = hyprland::colors_from_source(&self.plan.source, &theme.id, &theme.file);
        let outcome = hyprland::apply(
            &self.plan.paths,
            &settings,
            &colors,
            self.plan.manage_hyprland,
            self.plan.dry_run,
            self.reporter,
        )?;
        self.reporter.line(
            LogLevel::Info,
            &format!("generated config: {}", outcome.generated.display()),
        );
        if outcome.main_changed {
            self.reporter.line(
                LogLevel::Info,
                "run `hyprctl reload` or restart Hyprland to apply compositor changes",
            );
        }
        Ok(())
    }

    fn install_packages(&mut self) -> Result<()> {
        if !self.detection.arch_supported {
            bail!(
                "system package installation is only implemented for Arch Linux; \
                 install the dependencies listed in docs/installation.md manually"
            );
        }
        if !distro::command_exists("pacman") {
            bail!("pacman is not available");
        }
        let missing = distro::missing_packages(&distro::supported_packages());
        if missing.is_empty() {
            self.reporter
                .line(LogLevel::Success, "all AETHER packages are already installed");
            return Ok(());
        }
        let mut command = Command::new("sudo");
        command
            .arg("-n")
            .arg("pacman")
            .arg("-S")
            .arg("--needed")
            .arg("--noconfirm")
            .args(&missing);
        let printable = format!(
            "sudo -n pacman -S --needed --noconfirm {}",
            missing.join(" ")
        );
        if self.plan.dry_run {
            self.reporter
                .line(LogLevel::DryRun, &format!("would run: {printable}"));
            return Ok(());
        }
        self.reporter.line(LogLevel::Command, &printable);
        let output = command
            .output()
            .context("could not run sudo; install the packages manually")?;
        for line in String::from_utf8_lossy(&output.stdout).lines() {
            self.reporter.line(LogLevel::Info, line);
        }
        for line in String::from_utf8_lossy(&output.stderr).lines() {
            self.reporter.line(LogLevel::Warn, line);
        }
        if !output.status.success() {
            bail!(
                "sudo -n pacman failed (exit {}). Either authenticate sudo in a terminal \
                 first (`sudo -v`) and retry, or run manually:\n{printable}",
                output.status.code().unwrap_or(-1)
            );
        }
        self.reporter
            .line(LogLevel::Success, "system packages installed");
        Ok(())
    }

    fn write_marker(&mut self) -> Result<()> {
        let marker = json!({
            "schemaVersion": 1,
            "version": self.report.version,
            "installedAt": chrono::Local::now().to_rfc3339(),
            "mode": self.plan.mode.lower(),
            "prefix": self.plan.paths.prefix,
            "dataDir": self.plan.paths.data_dir,
            "configDir": self.plan.paths.config_dir,
            "theme": self.plan.theme,
            "components": self.plan.component_ids(),
            "source": self.plan.source.label(),
        });
        let path = self.plan.paths.data_dir.join(".aether-install.json");
        if self.plan.dry_run {
            self.reporter.line(
                LogLevel::DryRun,
                &format!("would write installation marker to {}", path.display()),
            );
            return Ok(());
        }
        fsutil::write_json(&path, &marker)?;
        self.reporter
            .line(LogLevel::Success, &format!("wrote {}", path.display()));
        Ok(())
    }

    fn verify(&mut self) -> Result<()> {
        if self.plan.dry_run {
            self.reporter
                .line(LogLevel::DryRun, "would verify installed files");
            return Ok(());
        }
        let data = &self.plan.paths.data_dir;
        let required = [
            data.join("shell/shell.qml"),
            data.join("themes/index.json"),
            data.join("config/config.default.json"),
            data.join("scripts/aether"),
            data.join(".aether-install.json"),
        ];
        for path in required {
            if !path.exists() {
                bail!("missing required file {}", path.display());
            }
        }
        let config = self.plan.paths.config_dir.join("config.json");
        if !config.is_file() {
            bail!("configuration was not written to {}", config.display());
        }
        if self.plan.has(Component::Integration) {
            match fs::read_link(self.plan.paths.bin_dir.join("aether")) {
                Ok(target) if target == data.join("scripts/aether") => {}
                _ => bail!(
                    "{} does not point at the installed aether command",
                    self.plan.paths.bin_dir.join("aether").display()
                ),
            }
        }
        self.reporter
            .line(LogLevel::Success, "verified shell, theme, config and command link");
        Ok(())
    }

    fn remove_data(&mut self) -> Result<()> {
        let data = &self.plan.paths.data_dir;
        if !data.exists() {
            self.reporter.line(
                LogLevel::Info,
                &format!("{} does not exist; nothing to remove", data.display()),
            );
            return Ok(());
        }
        let marker = data.join(".aether-install.json");
        if !marker.is_file() {
            bail!(
                "refusing to remove {}: .aether-install.json is missing. Remove it manually \
                 if it really is an AETHER data directory.",
                data.display()
            );
        }
        if self.plan.dry_run {
            self.reporter.line(
                LogLevel::DryRun,
                &format!("would remove {}", data.display()),
            );
            return Ok(());
        }
        fs::remove_dir_all(data)
            .with_context(|| format!("could not remove {}", data.display()))?;
        self.reporter
            .line(LogLevel::Success, &format!("removed {}", data.display()));
        Ok(())
    }

    fn remove_config(&mut self) -> Result<()> {
        let config = &self.plan.paths.config_dir;
        if !config.exists() {
            self.reporter.line(
                LogLevel::Info,
                &format!("{} does not exist; nothing to remove", config.display()),
            );
            return Ok(());
        }
        let backup_root = self.plan.paths.state_dir.join("uninstalled-config");
        if self.plan.dry_run {
            self.reporter.line(
                LogLevel::DryRun,
                &format!(
                    "would back up and remove user configuration at {}",
                    config.display()
                ),
            );
            return Ok(());
        }
        let backup = backup_root.join(fsutil::timestamp());
        copy_dir_all(config, &backup)?;
        fs::remove_dir_all(config)
            .with_context(|| format!("could not remove {}", config.display()))?;
        self.reporter.line(
            LogLevel::Success,
            &format!(
                "removed user configuration (backup: {})",
                backup.display()
            ),
        );
        Ok(())
    }
}

fn copy_dir_all(src: &Path, dest: &Path) -> Result<()> {
    fs::create_dir_all(dest)?;
    for entry in fs::read_dir(src)? {
        let entry = entry?;
        let path = entry.path();
        let target = dest.join(entry.file_name());
        let meta = fs::symlink_metadata(&path)?;
        if meta.is_dir() {
            copy_dir_all(&path, &target)?;
        } else if meta.is_file() {
            fs::copy(&path, &target)?;
        }
    }
    Ok(())
}

/// Helper used by the CLI when `--dry-run` is combined with non-interactive
/// output (and by tests): run the full plan and render the log to stdout.
pub fn run_headless(
    plan: &InstallPlan,
    detection: &Detection,
    version: &str,
) -> Result<RunReport> {
    use crate::report::LogLine;
    let mut reporter = crate::report::BufferReporter::default();
    let cancel = AtomicBool::new(false);
    let report = execute(plan, detection, &mut reporter, &cancel, None, version);
    for LogLine { level, text } in &reporter.lines {
        let prefix = match level {
            LogLevel::Info => "  ",
            LogLevel::Success => "ok",
            LogLevel::Warn => "!!",
            LogLevel::Error => "EE",
            LogLevel::Command => "$ ",
            LogLevel::DryRun => "..",
        };
        println!("{prefix} {text}");
    }
    Ok(report)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::distro::Detection;
    use crate::paths::Paths;
    use crate::plan::{Profile, InstallPlan};
    use crate::report::BufferReporter;
    use crate::source::Source;
    use std::path::Path;

    fn test_source() -> Source {
        Source::discover(Some(Path::new(env!("CARGO_MANIFEST_DIR")).join(".."))).unwrap()
    }

    fn test_plan(root: &Path) -> InstallPlan {
        let paths = Paths::for_test(root);
        let mut plan = InstallPlan::new(paths, test_source(), "aether-dark".into());
        plan.components = Profile::Standard.components();
        plan.manage_hyprland = true;
        plan
    }

    fn detection(dir: &Path) -> Detection {
        distro::detect(&Paths::for_test(dir))
    }

    #[test]
    fn dry_run_does_not_touch_the_filesystem() {
        let dir = tempfile::tempdir().unwrap();
        let mut plan = test_plan(dir.path());
        plan.dry_run = true;
        let mut reporter = BufferReporter::default();
        let cancel = AtomicBool::new(false);
        let report = execute(
            &plan,
            &detection(dir.path()),
            &mut reporter,
            &cancel,
            None,
            "1.0.0",
        );
        assert!(report.success);
        assert!(!dir.path().join("prefix/share/aether").exists());
        assert!(!dir.path().join("config/aether/config.json").exists());
        assert!(reporter
            .lines
            .iter()
            .any(|l| l.level == LogLevel::DryRun));
    }

    #[test]
    fn installs_into_a_temporary_prefix_and_preserves_config() {
        let dir = tempfile::tempdir().unwrap();
        let mut plan = test_plan(dir.path());
        plan.force_unsupported = true;
        std::fs::create_dir_all(&plan.paths.config_dir).unwrap();
        std::fs::write(
            plan.paths.config_dir.join("config.json"),
            r#"{"bar":{"height":61},"custom":{"keep":true}}"#,
        )
        .unwrap();
        std::fs::create_dir_all(plan.paths.hypr_dir()).unwrap();
        std::fs::write(
            plan.paths.hypr_dir().join("hyprland.conf"),
            "# existing hyprland config\n",
        )
        .unwrap();
        let mut reporter = BufferReporter::default();
        let cancel = AtomicBool::new(false);
        let report = execute(
            &plan,
            &detection(dir.path()),
            &mut reporter,
            &cancel,
            None,
            "1.0.0",
        );
        assert!(report.success, "errors: {:?}", report.errors);
        assert!(plan.paths.data_dir.join("shell/shell.qml").is_file());
        assert!(plan.paths.data_dir.join(".aether-install.json").is_file());
        assert!(plan.paths.config_dir.join("backups").is_dir());
        let config = fsutil::read_json(&plan.paths.config_dir.join("config.json"))
            .unwrap()
            .unwrap();
        assert_eq!(config["bar"]["height"], 61);
        assert_eq!(config["custom"]["keep"], true);
        assert_eq!(config["appearance"]["theme"], "aether-dark");
        let link = plan.paths.bin_dir.join("aether");
        assert_eq!(
            std::fs::read_link(link).unwrap(),
            plan.paths.data_dir.join("scripts/aether")
        );
        let hypr = plan.paths.hypr_dir().join("hyprland.conf");
        assert!(std::fs::read_to_string(hypr)
            .unwrap()
            .contains(hyprland::BEGIN_MARK));
    }

    #[test]
    fn uninstall_refuses_without_a_marker() {
        let dir = tempfile::tempdir().unwrap();
        let paths = Paths::for_test(dir.path());
        std::fs::create_dir_all(&paths.data_dir).unwrap();
        let mut plan = InstallPlan::new(paths, test_source(), "aether-dark".into());
        plan.mode = Mode::Uninstall;
        plan.force_unsupported = true;
        let mut reporter = BufferReporter::default();
        let cancel = AtomicBool::new(false);
        let report = execute(
            &plan,
            &detection(dir.path()),
            &mut reporter,
            &cancel,
            None,
            "1.0.0",
        );
        assert!(!report.success);
        assert!(report.errors.iter().any(|e| e.contains("refusing")));
        assert!(plan.paths.data_dir.exists());
    }
}
