//! Ratatui rendering for the installer.
//!
//! The visual language mirrors AETHER: deep surfaces, rounded borders, a violet
//! accent and a single aqua signal colour. The TUI is keyboard-first and never
//! relies on a mouse.

use crate::app::{App, Screen};
use crate::config::hex_rgb;
use crate::distro::human_bytes;
use crate::plan::{Component, Mode, Profile};
use crate::report::LogLevel;
use anyhow::Result;
use crossterm::execute;
use crossterm::terminal::{
    disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen,
};
use ratatui::backend::CrosstermBackend;
use ratatui::layout::{Alignment, Constraint, Direction, Layout, Rect};
use ratatui::style::{Color, Modifier, Style, Stylize};
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, BorderType, Borders, Gauge, Padding, Paragraph, Wrap};
use ratatui::{Frame, Terminal as RatatuiTerminal};
use std::io::{stdout, Stdout};

pub type Terminal = RatatuiTerminal<CrosstermBackend<Stdout>>;

const BG: Color = Color::Rgb(10, 12, 17);
const SURFACE: Color = Color::Rgb(18, 21, 29);
const SURFACE_HIGH: Color = Color::Rgb(32, 37, 51);
const TEXT: Color = Color::Rgb(232, 234, 242);
const MUTED: Color = Color::Rgb(167, 174, 195);
const DIM: Color = Color::Rgb(110, 118, 138);
const ACCENT: Color = Color::Rgb(169, 155, 255);
const AQUA: Color = Color::Rgb(111, 231, 221);
const SUCCESS: Color = Color::Rgb(139, 227, 162);
const WARNING: Color = Color::Rgb(255, 210, 138);
const ERROR: Color = Color::Rgb(255, 180, 171);

pub fn init() -> Result<Terminal> {
    enable_raw_mode()?;
    let mut output = stdout();
    if let Err(error) = execute!(output, EnterAlternateScreen) {
        let _ = disable_raw_mode();
        return Err(error.into());
    }
    let backend = CrosstermBackend::new(output);
    match RatatuiTerminal::new(backend) {
        Ok(mut terminal) => {
            let _ = terminal.hide_cursor();
            Ok(terminal)
        }
        Err(error) => {
            restore();
            Err(error.into())
        }
    }
}

pub fn restore() {
    let _ = disable_raw_mode();
    let _ = execute!(stdout(), LeaveAlternateScreen);
}

pub fn draw(frame: &mut Frame, app: &App) {
    let area = frame.area();
    frame.render_widget(Block::default().style(Style::default().bg(BG)), area);
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(4),
            Constraint::Min(3),
            Constraint::Length(2),
        ])
        .split(area);
    draw_header(frame, app, chunks[0]);
    match app.screen {
        Screen::Welcome => draw_welcome(frame, app, chunks[1]),
        Screen::Detection => draw_detection(frame, app, chunks[1]),
        Screen::Profiles => draw_profiles(frame, app, chunks[1]),
        Screen::Components => draw_components(frame, app, chunks[1]),
        Screen::Theme => draw_theme(frame, app, chunks[1]),
        Screen::Configuration => draw_configuration(frame, app, chunks[1]),
        Screen::Preview => draw_preview(frame, app, chunks[1]),
        Screen::Running => draw_running(frame, app, chunks[1]),
        Screen::Uninstall => draw_uninstall(frame, app, chunks[1]),
        Screen::Complete => draw_complete(frame, app, chunks[1]),
    }
    draw_footer(frame, app, chunks[2]);
}

fn accent(app: &App) -> Color {
    let index = app
        .catalog
        .themes
        .iter()
        .position(|t| t.id == app.plan.theme)
        .unwrap_or(0);
    let Some(theme) = app.catalog.themes.get(index) else {
        return ACCENT;
    };
    let (r, g, b) = hex_rgb(&theme.colors.primary);
    Color::Rgb(r, g, b)
}

fn theme_colors(app: &App) -> (Color, Color, Color) {
    let index = app
        .catalog
        .themes
        .iter()
        .position(|t| t.id == app.plan.theme)
        .unwrap_or(0);
    let Some(theme) = app.catalog.themes.get(index) else {
        return (SURFACE, ACCENT, TEXT);
    };
    let (br, bg, bb) = hex_rgb(&theme.colors.background);
    let (pr, pg, pb) = hex_rgb(&theme.colors.primary);
    let (sr, sg, sb) = hex_rgb(&theme.colors.surface);
    (
        Color::Rgb(br, bg, bb),
        Color::Rgb(pr, pg, pb),
        Color::Rgb(sr, sg, sb),
    )
}

