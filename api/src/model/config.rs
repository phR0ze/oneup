use log::LevelFilter;
use serde::Deserialize;

/// Application configuration
#[derive(Deserialize, Debug)]
pub(crate) struct Config {
  pub(crate) ip: String,
  pub(crate) port: u16,
  pub(crate) database_url: String,
  pub(crate) rust_log: LevelFilter,
}

impl Config {

  /// Create a new instance that is useful for testing
  #[cfg(test)]
  pub(crate) fn test() -> Self {
    Self {
      ip: "127.0.0.1".to_string(),
      port: 8080,
      database_url: "sqlite::memory:".to_string(),
      rust_log: LevelFilter::Off,
    }
  }
}