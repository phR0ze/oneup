use log::LevelFilter;
use serde::Deserialize;

/// Application configuration
#[derive(Deserialize, Debug, Clone)]
pub struct Config {
  pub ip: String,
  pub port: u16,
  pub database_url: String,
  pub web_app_dir: String,
  pub rust_log: LevelFilter,
}

impl Config {

  /// Create a new instance that is useful for testing
  #[cfg(test)]
  pub fn test() -> Self {
    Self {
      ip: "127.0.0.1".to_string(),
      port: 8080,
      database_url: "sqlite::memory:".to_string(),
      web_app_dir: "web".to_string(),
      rust_log: LevelFilter::Off,
    }
  }
}