fn draw_header(frame: &mut Frame, app: &App, area: Rect) {
    let columns = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(62), Constraint::Percentage(38)])
        .split(area);
    let title = vec![
        Line::from(vec![
            Span::styled("A E T H E R", Style::default().fg(accent(app)).bold()),
            Span::styled(
                format!("   installer {}", crate::version()),
                Style::default().fg(DIM),
            ),
        ]),
        Line::from(Span::styled(
            crate::TAGLINE,
            Style::default().fg(MUTED),
        )),
    ];
    frame.render_widget(
        Paragraph::new(title).block(
            Block::default()
                .borders(Borders::BOTTOM)
                .border_type(BorderType::Plain)
                .border_style(Style::default().fg(SURFACE_HIGH))
                .padding(Padding::new(2, 2, 0, 0)),
        ),
        columns[0],
    );

    let mut status = vec![Line::from(vec![
        Span::styled(
            format!(" {} ", app.plan.mode.label().to_uppercase()),
            Style::default().fg(BG).bg(accent(app)).bold(),
        ),
        Span::raw("  "),
        Span::styled("Arch Linux first-class", Style::default().fg(DIM)),
    ])];
    if app.plan.dry_run {
        status.push(Line::from(Span::styled(
            " DRY RUN — nothing will be written ",
            Style::default().fg(BG).bg(WARNING).bold(),
        )));
    } else {
        status.push(Line::from(Span::styled(
            app.plan.theme.clone(),
            Style::default().fg(DIM),
        )));
    }
    frame.render_widget(
        Paragraph::new(status)
            .alignment(Alignment::Right)
            .block(Block::default().padding(Padding::new(2, 2, 0, 0))),
        columns[1],
    );
}

fn draw_footer(frame: &mut Frame, app: &App, area: Rect) {
    let hints: Vec<(&str, &str)> = match app.screen {
        Screen::Welcome => vec![("↑↓", "choose"), ("Enter", "continue"), ("q", "quit")],
        Screen::Detection => vec![("Enter", "continue"), ("Esc", "back"), ("q", "quit")],
        Screen::Profiles => vec![("↑↓", "profile"), ("Enter", "select"), ("Esc", "back")],
        Screen::Components => vec![("↑↓", "move"), ("Space", "toggle"), ("Enter", "next")],
        Screen::Theme => vec![("↑↓", "preview"), ("Enter", "apply"), ("Esc", "back")],
        Screen::Configuration => vec![("↑↓", "move"), ("Space", "toggle"), ("Enter", "review")],
        Screen::Preview => vec![("Enter", "start"), ("Esc", "back"), ("q", "quit")],
        Screen::Uninstall => vec![("Space", "keep config"), ("Enter", "uninstall"), ("Esc", "back")],
        Screen::Running => vec![("Esc", "cancel"), ("PgUp/PgDn", "scroll log")],
        Screen::Complete => vec![("PgUp/PgDn", "log"), ("Enter", "exit")],
    };
    let mut spans = vec![Span::styled(" ", Style::default())];
    for (key, action) in hints {
        spans.push(Span::styled(
            format!(" {key} "),
            Style::default().fg(BG).bg(SURFACE_HIGH).bold(),
        ));
        spans.push(Span::styled(
            format!(" {action}   "),
            Style::default().fg(MUTED),
        ));
    }
    frame.render_widget(
        Paragraph::new(Line::from(spans)).block(
            Block::default()
                .borders(Borders::TOP)
                .border_style(Style::default().fg(SURFACE_HIGH))
                .padding(Padding::new(2, 2, 0, 0)),
        ),
        area,
    );
}

fn draw_welcome(frame: &mut Frame, app: &App, area: Rect) {
    let area = centered(area, 92, 27);
    let rows = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),
            Constraint::Length(2),
            Constraint::Length(11),
            Constraint::Min(2),
        ])
        .split(area);

    frame.render_widget(
        Paragraph::new(vec![
            Line::from(Span::styled(
                "Your desktop. Your atmosphere. Your AETHER.",
                Style::default().fg(TEXT).bold(),
            )),
            Line::from(Span::styled(
                "An open-source desktop for Arch Linux and Hyprland.",
                Style::default().fg(MUTED),
            )),
        ])
        .block(Block::default().padding(Padding::new(2, 2, 0, 0))),
        rows[0],
    );

    frame.render_widget(
        Paragraph::new(Span::styled(
            "What would you like to do?",
            Style::default().fg(DIM),
        ))
        .block(Block::default().padding(Padding::new(2, 2, 0, 0))),
        rows[1],
    );

    let modes = [
        (
            "Install",
            "Set up AETHER for this user. Existing configuration is backed up and merged.",
        ),
        (
            "Repair",
            "Reinstall program files and fix links, entries and configuration without losing settings.",
        ),
        (
            "Uninstall",
            "Remove AETHER program files and integrations. Keep or back up your configuration.",
        ),
    ];
    let cards = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),
            Constraint::Length(3),
            Constraint::Length(3),
            Constraint::Min(0),
        ])
        .split(rows[2]);
    for (index, (title, description)) in modes.iter().enumerate() {
        let selected = index == app.welcome_index;
        let border = if selected { accent(app) } else { SURFACE_HIGH };
        let block = Block::default()
            .borders(Borders::ALL)
            .border_type(BorderType::Rounded)
            .border_style(Style::default().fg(border))
            .style(Style::default().bg(if selected { SURFACE } else { BG }))
            .padding(Padding::new(2, 2, 0, 0));
        let lines = vec![Line::from(vec![
            Span::styled(
                if selected { "● " } else { "○ " },
                Style::default().fg(if selected { accent(app) } else { DIM }),
            ),
            Span::styled(*title, Style::default().fg(TEXT).bold()),
            Span::styled(
                format!("   {description}"),
                Style::default().fg(if selected { MUTED } else { DIM }),
            ),
        ])];
        frame.render_widget(Paragraph::new(lines).block(block), cards[index]);
    }

    let notes = vec![
        Line::from(vec![
            Span::styled("Supported: ", Style::default().fg(DIM)),
            Span::styled(
                "Arch Linux with Hyprland. Fedora, openSUSE and NixOS are not claimed as supported.",
                Style::default().fg(MUTED),
            ),
        ]),
        Line::from(vec![
            Span::styled("Safety: ", Style::default().fg(DIM)),
            Span::styled(
                "timestamped backups, atomic writes, no curl | sh and no shell interpolation.",
                Style::default().fg(MUTED),
            ),
        ]),
    ];
    frame.render_widget(
        Paragraph::new(notes)
            .wrap(Wrap { trim: true })
            .block(Block::default().padding(Padding::new(2, 2, 0, 0))),
        rows[3],
    );
}

