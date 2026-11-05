//! Progress reporting shared by the executor and the TUI.

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum LogLevel {
    Info,
    Success,
    Warn,
    Error,
    Command,
    DryRun,
}

#[derive(Debug, Clone)]
pub struct LogLine {
    pub level: LogLevel,
    pub text: String,
}

pub trait Reporter: Send {
    fn step(&mut self, index: usize, total: usize, label: &str);
    fn line(&mut self, level: LogLevel, message: &str);
    fn finish(&mut self, _report: &crate::installer::RunReport) {}
}

/// Reporter used by unit tests and by `--dry-run` callers outside the TUI.
#[derive(Debug, Default)]
pub struct BufferReporter {
    pub lines: Vec<LogLine>,
    pub steps: Vec<String>,
}

impl Reporter for BufferReporter {
    fn step(&mut self, _index: usize, _total: usize, label: &str) {
        self.steps.push(label.to_string());
    }

    fn line(&mut self, level: LogLevel, message: &str) {
        self.lines.push(LogLine {
            level,
            text: message.to_string(),
        });
    }
}
