//! Command-line entry point for the AETHER installer.

use aether_installer::app::{self, Options};
use aether_installer::installer::RunReport;
use aether_installer::plan::Mode;
use anyhow::{bail, Result};
use std::io::IsTerminal;
use std::path::PathBuf;
use std::process::ExitCode;

const HELP: &str = "\
AETHER installer — Your desktop. Your atmosphere. Your AETHER.

Usage:
  aether-installer [OPTIONS]

Modes:
  (default)             Install or update AETHER
  --repair              Reinstall files and integrations, preserving settings
  --uninstall           Remove program files and integrations

Options:
  --dry-run             Walk through every step without changing anything
  --prefix <PATH>       Install prefix (default: ~/.local)
  --source <PATH>       Use a checkout instead of the embedded payload
  --theme <ID>          Preselect a theme from themes/index.json
  --keep-config         Uninstall: keep ~/.config/aether (default)
  --remove-config       Uninstall: back up, then remove ~/.config/aether
  --force-unsupported   Continue on a distribution other than Arch Linux
  --headless            Print a dry-run report instead of opening the TUI
  -h, --help            Show this help
  -V, --version         Print the AETHER version

The installer writes timestamped backups before replacing configuration. It
never pipes remote content into a shell and never passes user input through a
shell. Package installation uses `sudo -n pacman` and requires cached sudo
credentials (`sudo -v` in another terminal first).

Exit status is 0 on success, 1 when an install fails, and 2 for invalid usage.
";

fn main() -> ExitCode {
    match execute() {
        Ok(code) => code,
        Err(error) => {
            eprintln!("aether-installer: {error:#}");
            ExitCode::from(2)
        }
    }
}

fn execute() -> Result<ExitCode> {
    let Some(options) = parse_args(std::env::args().skip(1))? else {
        return Ok(ExitCode::SUCCESS);
    };
    let interactive = std::io::stdin().is_terminal() && std::io::stdout().is_terminal();
    if options.headless || !interactive {
        if !options.dry_run {
            bail!(
                "the interactive TUI needs a terminal; re-run with --dry-run --headless \
                 for a non-mutating check"
            );
        }
        let report = app::run_headless(options)?;
        print_report(&report);
        return Ok(if report.success {
            ExitCode::SUCCESS
        } else {
            ExitCode::from(1)
        });
    }
    app::run(options)?;
    Ok(ExitCode::SUCCESS)
}

#[derive(Debug, Default)]
struct Parsed {
    help: bool,
    version: bool,
    dry_run: bool,
    headless: bool,
    force_unsupported: bool,
    prefix: Option<PathBuf>,
    source: Option<PathBuf>,
    theme: Option<String>,
    mode: Option<Mode>,
    keep_config: Option<bool>,
}

impl From<Parsed> for Options {
    fn from(parsed: Parsed) -> Self {
        Options {
            prefix: parsed.prefix,
            source: parsed.source,
            mode: parsed.mode,
            theme: parsed.theme,
            dry_run: parsed.dry_run,
            force_unsupported: parsed.force_unsupported,
            keep_config: parsed.keep_config,
            headless: parsed.headless,
        }
    }
}

fn parse_args(args: impl Iterator<Item = String>) -> Result<Option<Options>> {
    let mut parsed = Parsed::default();
    let mut args = args.peekable();
    while let Some(argument) = args.next() {
        match argument.as_str() {
            "-h" | "--help" => parsed.help = true,
            "-V" | "--version" => parsed.version = true,
            "--dry-run" => parsed.dry_run = true,
            "--headless" | "--no-tui" => parsed.headless = true,
            "--force-unsupported" => parsed.force_unsupported = true,
            "--repair" => set_mode(&mut parsed, Mode::Repair)?,
            "--uninstall" => set_mode(&mut parsed, Mode::Uninstall)?,
            "--install" => set_mode(&mut parsed, Mode::Install)?,
            "--keep-config" => parsed.keep_config = Some(true),
            "--remove-config" => parsed.keep_config = Some(false),
            "--prefix" => {
                parsed.prefix = Some(PathBuf::from(value(&mut args, "--prefix")?));
            }
            "--source" => {
                parsed.source = Some(PathBuf::from(value(&mut args, "--source")?));
            }
            "--theme" => parsed.theme = Some(value(&mut args, "--theme")?),
            _ if argument.starts_with("--prefix=") => {
                parsed.prefix = Some(PathBuf::from(argument.trim_start_matches("--prefix=")));
            }
            _ if argument.starts_with("--source=") => {
                parsed.source = Some(PathBuf::from(argument.trim_start_matches("--source=")));
            }
            _ if argument.starts_with("--theme=") => {
                parsed.theme = Some(argument.trim_start_matches("--theme=").to_string());
            }
            _ => bail!("unknown option: {argument}\n\nUse --help for the available options."),
        }
    }
    if parsed.help {
        print!("{HELP}");
        return Ok(None);
    }
    if parsed.version {
        println!("AETHER {}", aether_installer::version());
        return Ok(None);
    }
    if parsed
        .theme
        .as_ref()
        .map(|t| t.trim().is_empty())
        .unwrap_or(false)
    {
        bail!("--theme cannot be empty");
    }
    Ok(Some(parsed.into()))
}

fn set_mode(parsed: &mut Parsed, mode: Mode) -> Result<()> {
    if let Some(existing) = parsed.mode {
        if existing != mode {
            bail!(
                "--{} and --{} cannot be combined",
                existing.lower(),
                mode.lower()
            );
        }
    }
    parsed.mode = Some(mode);
    Ok(())
}

fn value<T>(args: &mut std::iter::Peekable<T>, option: &str) -> Result<String>
where
    T: Iterator<Item = String>,
{
    match args.next() {
        Some(value) if !value.is_empty() => Ok(value),
        _ => bail!("{option} requires a value"),
    }
}

fn print_report(report: &RunReport) {
    println!("{}", report.summary());
    println!("Steps: {}/{}", report.steps_completed, report.total_steps);
    println!("Data:  {}", report.data_dir.display());
    println!("Config:{}", report.config_dir.display());
    println!("Theme: {}", report.theme);
    if let Some(path) = &report.log_path {
        println!("Log:   {}", path.display());
    }
    for warning in &report.warnings {
        eprintln!("warning: {warning}");
    }
    for error in &report.errors {
        eprintln!("error: {error}");
    }
}