fn draw_detection(frame: &mut Frame, app: &App, area: Rect) {
    let area = centered(area, 108, 27);
    let columns = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(54), Constraint::Percentage(46)])
        .split(area);

    let yes = |value: bool| if value { "yes" } else { "no" };
    let mut left = vec![
        Line::from(vec![
            Span::styled("Distribution   ", Style::default().fg(DIM)),
            Span::styled(
                app.detection.os.summary(),
                Style::default()
                    .fg(if app.detection.arch_supported {
                        SUCCESS
                    } else {
                        ERROR
                    })
                    .bold(),
            ),
        ]),
        Line::from(vec![
            Span::styled("Session        ", Style::default().fg(DIM)),
            Span::styled(
                format!(
                    "{} / {}",
                    app.detection.session_type, app.detection.desktop
                ),
                Style::default().fg(TEXT),
            ),
        ]),
        Line::from(vec![
            Span::styled("Hyprland       ", Style::default().fg(DIM)),
            Span::styled(
                if app.detection.hyprland_running {
                    "running"
                } else {
                    "not detected in this session"
                },
                Style::default().fg(if app.detection.hyprland_running {
                    SUCCESS
                } else {
                    WARNING
                }),
            ),
        ]),
        Line::from(vec![
            Span::styled("Quickshell     ", Style::default().fg(DIM)),
            Span::styled(
                yes(app.detection.quickshell),
                Style::default().fg(if app.detection.quickshell {
                    SUCCESS
                } else {
                    ERROR
                }),
            ),
        ]),
        Line::from(vec![
            Span::styled("Disk free      ", Style::default().fg(DIM)),
            Span::styled(
                app.detection
                    .disk_free
                    .map(human_bytes)
                    .unwrap_or_else(|| "unknown".into()),
                Style::default().fg(TEXT),
            ),
        ]),
        Line::from(""),
        Line::from(vec![
            Span::styled("Existing install  ", Style::default().fg(DIM)),
            Span::styled(
                if app.detection.existing.data_dir {
                    app.detection
                        .existing
                        .marker_version
                        .clone()
                        .map(|v| format!("AETHER {v}"))
                        .unwrap_or_else(|| "present, no marker".into())
                } else {
                    "none".into()
                },
                Style::default().fg(TEXT),
            ),
        ]),
        Line::from(vec![
            Span::styled("User config       ", Style::default().fg(DIM)),
            Span::styled(
                if app.detection.existing.config {
                    "present (will be merged and backed up)"
                } else {
                    "will be created"
                },
                Style::default().fg(TEXT),
            ),
        ]),
        Line::from(""),
        Line::from(vec![
            Span::styled("Install prefix    ", Style::default().fg(DIM)),
            Span::styled(
                app.paths.prefix.display().to_string(),
                Style::default().fg(TEXT),
            ),
        ]),
        Line::from(vec![
            Span::styled("Data directory    ", Style::default().fg(DIM)),
            Span::styled(
                app.paths.data_dir.display().to_string(),
                Style::default().fg(TEXT),
            ),
        ]),
        Line::from(vec![
            Span::styled("Payload           ", Style::default().fg(DIM)),
            Span::styled(
                app.source.label(),
                Style::default().fg(TEXT),
            ),
        ]),
    ];
    if let Some(issue) = app
        .detection
        .blocking_issue(app.plan.force_unsupported)
    {
        left.push(Line::from(""));
        left.push(Line::from(Span::styled(
            format!("▲ {issue}"),
            Style::default().fg(ERROR).bold(),
        )));
    }
    frame.render_widget(
        Paragraph::new(left).wrap(Wrap { trim: true }).block(panel("System")),
        columns[0],
    );

    let mut tools = vec![Line::from(Span::styled(
        "Required and optional runtime tools",
        Style::default().fg(DIM),
    ))];
    for tool in &app.detection.tools {
        let (mark, color) = if tool.found {
            ("✓", SUCCESS)
        } else if tool.required {
            ("✗", ERROR)
        } else {
            ("·", DIM)
        };
        tools.push(Line::from(vec![
            Span::styled(format!("{mark} "), Style::default().fg(color).bold()),
            Span::styled(
                format!("{:<14}", tool.name),
                Style::default().fg(if tool.found { TEXT } else { MUTED }),
            ),
            Span::styled(tool.purpose, Style::default().fg(DIM)),
        ]));
    }
    if !app.detection.missing_packages.is_empty() {
        tools.push(Line::from(""));
        tools.push(Line::from(Span::styled(
            format!(
                "{} missing Arch package(s): {}",
                app.detection.missing_packages.len(),
                app.detection.missing_packages.join(", ")
            ),
            Style::default().fg(WARNING),
        )));
    }
    frame.render_widget(
        Paragraph::new(tools)
            .wrap(Wrap { trim: true })
            .block(panel("Dependencies")),
        columns[1],
    );
}

