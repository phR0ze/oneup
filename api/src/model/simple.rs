use serde::{Deserialize, Serialize};

/// Simple message type
#[derive(Debug, Deserialize, Serialize)]
pub struct Simple {
  pub message: String,
}

impl Simple {

  /// Create a new simple message
  pub fn new(msg: &str) -> Self {
    Self {
      message: msg.to_string(),
    }
  }
}