//! Interactive TUI application state and event loop.

use crate::config::ThemeCatalog;
use crate::distro::{self, Detection};
use crate::installer::{self, RunReport};
use crate::logging::Logger;
use crate::paths::Paths;
use crate::plan::{Component, InstallPlan, Mode, Profile};
use crate::report::{LogLevel, LogLine, Reporter};
use crate::source::Source;
use crate::tui;
use anyhow::{Context, Result};
use crossterm::event::{self, Event, KeyCode, KeyEvent, KeyEventKind, KeyModifiers};
use std::path::PathBuf;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::mpsc::{self, Receiver, Sender};
use std::sync::Arc;
use std::time::{Duration, Instant};

#[derive(Debug, Clone, Default)]
pub struct Options {
    pub prefix: Option<PathBuf>,
    pub source: Option<PathBuf>,
    pub mode: Option<Mode>,
    pub theme: Option<String>,
    pub dry_run: bool,
    pub force_unsupported: bool,
    pub keep_config: Option<bool>,
    pub headless: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Screen {
    Welcome,
    Detection,
    Profiles,
    Components,
    Theme,
    Configuration,
    Preview,
    Running,
    Uninstall,
    Complete,
}

pub enum WorkerMsg {
    Step {
        index: usize,
        total: usize,
        label: String,
    },
    Line(LogLine),
    Done(RunReport),
}

struct ChannelReporter {
    sender: Sender<WorkerMsg>,
    logger: Logger,
}

impl Reporter for ChannelReporter {
    fn step(&mut self, index: usize, total: usize, label: &str) {
        let _ = self.sender.send(WorkerMsg::Step {
            index,
            total,
            label: label.to_string(),
        });
    }

    fn line(&mut self, level: LogLevel, message: &str) {
        self.logger.line(level, message);
        let _ = self.sender.send(WorkerMsg::Line(LogLine {
            level,
            text: message.to_string(),
        }));
    }
}

pub struct App {
    pub(crate) paths: Paths,
    pub(crate) source: Source,
    pub(crate) detection: Detection,
    pub(crate) catalog: ThemeCatalog,
    pub(crate) plan: InstallPlan,
    pub(crate) screen: Screen,
    pub(crate) welcome_index: usize,
    pub(crate) profile_index: usize,
    pub(crate) component_index: usize,
    pub(crate) theme_index: usize,
    pub(crate) config_index: usize,
    pub(crate) log: Vec<LogLine>,
    pub(crate) log_offset: usize,
    pub(crate) report: Option<RunReport>,
    pub(crate) current_step: usize,
    pub(crate) total_steps: usize,
    pub(crate) step_label: String,
    pub(crate) logger: Logger,
    pub(crate) worker: Option<Receiver<WorkerMsg>>,
    pub(crate) cancel: Arc<AtomicBool>,
    pub(crate) started: Option<Instant>,
    pub(crate) tick: u64,
    pub(crate) error: Option<String>,
    pub(crate) should_quit: bool,
}

impl App {
    pub fn new(options: Options) -> Result<Self> {
        let paths = Paths::from_env(options.prefix.clone())?;
        let source = Source::discover(options.source.clone())?;
        let detection = distro::detect(&paths);
        let catalog = ThemeCatalog::load(&source)?;
        let theme = options
            .theme
            .clone()
            .filter(|id| catalog.get(id).is_some())
            .unwrap_or_else(|| catalog.default.clone());
        let mut plan = InstallPlan::new(paths.clone(), source.clone(), theme);
        plan.dry_run = options.dry_run;
        plan.force_unsupported = options.force_unsupported;
        plan.keep_config = options.keep_config.unwrap_or(true);
        if let Some(mode) = options.mode {
            plan.mode = mode;
        }
        if matches!(plan.mode, Mode::Repair | Mode::Uninstall) {
            if let Some(components) = InstallPlan::installed_components(&paths.data_dir) {
                plan.components = components;
            }
        }
        let welcome_index = match plan.mode {
            Mode::Install => 0,
            Mode::Repair => 1,
            Mode::Uninstall => 2,
        };
        let profile_index = Profile::ALL
            .iter()
            .position(|p| p.components() == plan.components)
            .unwrap_or(1);
        let theme_index = catalog
            .themes
            .iter()
            .position(|t| t.id == plan.theme)
            .unwrap_or(0);
        let logger = Logger::create(&paths.log_dir, plan.mode.lower())?;
        let mut app = Self {
            paths,
            source,
            detection,
            catalog,
            plan,
            screen: Screen::Welcome,
            welcome_index,
            profile_index,
            component_index: 0,
            theme_index,
            config_index: 0,
            log: Vec::new(),
            log_offset: 0,
            report: None,
            current_step: 0,
            total_steps: 0,
            step_label: String::new(),
            logger,
            worker: None,
            cancel: Arc::new(AtomicBool::new(false)),
            started: None,
            tick: 0,
            error: None,
            should_quit: false,
        };
        app.push_log(
            LogLevel::Info,
            &format!(
                "AETHER {} installer / {} mode",
                crate::version(),
                app.plan.mode.label()
            ),
        );
        app.push_log(
            LogLevel::Info,
            &format!("payload source: {}", app.source.label()),
        );
        app.push_log(
            LogLevel::Info,
            &format!("log file: {}", app.logger.path().display()),
        );
        if app.plan.dry_run {
            app.push_log(
                LogLevel::Warn,
                "dry-run is enabled: no files will be written and no commands run",
            );
        }
        Ok(app)
    }