fn draw_profiles(frame: &mut Frame, app: &App, area: Rect) {
    let area = centered(area, 92, 24);
    let rows = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(2),
            Constraint::Length(4),
            Constraint::Length(4),
            Constraint::Length(4),
            Constraint::Min(2),
        ])
        .split(area);
    frame.render_widget(
        Paragraph::new(Span::styled(
            "Choose a starting point. Every component can be changed on the next screen.",
            Style::default().fg(MUTED),
        ))
        .block(Block::default().padding(Padding::new(2, 2, 0, 0))),
        rows[0],
    );
    for (index, profile) in Profile::ALL.iter().enumerate() {
        let selected = index == app.profile_index;
        let block = Block::default()
            .borders(Borders::ALL)
            .border_type(BorderType::Rounded)
            .border_style(Style::default().fg(if selected { accent(app) } else { SURFACE_HIGH }))
            .style(Style::default().bg(if selected { SURFACE } else { BG }))
            .padding(Padding::new(2, 2, 0, 0));
        let components = profile
            .components()
            .iter()
            .map(|c| c.label())
            .collect::<Vec<_>>()
            .join("  ·  ");
        let lines = vec![
            Line::from(vec![
                Span::styled(
                    if selected { "● " } else { "○ " },
                    Style::default().fg(if selected { accent(app) } else { DIM }),
                ),
                Span::styled(profile.name(), Style::default().fg(TEXT).bold()),
            ]),
            Line::from(Span::styled(
                profile.description(),
                Style::default().fg(MUTED),
            )),
            Line::from(Span::styled(components, Style::default().fg(DIM))),
        ];
        frame.render_widget(Paragraph::new(lines).block(block), rows[index + 1]);
    }
    frame.render_widget(
        Paragraph::new(Span::styled(
            "Profiles are presets, not separate installers. Complete is the only profile that offers system packages.",
            Style::default().fg(DIM),
        ))
        .wrap(Wrap { trim: true })
        .block(Block::default().padding(Padding::new(2, 2, 0, 0))),
        rows[4],
    );
}

fn draw_components(frame: &mut Frame, app: &App, area: Rect) {
    let area = centered(area, 100, 26);
    let rows = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Length(2), Constraint::Min(3)])
        .split(area);
    frame.render_widget(
        Paragraph::new(Span::styled(
            "Select what to install. Shell and themes are required; everything else is optional.",
            Style::default().fg(MUTED),
        ))
        .block(Block::default().padding(Padding::new(2, 2, 0, 0))),
        rows[0],
    );
    let list = Layout::default()
        .direction(Direction::Vertical)
        .constraints(
            Component::ALL
                .iter()
                .map(|_| Constraint::Length(2))
                .chain([Constraint::Min(0)])
                .collect::<Vec<_>>(),
        )
        .split(rows[1]);
    for (index, component) in Component::ALL.iter().enumerate() {
        let selected = index == app.component_index;
        let enabled = app.plan.has(*component);
        let mark = if component.required() {
            "[✓]"
        } else if enabled {
            "[✓]"
        } else {
            "[ ]"
        };
        let style = if selected {
            Style::default().bg(SURFACE)
        } else {
            Style::default()
        };
        let border = if selected {
            Style::default().fg(accent(app))
        } else {
            Style::default().fg(SURFACE_HIGH)
        };
        let lines = vec![
            Line::from(vec![
                Span::styled(
                    format!("{mark} "),
                    Style::default()
                        .fg(if enabled { accent(app) } else { DIM })
                        .bold(),
                ),
                Span::styled(component.label(), Style::default().fg(TEXT).bold()),
                Span::styled(
                    if component.required() {
                        "   required"
                    } else if enabled {
                        "   enabled"
                    } else {
                        "   disabled"
                    },
                    Style::default().fg(if component.required() {
                        AQUA
                    } else if enabled {
                        SUCCESS
                    } else {
                        DIM
                    }),
                ),
            ]),
            Line::from(Span::styled(
                format!("    {}", component.description()),
                Style::default().fg(if enabled { MUTED } else { DIM }),
            )),
        ];
        frame.render_widget(
            Paragraph::new(lines).style(style).block(
                Block::default()
                    .borders(Borders::LEFT)
                    .border_style(border)
                    .padding(Padding::new(1, 1, 0, 0)),
            ),
            list[index],
        );
    }
}

fn draw_theme(frame: &mut Frame, app: &App, area: Rect) {
    let area = centered(area, 110, 27);
    let columns = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(42), Constraint::Percentage(58)])
        .split(area);
    let mut lines = Vec::new();
    for (index, theme) in app.catalog.themes.iter().enumerate() {
        let selected = index == app.theme_index;
        let (r, g, b) = hex_rgb(&theme.colors.primary);
        let (br, bg, bb) = hex_rgb(&theme.colors.background);
        lines.push(Line::from(vec![
            Span::styled(
                if selected { "● " } else { "○ " },
                Style::default().fg(Color::Rgb(r, g, b)),
            ),
            Span::styled("██ ", Style::default().fg(Color::Rgb(r, g, b))),
            Span::styled(
                format!("{:<20}", theme.name),
                Style::default()
                    .fg(if selected { TEXT } else { MUTED })
                    .bold(),
            ),
            Span::styled(
                format!(" {}", theme.variant),
                Style::default().fg(DIM),
            ),
        ]));
        if selected {
            lines.push(Line::from(Span::styled(
                format!("   background #{br:02X}{bg:02X}{bb:02X}  primary {}", theme.colors.primary),
                Style::default().fg(DIM),
            )));
        }
    }
    frame.render_widget(
        Paragraph::new(lines).block(panel("Built-in themes")),
        columns[0],
    );
    draw_theme_preview(frame, app, columns[1]);
}

