//! Configuration and theme handling.
//!
//! The installer never discards a user configuration. Existing values and
//! unknown keys win over defaults; only the choices explicitly made in the
//! installer (theme and Hyprland management) are updated.

use crate::fsutil;
use crate::report::{LogLevel, Reporter};
use crate::source::Source;
use anyhow::{Context, Result};
use serde::Deserialize;
use serde_json::{json, Value};
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, Deserialize)]
pub struct ThemeColors {
    pub primary: String,
    pub secondary: String,
    pub surface: String,
    pub background: String,
}

#[derive(Debug, Clone, Deserialize)]
pub struct ThemeMeta {
    pub id: String,
    pub name: String,
    pub variant: String,
    pub file: String,
    pub colors: ThemeColors,
}

#[derive(Debug, Clone, Deserialize)]
struct ThemeIndex {
    default: String,
    themes: Vec<ThemeMeta>,
}

#[derive(Debug, Clone)]
pub struct ThemeCatalog {
    pub default: String,
    pub themes: Vec<ThemeMeta>,
}

impl ThemeCatalog {
    pub fn load(source: &Source) -> Result<Self> {
        let text = source
            .read_to_string("themes/index.json")
            .context("could not read themes/index.json")?;
        let index: ThemeIndex = serde_json::from_str(&text)
            .context("themes/index.json is not a valid theme index")?;
        if index.themes.is_empty() {
            anyhow::bail!("themes/index.json does not list any themes");
        }
        let default = if index.themes.iter().any(|t| t.id == index.default) {
            index.default
        } else {
            index.themes[0].id.clone()
        };
        Ok(Self {
            default,
            themes: index.themes,
        })
    }

    pub fn get(&self, id: &str) -> Option<&ThemeMeta> {
        self.themes.iter().find(|t| t.id == id)
    }

    pub fn theme_file(&self, theme: &ThemeMeta) -> String {
        format!("themes/{}", theme.file)
    }
}

#[derive(Debug, Clone)]
pub struct ConfigRequest<'a> {
    pub source: &'a Source,
    pub theme: &'a str,
    pub manage_hyprland: bool,
}

#[derive(Debug, Clone, Default)]
pub struct ConfigOutcome {
    pub config_path: Option<PathBuf>,
    pub backup: Option<PathBuf>,
    pub created: bool,
    pub widgets_written: bool,
}

/// Recursively overlay `overlay` on `base`. Objects are merged, arrays and
/// scalars from the overlay replace the base. This is what preserves unknown
/// user keys during an upgrade.
pub fn deep_merge(base: Value, overlay: Value) -> Value {
    match (base, overlay) {
        (Value::Object(mut base_map), Value::Object(overlay_map)) => {
            for (key, value) in overlay_map {
                let merged = match base_map.remove(&key) {
                    Some(existing) => deep_merge(existing, value),
                    None => value,
                };
                base_map.insert(key, merged);
            }
            Value::Object(base_map)
        }
        (_, overlay) => overlay,
    }
}

pub fn set_path(root: &mut Value, path: &[&str], value: Value) {
    if path.is_empty() {
        *root = value;
        return;
    }
    if !root.is_object() {
        *root = json!({});
    }
    let map = root.as_object_mut().expect("object was just ensured");
    if path.len() == 1 {
        map.insert(path[0].to_string(), value);
        return;
    }
    let entry = map
        .entry(path[0].to_string())
        .or_insert_with(|| Value::Object(Default::default()));
    set_path(entry, &path[1..], value);
}

pub fn get_path<'a>(root: &'a Value, path: &[&str]) -> Option<&'a Value> {
    let mut current = root;
    for key in path {
        current = current.get(*key)?;
    }
    Some(current)
}

/// Build the on-disk configuration. Existing configuration is authoritative,
/// then installer choices are applied on top.
pub fn build_config(default: Value, existing: Option<Value>, theme: &str, manage_hyprland: bool) -> Value {
    let mut merged = match existing {
        Some(value) => deep_merge(default, value),
        None => default,
    };
    set_path(
        &mut merged,
        &["appearance", "theme"],
        Value::String(theme.to_string()),
    );
    set_path(
        &mut merged,
        &["hyprland", "manageConfig"],
        Value::Bool(manage_hyprland),
    );
    merged
}

