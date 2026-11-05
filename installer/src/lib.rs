//! AETHER installer library.
//!
//! The binary is a thin wrapper around this crate; the TUI and every
//! filesystem operation live here so they can be tested without a terminal.

pub mod app;
pub mod config;
pub mod distro;
pub mod fsutil;
pub mod hyprland;
pub mod installer;
pub mod integration;
pub mod logging;
pub mod paths;
pub mod plan;
pub mod report;
pub mod source;
pub mod tui;

pub const PROJECT_NAME: &str = "AETHER";
pub const TAGLINE: &str = "Your desktop. Your atmosphere. Your AETHER.";

pub fn version() -> &'static str {
    include_str!("../../VERSION").trim()
}