    pub fn run(&mut self) -> Result<()> {
        let mut terminal = tui::init()?;
        let result = self.event_loop(&mut terminal);
        tui::restore();
        result
    }

    fn event_loop(
        &mut self,
        terminal: &mut tui::Terminal,
    ) -> Result<()> {
        while !self.should_quit {
            self.poll_worker();
            terminal
                .draw(|frame| tui::draw(frame, self))
                .context("could not draw the installer interface")?;
            self.tick = self.tick.wrapping_add(1);
            if event::poll(Duration::from_millis(120))? {
                if let Event::Key(key) = event::read()? {
                    if key.kind == KeyEventKind::Press {
                        self.on_key(key)?;
                    }
                }
            }
        }
        Ok(())
    }

    fn poll_worker(&mut self) {
        let mut messages = Vec::new();
        if let Some(receiver) = &self.worker {
            while let Ok(message) = receiver.try_recv() {
                messages.push(message);
            }
        }
        for message in messages {
            match message {
                WorkerMsg::Step {
                    index,
                    total,
                    label,
                } => {
                    self.current_step = index;
                    self.total_steps = total;
                    self.step_label = label;
                }
                WorkerMsg::Line(line) => self.log.push(line),
                WorkerMsg::Done(report) => {
                    self.report = Some(report);
                    self.worker = None;
                    self.started = None;
                    self.screen = Screen::Complete;
                }
            }
        }
        if self.log.len() > 2000 {
            let excess = self.log.len() - 2000;
            self.log.drain(0..excess);
        }
    }

