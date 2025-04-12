use log::Record;
use logforth::layout::Layout;
use logforth::Diagnostic;
use std::path::Path;
use std::ffi::OsStr;
use dotenvy::dotenv;
use anyhow::{anyhow, Result};

use super::model::Config;

mod errors;
mod security;
pub(crate) use security::*;
pub(crate) use errors::*;

/// Load configuration
/// - is called before logging is fully setup
/// - prioritize cli flags, then env vars, then .env file, then config file
/// - TODO: add config file support
/// - TODO: support reading env vars first before .env overrides them
pub(crate) fn load_config() -> Result<Config> {

  // Optionally set environment variables based on .env file
  dotenv().ok();

  // Load configuration from environment variables
  match envy::from_env::<Config>() {
    Ok(config) => {
      return Ok(config);
    },
    Err(e) => Err(anyhow!("loading configuration: {}", e)),
  }
}


/// Configure observability functions like logging and tracing
/// 
/// - `service_name`: The name to use for tracing service visualization
/// - `config`: The configuration to use for logging
pub(crate) fn observe(service_name: &str, config: &Config) {

  // Setup logging with logforth
  logforth::builder()

    // Log to stdout
    .dispatch(|x|
      x.append(logforth::append::Stdout::default().with_layout(LogLayout))
    )

    // Integrate with tracing
    .dispatch(|x|
      // Attaches trace id to logs
      x.diagnostic(logforth::diagnostic::FastraceDiagnostic::default())
        // Attaches logs to spans
        .append(logforth::append::FastraceEvent::default())
    )
    .apply();

  // Setup tracing with fastrace
  // fastrace::set_reporter(
  //   fastrace::collector::ConsoleReporter,
  //   fastrace::collector::Config::default()
  // );
  // fastrace::set_reporter(
  //     fastrace_jaeger::JaegerReporter::new("127.0.0.1:6831".parse().unwrap(), service_name).unwrap(),
  //     fastrace::collector::Config::default()
  // );

  // Set the log level for the whole application
  log::set_max_level(config.log_level.clone());

  log::info!("Starting {}...", service_name);
  log::info!("Configuration loaded...");
  log::debug!("{:?}", config);
}

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
struct LogLayout;

impl Layout for LogLayout {
  fn format(&self, record: &Record, _: &[Box<dyn Diagnostic>]) -> anyhow::Result<Vec<u8>> {

    // Adjust the time format to drop the printed timezone name for brevity
    // e.g. "2025-04-10T13:10:12.572"
    //let time = jiff::Zoned::now().round(jiff::Unit::Millisecond).unwrap();
    //let time_str = time.strftime("%Y-%m-%dT%H:%M:%S%.3f");
    let time = chrono::Local::now();
    let time_str = time.format("%Y-%m-%dT%H:%M:%S%.3f");

    // Get the file name from the given path
    // e.g. "mod.rs"
    let file = record.file().map(Path::new).and_then(Path::file_name)
      .map(OsStr::to_string_lossy).unwrap_or_default();

    let level = record.level().to_string();       // e.g. "INFO"
    let module = record.target();                 // e.g. "oneup_api::utils"
    let line = record.line().unwrap_or_default(); // e.g. 38
    let message = record.args();                  // e.g. "Starting oneup..."

    // Format the log message
    let output = format!("{level:>5} [{time_str} {module}::{file}:{line}] {message}");

    Ok(output.into_bytes())
  }
}