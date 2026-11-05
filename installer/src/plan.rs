//! Installation plans, components and profiles.

use crate::paths::Paths;
use crate::source::Source;
use std::collections::BTreeSet;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Mode {
    Install,
    Repair,
    Uninstall,
}

impl Mode {
    pub fn label(self) -> &'static str {
        match self {
            Mode::Install => "Install",
            Mode::Repair => "Repair",
            Mode::Uninstall => "Uninstall",
        }
    }

    pub fn lower(self) -> &'static str {
        match self {
            Mode::Install => "install",
            Mode::Repair => "repair",
            Mode::Uninstall => "uninstall",
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub enum Component {
    Shell,
    Apps,
    Themes,
    Wallpapers,
    Hyprland,
    Integration,
    Packages,
}

impl Component {
    pub const ALL: [Component; 7] = [
        Component::Shell,
        Component::Apps,
        Component::Themes,
        Component::Wallpapers,
        Component::Hyprland,
        Component::Integration,
        Component::Packages,
    ];

    pub fn id(self) -> &'static str {
        match self {
            Component::Shell => "shell",
            Component::Apps => "apps",
            Component::Themes => "themes",
            Component::Wallpapers => "wallpapers",
            Component::Hyprland => "hyprland",
            Component::Integration => "integration",
            Component::Packages => "packages",
        }
    }

    pub fn label(self) -> &'static str {
        match self {
            Component::Shell => "Desktop shell",
            Component::Apps => "Application suite",
            Component::Themes => "Themes",
            Component::Wallpapers => "Wallpapers & branding",
            Component::Hyprland => "Hyprland integration",
            Component::Integration => "Commands & desktop entries",
            Component::Packages => "System packages (sudo)",
        }
    }

    pub fn description(self) -> &'static str {
        match self {
            Component::Shell => "Quickshell bar, launcher, dashboard and notifications",
            Component::Apps => "Settings, Music, Monitor, Files, Wallpaper and Power",
            Component::Themes => "Seven built-in themes and the theme index",
            Component::Wallpapers => "Default wallpapers, logo and application icon",
            Component::Hyprland => "Static keybind file and generated visual settings",
            Component::Integration => "aether command, .desktop entries and app icon",
            Component::Packages => "Install missing Arch dependencies with sudo -n",
        }
    }

    pub fn required(self) -> bool {
        matches!(self, Component::Shell | Component::Themes)
    }

    pub fn from_id(id: &str) -> Option<Self> {
        Component::ALL.into_iter().find(|c| c.id() == id)
    }
}

impl std::fmt::Display for Component {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(self.id())
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Profile {
    Minimal,
    Standard,
    Complete,
}

impl Profile {
    pub const ALL: [Profile; 3] = [Profile::Minimal, Profile::Standard, Profile::Complete];

    pub fn name(self) -> &'static str {
        match self {
            Profile::Minimal => "Minimal",
            Profile::Standard => "Standard",
            Profile::Complete => "Complete",
        }
    }

    pub fn description(self) -> &'static str {
        match self {
            Profile::Minimal => "Shell, themes and the aether command. No extra applications.",
            Profile::Standard => "The full desktop: shell, applications, themes and integrations.",
            Profile::Complete => "Everything, including missing system packages via sudo -n.",
        }
    }

    pub fn components(self) -> BTreeSet<Component> {
        let list: &[Component] = match self {
            Profile::Minimal => &[
                Component::Shell,
                Component::Themes,
                Component::Integration,
            ],
            Profile::Standard => &[
                Component::Shell,
                Component::Apps,
                Component::Themes,
                Component::Wallpapers,
                Component::Hyprland,
                Component::Integration,
            ],
            Profile::Complete => &Component::ALL,
        };
        list.iter().copied().collect()
    }

    pub fn detect(components: &BTreeSet<Component>) -> Profile {
        Profile::ALL
            .into_iter()
            .find(|p| &p.components() == components)
            .unwrap_or(Profile::Standard)
    }
}

#[derive(Debug, Clone)]
pub struct InstallPlan {
    pub mode: Mode,
    pub paths: Paths,
    pub source: Source,
    pub components: BTreeSet<Component>,
    pub theme: String,
    pub manage_hyprland: bool,
    pub dry_run: bool,
    pub keep_config: bool,
    pub force_unsupported: bool,
}

impl InstallPlan {
    pub fn new(paths: Paths, source: Source, theme: String) -> Self {
        Self {
            mode: Mode::Install,
            paths,
            source,
            components: Profile::Standard.components(),
            theme,
            manage_hyprland: false,
            dry_run: false,
            keep_config: true,
            force_unsupported: false,
        }
    }

    /// Components recorded by a previous install. Used by repair and uninstall
    /// so an integration is removed only when it was actually installed.
    pub fn installed_components(data_dir: &std::path::Path) -> Option<BTreeSet<Component>> {
        let text = std::fs::read_to_string(data_dir.join(".aether-install.json")).ok()?;
        let value: serde_json::Value = serde_json::from_str(&text).ok()?;
        let list = value.get("components")?.as_array()?;
        let mut set: BTreeSet<Component> = list
            .iter()
            .filter_map(|v| v.as_str())
            .filter_map(Component::from_id)
            .collect();
        set.insert(Component::Shell);
        Some(set)
    }

    pub fn has(&self, component: Component) -> bool {
        self.components.contains(&component)
    }

    pub fn enable(&mut self, component: Component, enabled: bool) {
        if enabled {
            self.components.insert(component);
        } else if !component.required() {
            self.components.remove(&component);
        }
        self.components.insert(Component::Shell);
    }

    pub fn component_ids(&self) -> Vec<&'static str> {
        self.components.iter().map(|c| c.id()).collect()
    }

    pub fn data_source_ready(&self) -> bool {
        self.source.exists("shell/shell.qml") && self.source.exists("themes/index.json")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn shell_cannot_be_disabled() {
        let mut plan = InstallPlan::new(
            Paths::for_test(std::path::Path::new("/tmp/aether-test")),
            Source::Embedded,
            "aether-dark".into(),
        );
        plan.enable(Component::Shell, false);
        plan.enable(Component::Themes, false);
        assert!(plan.has(Component::Shell));
        assert!(plan.has(Component::Themes));
    }

    #[test]
    fn profiles_round_trip() {
        for profile in Profile::ALL {
            assert_eq!(Profile::detect(&profile.components()), profile);
        }
        assert!(Profile::Complete.components().contains(&Component::Packages));
        assert!(!Profile::Minimal.components().contains(&Component::Apps));
    }

    #[test]
    fn component_ids_are_stable() {
        for component in Component::ALL {
            assert_eq!(Component::from_id(component.id()), Some(component));
        }
    }
}
