use tracing_subscriber::{
    filter::EnvFilter, fmt::format::FmtSpan, layer::SubscriberExt, util::SubscriberInitExt
};

use crate::model::Config;

/// Configure observability functions like logging and tracing
/// 
/// - `service_name`: The name to use for tracing service visualization
/// - `config`: The configuration to use for logging
pub(crate) fn init(service_name: &str, config: &Config) {

  // Create a filter with default config.rust_log log level
  let mut filter_str = format!("{}", config.rust_log);
  filter_str.push_str(&format!(",{}={}", service_name, config.rust_log));

  // Set log level for libraries
  filter_str.push_str(",sqlx=info");
  filter_str.push_str(",tower_http=debug");
  filter_str.push_str(",axum::rejection=trace");

  // Set up a tracing subscriber with a formatter and filtering
  let fmt_layer = tracing_subscriber::fmt::layer()
      .with_target(true)
      .with_timer(tracing_subscriber::fmt::time::time())
      .with_span_events(FmtSpan::NEW | FmtSpan::CLOSE)
      .compact();
  
  // Combine the layers
  tracing_subscriber::registry()
      .with(EnvFilter::new(filter_str.clone()))
      .with(fmt_layer)
      .init();

  // Set the log level for the whole application. This is done last to ensure that
  // fastrace is set up before we start logging.
  log::set_max_level(config.rust_log.clone());
  log::info!("Starting {}...", service_name);
  log::info!("Tracing initialized...");
  log::debug!(" - Base filter: {}", filter_str);
  log::debug!(" - Log level: {}", config.rust_log);
  log::info!("Configuration loaded...");
  log::debug!("{:?}", config);
}