    fn on_key(&mut self, key: KeyEvent) -> Result<()> {
        if key.code == KeyCode::Char('c') && key.modifiers.contains(KeyModifiers::CONTROL) {
            if self.screen == Screen::Running {
                self.request_cancel();
            } else {
                self.should_quit = true;
            }
            return Ok(());
        }
        self.error = None;
        match self.screen {
            Screen::Welcome => match key.code {
                KeyCode::Up | KeyCode::Char('k') => {
                    self.welcome_index = self.welcome_index.saturating_sub(1);
                }
                KeyCode::Down | KeyCode::Char('j') => {
                    self.welcome_index = (self.welcome_index + 1).min(2);
                }
                KeyCode::Char('i') => {
                    self.welcome_index = 0;
                    self.choose_mode();
                }
                KeyCode::Char('r') => {
                    self.welcome_index = 1;
                    self.choose_mode();
                }
                KeyCode::Char('u') => {
                    self.welcome_index = 2;
                    self.choose_mode();
                }
                KeyCode::Enter | KeyCode::Char('l') => self.choose_mode(),
                KeyCode::Esc | KeyCode::Char('q') => self.should_quit = true,
                _ => {}
            },
            Screen::Detection => match key.code {
                KeyCode::Enter => {
                    if let Some(issue) = self.detection.blocking_issue(self.plan.force_unsupported) {
                        self.error = Some(issue);
                    } else {
                        self.screen = match self.plan.mode {
                            Mode::Install => {
                                self.profile_index = Profile::detect(&self.plan.components)
                                    .as_index();
                                Screen::Profiles
                            }
                            Mode::Repair => Screen::Preview,
                            Mode::Uninstall => Screen::Uninstall,
                        };
                    }
                }
                KeyCode::Esc => self.screen = Screen::Welcome,
                KeyCode::Char('q') => self.should_quit = true,
                _ => {}
            },
            Screen::Profiles => match key.code {
                KeyCode::Up | KeyCode::Char('k') => {
                    self.profile_index = self.profile_index.saturating_sub(1);
                }
                KeyCode::Down | KeyCode::Char('j') => {
                    self.profile_index = (self.profile_index + 1).min(Profile::ALL.len() - 1);
                }
                KeyCode::Enter | KeyCode::Char('l') => {
                    self.plan.components = Profile::ALL[self.profile_index].components();
                    self.plan.components.insert(Component::Shell);
                    self.component_index = 0;
                    self.screen = Screen::Components;
                }
                KeyCode::Esc => self.screen = Screen::Detection,
                KeyCode::Char('q') => self.should_quit = true,
                _ => {}
            },
            Screen::Components => match key.code {
                KeyCode::Up | KeyCode::Char('k') => {
                    self.component_index = self.component_index.saturating_sub(1);
                }
                KeyCode::Down | KeyCode::Char('j') => {
                    self.component_index =
                        (self.component_index + 1).min(Component::ALL.len() - 1);
                }
                KeyCode::Char(' ') => {
                    let component = Component::ALL[self.component_index];
                    if component.required() {
                        self.error = Some(format!(
                            "{} is required and cannot be disabled",
                            component.label()
                        ));
                    } else {
                        self.plan
                            .enable(component, !self.plan.has(component));
                    }
                }
                KeyCode::Enter | KeyCode::Char('l') => {
                    self.theme_index = self
                        .catalog
                        .themes
                        .iter()
                        .position(|t| t.id == self.plan.theme)
                        .unwrap_or(0);
                    self.screen = Screen::Theme;
                }
                KeyCode::Esc => self.screen = Screen::Profiles,
                KeyCode::Char('q') => self.should_quit = true,
                _ => {}
            },
            Screen::Theme => match key.code {
                KeyCode::Up | KeyCode::Char('k') => {
                    self.theme_index = self.theme_index.saturating_sub(1);
                    self.select_theme();
                }
                KeyCode::Down | KeyCode::Char('j') => {
                    self.theme_index =
                        (self.theme_index + 1).min(self.catalog.themes.len() - 1);
                    self.select_theme();
                }
                KeyCode::Enter | KeyCode::Char('l') => {
                    self.select_theme();
                    self.config_index = 0;
                    self.screen = Screen::Configuration;
                }
                KeyCode::Esc => self.screen = Screen::Components,
                KeyCode::Char('q') => self.should_quit = true,
                _ => {}
            },
            Screen::Configuration => match key.code {
                KeyCode::Up | KeyCode::Char('k') => {
                    self.config_index = self.config_index.saturating_sub(1);
                }
                KeyCode::Down | KeyCode::Char('j') => {
                    self.config_index = (self.config_index + 1).min(2);
                }
                KeyCode::Char(' ') => self.toggle_config(),
                KeyCode::Enter | KeyCode::Char('l') => self.screen = Screen::Preview,
                KeyCode::Esc => self.screen = Screen::Theme,
                KeyCode::Char('q') => self.should_quit = true,
                _ => {}
            },
            Screen::Preview => match key.code {
                KeyCode::Enter | KeyCode::Char('l') => self.begin_run()?,
                KeyCode::Esc => self.screen = Screen::Configuration,
                KeyCode::Char('q') => self.should_quit = true,
                _ => {}
            },
            Screen::Uninstall => match key.code {
                KeyCode::Up | KeyCode::Down | KeyCode::Char('k') | KeyCode::Char('j') => {
                    self.plan.keep_config = !self.plan.keep_config;
                }
                KeyCode::Char(' ') => self.plan.keep_config = !self.plan.keep_config,
                KeyCode::Enter | KeyCode::Char('l') => self.begin_run()?,
                KeyCode::Esc => self.screen = Screen::Detection,
                KeyCode::Char('q') => self.should_quit = true,
                _ => {}
            },
            Screen::Running => match key.code {
                KeyCode::Esc | KeyCode::Char('q') => self.request_cancel(),
                KeyCode::PageUp => self.scroll_log(5),
                KeyCode::PageDown => self.scroll_log(-5),
                _ => {}
            },
            Screen::Complete => match key.code {
                KeyCode::Enter | KeyCode::Esc | KeyCode::Char('q') => {
                    self.should_quit = true
                }
                KeyCode::PageUp => self.scroll_log(5),
                KeyCode::PageDown => self.scroll_log(-5),
                _ => {}
            },
        }
        Ok(())
    }

    fn choose_mode(&mut self) {
        self.plan.mode = match self.welcome_index {
            0 => Mode::Install,
            1 => Mode::Repair,
            _ => Mode::Uninstall,
        };
        if matches!(self.plan.mode, Mode::Repair | Mode::Uninstall) {
            if let Some(components) = InstallPlan::installed_components(&self.paths.data_dir) {
                self.plan.components = components;
            }
        }
        self.push_log(
            LogLevel::Info,
            &format!("selected mode: {}", self.plan.mode.label()),
        );
        self.screen = Screen::Detection;
    }

    fn select_theme(&mut self) {
        if let Some(theme) = self.catalog.themes.get(self.theme_index) {
            self.plan.theme = theme.id.clone();
        }
    }

