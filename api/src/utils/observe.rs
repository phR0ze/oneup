use tracing_subscriber::{
  filter::EnvFilter, layer::SubscriberExt, util::SubscriberInitExt
};
use crate::model::Config;

/// Set up a tracing subscriber with a formatter and filtering
pub(crate) fn init(service_name: &str, config: &Config)
{
    // Set up the environment filter for log levels and modules
    let mut filter_str = format!("{}", config.rust_log);
    filter_str.push_str(&format!(",{}={}", service_name, config.rust_log));
    filter_str.push_str(",sqlx=info");
    filter_str.push_str(",tower_http=debug");
    filter_str.push_str(",axum::rejection=trace");
    filter_str.push_str(",axum::response=debug");
    filter_str.push_str(",axum::body=debug");
    filter_str.push_str(",axum::handler=debug");

    // Initialize the tracing subscriber with the custom formatter and filter
    tracing_subscriber::registry()
        .with(EnvFilter::new(filter_str.clone()))
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Log the initialization details
    log::set_max_level(config.rust_log.clone());
    log::info!("Starting {}...", service_name);
    log::info!("Tracing initialized...");
    log::debug!(" - Base filter: {}", filter_str);
    log::debug!(" - Log level: {}", config.rust_log);
    log::info!("Configuration loaded...");
    log::debug!("{:?}", config);
}