fn draw_theme_preview(frame: &mut Frame, app: &App, area: Rect) {
    let (background, primary, surface) = theme_colors(app);
    let block = Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(Style::default().fg(primary))
        .title(" Preview ")
        .style(Style::default().bg(background))
        .padding(Padding::new(2, 2, 1, 1));
    let inner = block.inner(area);
    frame.render_widget(block, area);
    if inner.height < 8 {
        return;
    }
    let rows = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(2),
            Constraint::Length(1),
            Constraint::Length(4),
            Constraint::Length(1),
            Constraint::Min(1),
        ])
        .split(inner);
    frame.render_widget(
        Paragraph::new(vec![
            Line::from(vec![
                Span::styled("⬤ ", Style::default().fg(primary)),
                Span::styled("AETHER", Style::default().fg(TEXT).bold()),
                Span::styled("   workspace 2   media   network   12:30", Style::default().fg(MUTED)),
            ]),
            Line::from(Span::styled(
                "────────────────────────────────────────────────────────────",
                Style::default().fg(surface),
            )),
        ]),
        rows[0],
    );
    frame.render_widget(
        Paragraph::new(Span::styled(
            "Good evening",
            Style::default().fg(TEXT).bold(),
        )),
        rows[2],
    );
    let card = Rect {
        x: inner.x,
        y: rows[2].y + 1,
        width: inner.width,
        height: 3,
    };
    frame.render_widget(
        Paragraph::new(vec![
            Line::from(Span::styled(
                "  Notification centre",
                Style::default().fg(TEXT),
            )),
            Line::from(Span::styled(
                "  AETHER Settings · theme applied · just now",
                Style::default().fg(MUTED),
            )),
        ])
        .style(Style::default().bg(surface))
        .block(
            Block::default()
                .borders(Borders::ALL)
                .border_type(BorderType::Rounded)
                .border_style(Style::default().fg(surface)),
        ),
        card,
    );
    frame.render_widget(
        Paragraph::new(vec![
            Line::from(""),
            Line::from(vec![
                Span::styled(" ▰▰▰▰▰ ", Style::default().fg(primary)),
                Span::styled("  colour roles, radii and blur are read from the theme JSON", Style::default().fg(DIM)),
            ]),
        ])
        .wrap(Wrap { trim: true }),
        rows[4],
    );
}

fn draw_configuration(frame: &mut Frame, app: &App, area: Rect) {
    let area = centered(area, 100, 27);
    let groups = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(2),
            Constraint::Length(11),
            Constraint::Length(9),
            Constraint::Min(1),
        ])
        .split(area);
    frame.render_widget(
        Paragraph::new(Span::styled(
            "Choose how AETHER should integrate with this system. Nothing is changed until you confirm.",
            Style::default().fg(MUTED),
        ))
        .block(Block::default().padding(Padding::new(2, 2, 0, 0))),
        groups[0],
    );
    let rows = app.config_rows();
    let list = Layout::default()
        .direction(Direction::Vertical)
        .constraints(
            rows.iter()
                .map(|_| Constraint::Length(3))
                .chain([Constraint::Min(0)])
                .collect::<Vec<_>>(),
        )
        .split(groups[1]);
    for (index, row) in rows.iter().enumerate() {
        let selected = index == app.config_index;
        let lines = vec![
            Line::from(vec![
                Span::styled(
                    if selected { "● " } else { "○ " },
                    Style::default().fg(if selected { accent(app) } else { DIM }),
                ),
                Span::styled(row.title, Style::default().fg(TEXT).bold()),
                Span::styled(
                    format!("   {}", row.value),
                    Style::default().fg(if row.value == "enabled" {
                        SUCCESS
                    } else if row.value == "disabled" {
                        DIM
                    } else {
                        WARNING
                    }),
                ),
            ]),
            Line::from(Span::styled(
                format!("   {}", row.detail),
                Style::default().fg(if row.toggleable { MUTED } else { DIM }),
            )),
        ];
        frame.render_widget(
            Paragraph::new(lines)
                .style(if selected {
                    Style::default().bg(SURFACE)
                } else {
                    Style::default()
                })
                .block(
                    Block::default()
                        .borders(Borders::LEFT)
                        .border_style(Style::default().fg(if selected {
                            accent(app)
                        } else {
                            SURFACE_HIGH
                        })),
                ),
            list[index],
        );
    }

    let paths = vec![
        Line::from(Span::styled("Paths", Style::default().fg(DIM).bold())),
        Line::from(vec![
            Span::styled("  prefix      ", Style::default().fg(DIM)),
            Span::styled(app.paths.prefix.display().to_string(), Style::default().fg(TEXT)),
        ]),
        Line::from(vec![
            Span::styled("  data        ", Style::default().fg(DIM)),
            Span::styled(app.paths.data_dir.display().to_string(), Style::default().fg(TEXT)),
        ]),
        Line::from(vec![
            Span::styled("  config      ", Style::default().fg(DIM)),
            Span::styled(app.paths.config_dir.display().to_string(), Style::default().fg(TEXT)),
        ]),
        Line::from(vec![
            Span::styled("  state       ", Style::default().fg(DIM)),
            Span::styled(app.paths.state_dir.display().to_string(), Style::default().fg(TEXT)),
        ]),
        Line::from(Span::styled(
            "  Existing config.json is copied to config/backups before the merge.",
            Style::default().fg(DIM),
        )),
    ];
    frame.render_widget(Paragraph::new(paths).block(panel("Locations")), groups[2]);
    if let Some(error) = &app.error {
        frame.render_widget(
            Paragraph::new(Span::styled(
                format!("▲ {error}"),
                Style::default().fg(ERROR),
            ))
            .block(Block::default().padding(Padding::new(2, 2, 0, 0))),
            groups[3],
        );
    }
}