    fn toggle_config(&mut self) {
        match self.config_index {
            0 => {
                self.plan.manage_hyprland = !self.plan.manage_hyprland;
                self.plan
                    .enable(Component::Hyprland, self.plan.manage_hyprland);
            }
            1 => {
                let enabled = self.plan.has(Component::Integration);
                self.plan.enable(Component::Integration, !enabled);
            }
            2 => {
                if !self.detection.arch_supported {
                    self.error = Some(
                        "Package installation is only implemented for Arch Linux".into(),
                    );
                    return;
                }
                let enabled = self.plan.has(Component::Packages);
                self.plan.enable(Component::Packages, !enabled);
            }
            _ => {}
        }
    }

    fn begin_run(&mut self) -> Result<()> {
        if let Some(issue) = self.detection.blocking_issue(self.plan.force_unsupported) {
            self.error = Some(issue);
            self.screen = Screen::Detection;
            return Ok(());
        }
        if self.plan.has(Component::Packages) && !self.detection.arch_supported {
            self.plan.components.remove(&Component::Packages);
            self.push_log(
                LogLevel::Warn,
                "system package installation skipped: unsupported distribution",
            );
        }
        self.select_theme();
        self.cancel = Arc::new(AtomicBool::new(false));
        self.log.clear();
        self.log_offset = 0;
        self.current_step = 0;
        self.total_steps = 0;
        self.step_label = "Starting".into();
        self.report = None;
        self.screen = Screen::Running;
        self.started = Some(Instant::now());
        self.start_worker();
        Ok(())
    }

    fn start_worker(&mut self) {
        let plan = self.plan.clone();
        let detection = self.detection.clone();
        let logger = self.logger.clone();
        let cancel = Arc::clone(&self.cancel);
        let log_path = logger.path().to_path_buf();
        let (sender, receiver) = mpsc::channel();
        self.worker = Some(receiver);
        std::thread::spawn(move || {
            let mut reporter = ChannelReporter { sender, logger };
            let report = installer::execute(
                &plan,
                &detection,
                &mut reporter,
                &cancel,
                Some(log_path),
                crate::version(),
            );
            let _ = reporter.sender.send(WorkerMsg::Done(report));
        });
    }

    fn request_cancel(&mut self) {
        if !self.cancel.swap(true, Ordering::SeqCst) {
            self.push_log(
                LogLevel::Warn,
                "cancellation requested; the current step will finish first",
            );
        }
    }

    fn scroll_log(&mut self, delta: i32) {
        let max = self.log.len();
        let next = self.log_offset as i32 + delta;
        self.log_offset = next.clamp(0, max as i32) as usize;
    }

    pub fn push_log(&mut self, level: LogLevel, text: &str) {
        self.logger.line(level, text);
        self.log.push(LogLine {
            level,
            text: text.to_string(),
        });
    }

    pub fn config_rows(&self) -> Vec<ConfigRow> {
        vec![
            ConfigRow {
                title: "Hyprland visual settings",
                value: yes_no(self.plan.manage_hyprland),
                detail: "Add one managed include to ~/.config/hypr/hyprland.conf",
                toggleable: true,
            },
            ConfigRow {
                title: "Commands and desktop entries",
                value: yes_no(self.plan.has(Component::Integration)),
                detail: "Install the aether command, app menu entries and icon",
                toggleable: true,
            },
            ConfigRow {
                title: "Missing system packages",
                value: if !self.detection.arch_supported {
                    "unsupported".into()
                } else {
                    yes_no(self.plan.has(Component::Packages))
                },
                detail: "Runs sudo -n pacman; authenticate first with sudo -v if needed",
                toggleable: self.detection.arch_supported,
            },
        ]
    }

    /// Log lines to render, newest last.
    pub fn visible_log(&self, height: usize) -> Vec<&LogLine> {
        if height == 0 || self.log.is_empty() {
            return Vec::new();
        }
        let end = self.log.len().saturating_sub(self.log_offset);
        let start = end.saturating_sub(height);
        self.log[start..end].iter().collect()
    }
}

#[derive(Debug, Clone)]
pub struct ConfigRow {
    pub title: &'static str,
    pub value: String,
    pub detail: &'static str,
    pub toggleable: bool,
}

fn yes_no(value: bool) -> String {
    if value {
        "enabled".into()
    } else {
        "disabled".into()
    }
}

impl Profile {
    pub fn as_index(self) -> usize {
        match self {
            Profile::Minimal => 0,
            Profile::Standard => 1,
            Profile::Complete => 2,
        }
    }
}

pub fn run(options: Options) -> Result<()> {
    let mut app = App::new(options)?;
    app.run()
}

/// Non-interactive dry-run used by `--headless` and CI.
pub fn run_headless(options: Options) -> Result<crate::installer::RunReport> {
    let app = App::new(options)?;
    crate::installer::run_headless(&app.plan, &app.detection, crate::version())
}
