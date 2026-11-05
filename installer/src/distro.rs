//! Distribution and runtime detection.
//!
//! Detection is read-only. It never invokes a shell and never escalates
//! privileges. Missing tools are reported exactly as they are found.

use crate::paths::Paths;
use std::collections::HashMap;
use std::fs;
use std::path::Path;
use std::process::{Command, Stdio};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct OsInfo {
    pub id: String,
    pub name: String,
    pub version_id: String,
    pub id_like: Vec<String>,
}

impl OsInfo {
    pub fn is_arch_family(&self) -> bool {
        self.id == "arch" || self.id_like.iter().any(|v| v == "arch")
    }

    pub fn summary(&self) -> String {
        if self.version_id.is_empty() {
            self.name.clone()
        } else {
            format!("{} {}", self.name, self.version_id)
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Tool {
    pub name: &'static str,
    pub found: bool,
    pub purpose: &'static str,
    pub required: bool,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ExistingInstall {
    pub data_dir: bool,
    pub config: bool,
    pub marker_version: Option<String>,
}

#[derive(Debug, Clone)]
pub struct Detection {
    pub os: OsInfo,
    pub session_type: String,
    pub desktop: String,
    pub hyprland_running: bool,
    pub quickshell: bool,
    pub tools: Vec<Tool>,
    pub missing_packages: Vec<String>,
    pub existing: ExistingInstall,
    pub arch_supported: bool,
    pub disk_free: Option<u64>,
}

impl Detection {
    pub fn tool(&self, name: &str) -> bool {
        self.tools
            .iter()
            .find(|t| t.name == name)
            .map(|t| t.found)
            .unwrap_or(false)
    }

    pub fn blocking_issue(&self, force: bool) -> Option<String> {
        if !self.arch_supported && !force {
            return Some(
                "This distribution is not Arch Linux. AETHER is only officially supported \
                 on Arch Linux. Re-run with --force-unsupported to continue anyway."
                    .into(),
            );
        }
        None
    }
}

pub fn detect(paths: &Paths) -> Detection {
    let os = read_os_release(Path::new("/etc/os-release")).unwrap_or_else(|| OsInfo {
        id: "unknown".into(),
        name: "Unknown Linux".into(),
        version_id: String::new(),
        id_like: Vec::new(),
    });
    let tools = vec![
        tool("quickshell", "desktop shell", true),
        tool("python3", "Hyprland config generator", true),
        tool("hyprland", "Wayland compositor", true),
        tool("hyprctl", "compositor control", false),
        tool("pacman", "Arch package manager", false),
        tool("sudo", "optional package installation", false),
        tool("brightnessctl", "brightness control", false),
        tool("hyprsunset", "night light", false),
        tool("wpctl", "PipeWire volume", false),
        tool("nmcli", "NetworkManager control", false),
        tool("bluetoothctl", "Bluetooth control", false),
        tool("playerctl", "media control", false),
    ];
    let existing = ExistingInstall {
        data_dir: paths.data_dir.join("shell/shell.qml").is_file(),
        config: paths.config_dir.join("config.json").is_file(),
        marker_version: read_marker_version(&paths.data_dir),
    };
    let missing_packages = if command_exists("pacman") {
        missing_packages(&supported_packages())
    } else {
        supported_packages()
    };
    let arch_supported = os.is_arch_family();
    Detection {
        os,
        arch_supported,
        session_type: std::env::var("XDG_SESSION_TYPE").unwrap_or_else(|_| "unknown".into()),
        desktop: std::env::var("XDG_CURRENT_DESKTOP").unwrap_or_else(|_| "unknown".into()),
        hyprland_running: std::env::var_os("HYPRLAND_INSTANCE_SIGNATURE").is_some(),
        quickshell: command_exists("quickshell") || command_exists("qs"),
        tools,
        missing_packages,
        existing,
        disk_free: disk_free(&paths.prefix),
    }
}

fn tool(name: &'static str, purpose: &'static str, required: bool) -> Tool {
    Tool {
        name,
        found: command_exists(name),
        purpose,
        required,
    }
}

pub fn command_exists(name: &str) -> bool {
    if name.contains('/') {
        return Path::new(name).is_file();
    }
    std::env::var_os("PATH")
        .map(|paths| {
            std::env::split_paths(&paths)
                .any(|dir| dir.join(name).is_file())
        })
        .unwrap_or(false)
}

pub fn read_os_release(path: &Path) -> Option<OsInfo> {
    let text = fs::read_to_string(path).ok()?;
    let mut values: HashMap<String, String> = HashMap::new();
    for line in text.lines() {
        let line = line.trim();
        if line.is_empty() || line.starts_with('#') {
            continue;
        }
        let Some((key, raw)) = line.split_once('=') else {
            continue;
        };
        values.insert(key.trim().to_string(), unquote(raw.trim()));
    }
    Some(OsInfo {
        id: values.get("ID").cloned().unwrap_or_default(),
        name: values
            .get("PRETTY_NAME")
            .or_else(|| values.get("NAME"))
            .cloned()
            .unwrap_or_else(|| "Unknown Linux".into()),
        version_id: values.get("VERSION_ID").cloned().unwrap_or_default(),
        id_like: values
            .get("ID_LIKE")
            .map(|v| v.split_whitespace().map(str::to_string).collect())
            .unwrap_or_default(),
    })
}

fn unquote(value: &str) -> String {
    let value = value.trim();
    if value.len() >= 2 {
        let bytes = value.as_bytes();
        let (first, last) = (bytes[0], bytes[value.len() - 1]);
        if (first == b'"' && last == b'"') || (first == b'\'' && last == b'\'') {
            let inner = &value[1..value.len() - 1];
            return inner
                .replace("\\\"", "\"")
                .replace("\\'", "'")
                .replace("\\\\", "\\");
        }
    }
    value.to_string()
}

pub fn supported_packages() -> Vec<String> {
    [
        "hyprland",
        "quickshell",
        "qt6-declarative",
        "qt6-svg",
        "qt6-wayland",
        "hyprsunset",
        "pipewire",
        "pipewire-pulse",
        "wireplumber",
        "networkmanager",
        "bluez",
        "bluez-utils",
        "brightnessctl",
        "playerctl",
        "python",
        "ttf-jetbrains-mono",
    ]
    .iter()
    .map(|s| s.to_string())
    .collect()
}

pub fn missing_packages(packages: &[String]) -> Vec<String> {
    if !command_exists("pacman") {
        return packages.to_vec();
    }
    let output = Command::new("pacman")
        .arg("-T")
        .args(packages)
        .stdin(Stdio::null())
        .stderr(Stdio::null())
        .output();
    match output {
        Ok(out) => String::from_utf8_lossy(&out.stdout)
            .lines()
            .map(str::trim)
            .filter(|l| !l.is_empty())
            .map(str::to_string)
            .collect(),
        Err(_) => packages.to_vec(),
    }
}

pub fn read_marker_version(data_dir: &Path) -> Option<String> {
    let text = fs::read_to_string(data_dir.join(".aether-install.json")).ok()?;
    let value: serde_json::Value = serde_json::from_str(&text).ok()?;
    value
        .get("version")
        .and_then(|v| v.as_str())
        .map(str::to_string)
}

pub fn disk_free(path: &Path) -> Option<u64> {
    let output = Command::new("df")
        .arg("-Pk")
        .arg(path)
        .stdin(Stdio::null())
        .stderr(Stdio::null())
        .output()
        .ok()?;
    if !output.status.success() {
        return None;
    }
    let text = String::from_utf8_lossy(&output.stdout);
    let line = text.lines().nth(1)?;
    let kb: u64 = line.split_whitespace().nth(3)?.parse().ok()?;
    Some(kb.saturating_mul(1024))
}

pub fn human_bytes(bytes: u64) -> String {
    const UNITS: [&str; 5] = ["B", "KiB", "MiB", "GiB", "TiB"];
    let mut size = bytes as f64;
    let mut unit = 0;
    while size >= 1024.0 && unit < UNITS.len() - 1 {
        size /= 1024.0;
        unit += 1;
    }
    if unit == 0 {
        format!("{} {}", bytes, UNITS[unit])
    } else {
        format!("{size:.1} {}", UNITS[unit])
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;

    #[test]
    fn parses_arch_os_release() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("os-release");
        let mut file = fs::File::create(&path).unwrap();
        writeln!(
            file,
            "NAME=\"Arch Linux\"\nID=arch\nID_LIKE=archlinux\nPRETTY_NAME=\"Arch Linux\"\nVERSION_ID=rolling\n"
        )
        .unwrap();
        let os = read_os_release(&path).unwrap();
        assert_eq!(os.id, "arch");
        assert!(os.is_arch_family());
        assert_eq!(os.summary(), "Arch Linux rolling");
    }

    #[test]
    fn parses_quoted_and_escaped_values() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("os-release");
        fs::write(
            &path,
            "ID=fedora\nNAME=\"Fedora \\\"Rawhide\\\"\"\nID_LIKE=\"rhel centos\"\n",
        )
        .unwrap();
        let os = read_os_release(&path).unwrap();
        assert!(!os.is_arch_family());
        assert_eq!(os.name, "Fedora \"Rawhide\"");
        assert_eq!(os.id_like, vec!["rhel", "centos"]);
    }

    #[test]
    fn formats_bytes() {
        assert_eq!(human_bytes(512), "512 B");
        assert_eq!(human_bytes(1024), "1.0 KiB");
        assert_eq!(human_bytes(3 * 1024 * 1024), "3.0 MiB");
    }
}
