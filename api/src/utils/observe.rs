use log::Record;
use logforth::layout::Layout;
use logforth::Diagnostic;
use std::path::Path;
use std::ffi::OsStr;
use tracing_subscriber::layer::SubscriberExt;

use crate::model::Config;

/// Configure observability functions like logging and tracing
/// 
/// - `service_name`: The name to use for tracing service visualization
/// - `config`: The configuration to use for logging
pub(crate) fn init(service_name: &str, config: &Config) {

  // Because Axum is instrumented with `tracing` we need a `tracing-subscriber` redirection to
  // fastrace to get the tracing events into fastrace.
  tracing::subscriber::set_global_default(
    tracing_subscriber::Registry::default().with(fastrace_tracing::FastraceCompatLayer::new()),
  ).unwrap();

  // Setup logging with logforth
  logforth::builder()

    // Log to stdout using the custom logging layout `LogLayout`
    .dispatch(|x|
      x.append(logforth::append::Stdout::default().with_layout(LogLayout))
    )

    // Integrate logforth with fastrace
    .dispatch(|x|

      // Attach trace id to logs
      x.diagnostic(logforth::diagnostic::FastraceDiagnostic::default())

        // Attach logs to spans
        .append(logforth::append::FastraceEvent::default())
    )
    .apply();

  // Configure fastrace reporting to use the console reporter for now
  fastrace::set_reporter(fastrace::collector::ConsoleReporter, fastrace::collector::Config::default());

  // TODO: implement Jaeger reporting later
  // fastrace::set_reporter(
  //     fastrace_jaeger::JaegerReporter::new("127.0.0.1:6831".parse().unwrap(), service_name).unwrap(),
  //     fastrace::collector::Config::default()
  // );

  // Set the log level for the whole application. This is done last to ensure that
  // fastrace is set up before we start logging.
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