fn draw_preview(frame: &mut Frame, app: &App, area: Rect) {
    let area = centered(area, 104, 27);
    let title = if app.plan.mode == Mode::Repair {
        "Repair plan"
    } else {
        "Review installation"
    };
    let block = panel(title);
    let inner = block.inner(area);
    frame.render_widget(block, area);
    let columns = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(56), Constraint::Percentage(44)])
        .split(inner);
    let theme = app
        .catalog
        .get(&app.plan.theme)
        .map(|t| t.name.clone())
        .unwrap_or_else(|| app.plan.theme.clone());
    let mut left = vec![
        field("Mode", app.plan.mode.label()),
        field("Distribution", app.detection.os.summary()),
        field("Theme", theme.clone()),
        field("Prefix", app.paths.prefix.display().to_string()),
        field("Data", app.paths.data_dir.display().to_string()),
        field("Config", app.paths.config_dir.display().to_string()),
        field("Payload", app.source.label()),
        Line::from(""),
        Line::from(Span::styled("Components", Style::default().fg(DIM).bold())),
    ];
    for component in Component::ALL {
        if app.plan.has(component) {
            left.push(Line::from(vec![
                Span::styled("  ✓ ", Style::default().fg(SUCCESS)),
                Span::styled(component.label(), Style::default().fg(TEXT)),
            ]));
        }
    }
    if app.plan.mode == Mode::Repair {
        left.push(Line::from(""));
        left.push(Line::from(Span::styled(
            "Repair reinstalls files, merges configuration, recreates links and entries.",
            Style::default().fg(MUTED),
        )));
    }
    frame.render_widget(
        Paragraph::new(left).wrap(Wrap { trim: true }),
        columns[0],
    );

    let mut right = vec![
        Line::from(Span::styled("What happens", Style::default().fg(DIM).bold())),
        Line::from(""),
        Line::from(Span::styled(
            "1. Program files are written atomically.",
            Style::default().fg(MUTED),
        )),
        Line::from(Span::styled(
            "2. config.json is merged; existing keys win.",
            Style::default().fg(MUTED),
        )),
        Line::from(Span::styled(
            "3. Existing configs and hyprland.conf get timestamped backups.",
            Style::default().fg(MUTED),
        )),
        Line::from(Span::styled(
            "4. Links, desktop entries and Hyprland settings are updated.",
            Style::default().fg(MUTED),
        )),
        Line::from(""),
    ];
    if app.plan.manage_hyprland {
        right.push(Line::from(Span::styled(
            "Hyprland: one managed include will be added.",
            Style::default().fg(AQUA),
        )));
    } else {
        right.push(Line::from(Span::styled(
            "Hyprland: no changes; add the include yourself later.",
            Style::default().fg(DIM),
        )));
    }
    if app.plan.has(Component::Packages) {
        right.push(Line::from(Span::styled(
            "Packages: sudo -n pacman will run. Authenticate with sudo -v first.",
            Style::default().fg(WARNING),
        )));
    }
    if !app.detection.existing.data_dir && app.plan.mode == Mode::Install {
        right.push(Line::from(""));
        right.push(Line::from(Span::styled(
            "This is a fresh install.",
            Style::default().fg(DIM),
        )));
    }
    if let Some(error) = &app.error {
        right.push(Line::from(""));
        right.push(Line::from(Span::styled(
            format!("▲ {error}"),
            Style::default().fg(ERROR),
        )));
    }
    right.push(Line::from(""));
    right.push(Line::from(vec![
        Span::styled("Enter", Style::default().fg(BG).bg(accent(app)).bold()),
        Span::styled(
            if app.plan.dry_run {
                "  run dry-run"
            } else {
                "  start"
            },
            Style::default().fg(accent(app)).bold(),
        ),
    ]));
    frame.render_widget(
        Paragraph::new(right)
            .wrap(Wrap { trim: true })
            .block(
                Block::default()
                    .borders(Borders::LEFT)
                    .border_style(Style::default().fg(SURFACE_HIGH))
                    .padding(Padding::new(2, 1, 0, 0)),
            ),
        columns[1],
    );
}

