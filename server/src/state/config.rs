use dotenvy::dotenv;
use anyhow::{anyhow, Result};

use crate::model::Config;

/// Load configuration
/// 
/// - is called before logging is fully setup
/// - prioritize cli flags, then env vars, then .env file, then config file
pub(crate) fn init() -> Result<Config> 
{
  // Load configuration from .env file if it exists
  // then set environment variables based from the .env file
  dotenv().ok();

  // Load configuration from environment variables
  match envy::from_env::<Config>() {
    Ok(config) => return Ok(config),
    Err(e) => Err(anyhow!("loading configuration: {}", e)),
  }
}
