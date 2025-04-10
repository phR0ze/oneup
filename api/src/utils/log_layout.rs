use log::Record;
use logforth::layout::Layout;
use logforth::Diagnostic;
use std::path::Path;
use std::ffi::OsStr;

/// A simple custom log layout for logforth.
///
/// ### Example output:
///
/// ```text
///  INFO [2025-04-10T14:18:35.411 oneup_api::utils/mod.rs:38] Starting oneup...
/// ERROR [2025-04-10T14:18:35.411 oneup_api::utils/mod.rs:38] Starting oneup...
///  WARN [2025-04-10T14:18:35.411 oneup_api::utils/mod.rs:38] Starting oneup...
/// ```
#[derive(Debug, Clone, Default)]
pub(crate) struct LogLayout;

impl Layout for LogLayout {
  fn format(&self, record: &Record, _: &[Box<dyn Diagnostic>]) -> anyhow::Result<Vec<u8>> {

    // Adjust the time format to drop the printed timezone name for brevity
    // e.g. "2025-04-10T13:10:12.572"
    let time = jiff::Zoned::now().round(jiff::Unit::Millisecond).unwrap();
    let time_str = time.strftime("%Y-%m-%dT%H:%M:%S%.3f");

    // Get the file name from the given path
    // e.g. "mod.rs"
    let file = record.file().map(Path::new).and_then(Path::file_name)
      .map(OsStr::to_string_lossy).unwrap_or_default();

    let level = record.level().to_string();       // e.g. "INFO"
    let module = record.target();                 // e.g. "oneup_api::utils"
    let line = record.line().unwrap_or_default(); // e.g. 38
    let message = record.args();                  // e.g. "Starting oneup..."

    // Format the log message
    let output = format!("{level:>5} [{time_str} {module}/{file}:{line}] {message}");

    Ok(output.into_bytes())
  }
}