fn draw_uninstall(frame: &mut Frame, app: &App, area: Rect) {
    let area = centered(area, 92, 23);
    let block = Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(Style::default().fg(ERROR))
        .title(" Remove AETHER ")
        .padding(Padding::new(3, 3, 1, 1));
    let inner = block.inner(area);
    frame.render_widget(block, area);
    let lines = vec![
        Line::from(Span::styled(
            "This removes AETHER program files and integrations.",
            Style::default().fg(TEXT).bold(),
        )),
        Line::from(""),
        Line::from(vec![
            Span::styled("Will remove   ", Style::default().fg(DIM)),
            Span::styled(app.paths.data_dir.display().to_string(), Style::default().fg(TEXT)),
        ]),
        Line::from(vec![
            Span::styled("Will remove   ", Style::default().fg(DIM)),
            Span::styled("the aether symlink and managed desktop entries", Style::default().fg(TEXT)),
        ]),
        Line::from(vec![
            Span::styled("Will remove   ", Style::default().fg(DIM)),
            Span::styled("the AETHER managed Hyprland include block", Style::default().fg(TEXT)),
        ]),
        Line::from(""),
        Line::from(vec![
            Span::styled(
                if app.plan.keep_config { "[✓] " } else { "[ ] " },
                Style::default().fg(accent(app)).bold(),
            ),
            Span::styled("Keep my configuration", Style::default().fg(TEXT).bold()),
            Span::styled(
                if app.plan.keep_config {
                    "   recommended"
                } else {
                    "   will back up, then remove ~/.config/aether"
                },
                Style::default().fg(if app.plan.keep_config { SUCCESS } else { WARNING }),
            ),
        ]),
        Line::from(""),
        Line::from(Span::styled(
            "Backups in ~/.config/aether/backups are never deleted automatically.",
            Style::default().fg(DIM),
        )),
        Line::from(""),
        Line::from(Span::styled(
            "Press Space to change the option. Press Enter to continue.",
            Style::default().fg(MUTED),
        )),
    ];
    frame.render_widget(
        Paragraph::new(lines).wrap(Wrap { trim: false }).block(
            Block::default().padding(Padding::new(0, 0, 0, 0)),
        ),
        inner,
    );
    if let Some(error) = &app.error {
        let _ = error;
    }
}

fn draw_running(frame: &mut Frame, app: &App, area: Rect) {
    let area = centered(area, 112, 28);
    let rows = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Length(7), Constraint::Min(3)])
        .split(area);
    let spinner = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
        [app.tick as usize % 10];
    let completed = app.current_step.saturating_sub(1);
    let ratio = if app.total_steps == 0 {
        0.0
    } else if app.report.is_some() {
        1.0
    } else {
        completed as f64 / app.total_steps as f64
    };
    let elapsed = app
        .started
        .map(|s| s.elapsed().as_secs())
        .unwrap_or(0);
    let block = panel(if app.plan.dry_run {
        "Checking installation"
    } else {
        "Installing AETHER"
    });
    let inner = block.inner(rows[0]);
    frame.render_widget(block, rows[0]);
    let info = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(1),
            Constraint::Length(1),
            Constraint::Length(1),
            Constraint::Length(1),
        ])
        .split(inner);
    frame.render_widget(
        Paragraph::new(Line::from(vec![
            Span::styled(format!("{spinner} "), Style::default().fg(accent(app))),
            Span::styled(
                format!(
                    "Step {} of {}  ",
                    app.current_step.max(1),
                    app.total_steps.max(1)
                ),
                Style::default().fg(DIM),
            ),
            Span::styled(&app.step_label, Style::default().fg(TEXT).bold()),
        ])),
        info[0],
    );
    frame.render_widget(
        Gauge::default()
            .ratio(ratio.clamp(0.0, 1.0))
            .gauge_style(
                Style::default()
                    .fg(accent(app))
                    .bg(SURFACE_HIGH)
                    .add_modifier(Modifier::BOLD),
            )
            .label(format!("{:.0}%", ratio * 100.0)),
        info[1],
    );
    let mut status = vec![Span::styled(
        format!("  elapsed {elapsed}s"),
        Style::default().fg(DIM),
    )];
    if app.cancel.load(std::sync::atomic::Ordering::Relaxed) {
        status.push(Span::styled(
            "   cancellation requested",
            Style::default().fg(WARNING).bold(),
        ));
    }
    frame.render_widget(Paragraph::new(Line::from(status)), info[2]);
    frame.render_widget(
        Paragraph::new(Span::styled(
            "The current step always finishes before cancellation. External commands are never interrupted.",
            Style::default().fg(DIM),
        )),
        info[3],
    );

    let log_height = rows[1].height.saturating_sub(3) as usize;
    let lines: Vec<Line> = app
        .visible_log(log_height)
        .into_iter()
        .map(|line| {
            let (mark, color) = match line.level {
                LogLevel::Info => ("·", MUTED),
                LogLevel::Success => ("✓", SUCCESS),
                LogLevel::Warn => ("▲", WARNING),
                LogLevel::Error => ("✗", ERROR),
                LogLevel::Command => ("$", AQUA),
                LogLevel::DryRun => ("…", WARNING),
            };
            Line::from(vec![
                Span::styled(format!(" {mark} "), Style::default().fg(color)),
                Span::styled(&line.text, Style::default().fg(if matches!(line.level, LogLevel::Error) { ERROR } else { TEXT })),
            ])
        })
        .collect();
    let title = if app.log_offset > 0 {
        format!("Log (scrolled {} lines)", app.log_offset)
    } else {
        "Log".to_string()
    };
    frame.render_widget(
        Paragraph::new(lines)
            .wrap(Wrap { trim: false })
            .block(panel(&title)),
        rows[1],
    );
}