pub fn write_user_config(
    request: &ConfigRequest<'_>,
    paths_config_dir: &Path,
    dry_run: bool,
    reporter: &mut dyn Reporter,
) -> Result<ConfigOutcome> {
    let default_text = request
        .source
        .read_to_string("config/config.default.json")
        .context("could not read config/config.default.json")?;
    let default: Value =
        serde_json::from_str(&default_text).context("config/config.default.json is invalid")?;
    let config_path = paths_config_dir.join("config.json");
    let backups = paths_config_dir.join("backups");
    let mut outcome = ConfigOutcome {
        config_path: Some(config_path.clone()),
        ..Default::default()
    };

    let existing = match fsutil::read_json(&config_path) {
        Ok(value) => value,
        Err(err) => {
            reporter.line(
                LogLevel::Warn,
                &format!("existing config is invalid ({err}); it will be preserved as a backup"),
            );
            None
        }
    };

    let merged = build_config(
        default,
        existing.clone(),
        request.theme,
        request.manage_hyprland,
    );

    if dry_run {
        reporter.line(
            LogLevel::DryRun,
            &format!(
                "would merge defaults with {} and write {}",
                if existing.is_some() {
                    "the existing config"
                } else {
                    "no existing config"
                },
                config_path.display()
            ),
        );
    } else {
        if config_path.exists() {
            let backup = fsutil::backup_file(&config_path, &backups)?;
            outcome.backup = backup.clone();
            reporter.line(
                LogLevel::Info,
                &format!(
                    "backed up existing config to {}",
                    backup
                        .as_ref()
                        .map(|p| p.display().to_string())
                        .unwrap_or_else(|| "(none)".into())
                ),
            );
        } else {
            outcome.created = true;
        }
        fsutil::write_json(&config_path, &merged)?;
        reporter.line(
            LogLevel::Success,
            &format!("wrote merged configuration to {}", config_path.display()),
        );
    }

    let widgets_path = paths_config_dir.join("widgets.json");
    if !widgets_path.exists() {
        let widgets = request
            .source
            .read("config/widgets.default.json")
            .context("could not read config/widgets.default.json")?;
        if dry_run {
            reporter.line(
                LogLevel::DryRun,
                &format!("would write default widgets to {}", widgets_path.display()),
            );
        } else {
            fsutil::atomic_write(&widgets_path, &widgets, None)?;
            outcome.widgets_written = true;
            reporter.line(
                LogLevel::Success,
                &format!("wrote default widget layout to {}", widgets_path.display()),
            );
        }
    } else {
        reporter.line(
            LogLevel::Info,
            "kept the existing widgets.json layout (user-owned)",
        );
    }

    Ok(outcome)
}

/// Hex colour to an RGB tuple. Invalid values fall back to AETHER violet.
pub fn hex_rgb(value: &str) -> (u8, u8, u8) {
    let text = value.trim().trim_start_matches('#');
    if text.len() == 6 {
        if let (Ok(r), Ok(g), Ok(b)) = (
            u8::from_str_radix(&text[0..2], 16),
            u8::from_str_radix(&text[2..4], 16),
            u8::from_str_radix(&text[4..6], 16),
        ) {
            return (r, g, b);
        }
    }
    (169, 155, 255)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_defaults() -> Value {
        json!({
            "schemaVersion": 1,
            "appearance": { "theme": "aether-dark", "fontScale": 1.0 },
            "bar": { "enabled": true, "height": 44 },
            "launcher": { "favorites": ["a"] }
        })
    }

    #[test]
    fn merge_preserves_unknown_user_keys_and_arrays() {
        let existing = json!({
            "bar": { "height": 52 },
            "myCustomSection": { "keep": true },
            "launcher": { "favorites": ["firefox", "kitty"] }
        });
        let merged = build_config(sample_defaults(), Some(existing), "aether-ocean", true);
        assert_eq!(get_path(&merged, &["bar", "height"]).unwrap(), &json!(52));
        assert_eq!(get_path(&merged, &["bar", "enabled"]).unwrap(), &json!(true));
        assert_eq!(
            get_path(&merged, &["myCustomSection", "keep"]).unwrap(),
            &json!(true)
        );
        assert_eq!(
            get_path(&merged, &["launcher", "favorites"]).unwrap(),
            &json!(["firefox", "kitty"])
        );
        assert_eq!(
            get_path(&merged, &["appearance", "theme"]).unwrap(),
            &json!("aether-ocean")
        );
        assert_eq!(
            get_path(&merged, &["hyprland", "manageConfig"]).unwrap(),
            &json!(true)
        );
    }

    #[test]
    fn set_path_creates_missing_objects() {
        let mut value = json!({});
        set_path(&mut value, &["a", "b", "c"], json!(3));
        assert_eq!(value, json!({"a": {"b": {"c": 3}}}));
    }

    #[test]
    fn parses_hex_colours_safely() {
        assert_eq!(hex_rgb("#A99BFF"), (169, 155, 255));
        assert_eq!(hex_rgb("nope"), (169, 155, 255));
        assert_eq!(hex_rgb("#fff"), (169, 155, 255));
    }
}
