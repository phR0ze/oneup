use serde::Deserialize;

/// Application configuration
#[derive(Deserialize, Debug)]
pub(crate) struct Config {
  pub(crate) ip: String,
  pub(crate) port: u16,
  pub(crate) db_url: String,
}