fn draw_complete(frame: &mut Frame, app: &App, area: Rect) {
    let report = app.report.as_ref();
    let success = report.map(|r| r.success).unwrap_or(false);
    let cancelled = report.map(|r| r.cancelled).unwrap_or(false);
    let area = centered(area, 104, 28);
    let columns = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(55), Constraint::Percentage(45)])
        .split(area);
    let (mark, color, heading) = if cancelled {
        ("▲", WARNING, "Installation cancelled")
    } else if success {
        ("✓", SUCCESS, "AETHER is ready")
    } else {
        ("✗", ERROR, "AETHER could not be installed")
    };
    let mut left = vec![
        Line::from(vec![
            Span::styled(format!("{mark}  "), Style::default().fg(color).bold()),
            Span::styled(heading, Style::default().fg(TEXT).bold()),
        ]),
        Line::from(""),
    ];
    if let Some(report) = report {
        left.push(Line::from(Span::styled(
            report.summary(),
            Style::default().fg(MUTED),
        )));
        left.push(Line::from(""));
        left.push(field(
            "Steps",
            format!("{} / {}", report.steps_completed, report.total_steps),
        ));
        left.push(field("Data", report.data_dir.display().to_string()));
        left.push(field("Config", report.config_dir.display().to_string()));
        left.push(field("Theme", report.theme.clone()));
        if let Some(log) = &report.log_path {
            left.push(field("Log", log.display().to_string()));
        }
        if !report.errors.is_empty() {
            left.push(Line::from(""));
            left.push(Line::from(Span::styled(
                "Errors",
                Style::default().fg(ERROR).bold(),
            )));
            for error in report.errors.iter().take(4) {
                left.push(Line::from(Span::styled(
                    format!("  ✗ {error}"),
                    Style::default().fg(ERROR),
                )));
            }
        }
    }
    frame.render_widget(
        Paragraph::new(left).wrap(Wrap { trim: true }).block(panel("Result")),
        columns[0],
    );

    let mut right = vec![Line::from(Span::styled(
        "Next steps",
        Style::default().fg(DIM).bold(),
    ))];
    if success && app.plan.mode == Mode::Uninstall {
        right.push(Line::from(Span::styled(
            "AETHER program files were removed.",
            Style::default().fg(MUTED),
        )));
        if app.plan.keep_config {
            right.push(Line::from(Span::styled(
                "Your configuration was kept.",
                Style::default().fg(MUTED),
            )));
        } else {
            right.push(Line::from(Span::styled(
                "Your configuration was backed up, then removed.",
                Style::default().fg(MUTED),
            )));
        }
        right.push(Line::from(""));
        right.push(Line::from(Span::styled(
            "You can reinstall at any time.",
            Style::default().fg(DIM),
        )));
    } else if success {
        let steps = [
            "Run `aether doctor` to check the runtime.",
            "Start the shell with `aether shell`.",
            "If needed, source ~/.config/hypr/aether/aether.conf for AETHER keybinds.",
            "Log out and choose Hyprland to start a clean session.",
            "Open `aether settings` to change the theme or widgets.",
        ];
        for step in steps {
            right.push(Line::from(vec![
                Span::styled("  → ", Style::default().fg(accent(app))),
                Span::styled(step, Style::default().fg(MUTED)),
            ]));
        }
        right.push(Line::from(""));
        right.push(Line::from(Span::styled(
            "AETHER does not claim to be verified on other distributions.",
            Style::default().fg(DIM),
        )));
    } else {
        right.push(Line::from(Span::styled(
            "Open the log file and fix the first error, then choose Repair.",
            Style::default().fg(MUTED),
        )));
        right.push(Line::from(""));
        right.push(Line::from(Span::styled(
            "No system configuration is deleted by a failed install.",
            Style::default().fg(DIM),
        )));
    }
    if let Some(report) = report {
        if !report.warnings.is_empty() {
            right.push(Line::from(""));
            right.push(Line::from(Span::styled(
                "Warnings",
                Style::default().fg(WARNING).bold(),
            )));
            for warning in report.warnings.iter().take(4) {
                right.push(Line::from(Span::styled(
                    format!("  ▲ {warning}"),
                    Style::default().fg(WARNING),
                )));
            }
        }
    }
    frame.render_widget(
        Paragraph::new(right).wrap(Wrap { trim: true }).block(panel("Finish")),
        columns[1],
    );
}

fn panel(title: &str) -> Block<'_> {
    Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(Style::default().fg(SURFACE_HIGH))
        .title(Span::styled(
            format!(" {title} "),
            Style::default().fg(MUTED).bold(),
        ))
        .style(Style::default().bg(BG))
        .padding(Padding::new(2, 2, 0, 1))
}

fn field(label: &'static str, value: impl Into<String>) -> Line<'static> {
    Line::from(vec![
        Span::styled(format!("{label:<13}"), Style::default().fg(DIM)),
        Span::styled(value.into(), Style::default().fg(TEXT)),
    ])
}

fn centered(area: Rect, width: u16, height: u16) -> Rect {
    let width = width.min(area.width.saturating_sub(2));
    let height = height.min(area.height.saturating_sub(1));
    let x = area.x + area.width.saturating_sub(width) / 2;
    let y = area.y + area.height.saturating_sub(height) / 2;
    Rect {
        x,
        y,
        width,
        height,
    }
}
