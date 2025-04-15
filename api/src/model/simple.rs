use serde::{Deserialize, Serialize};

/// Error type to respond with
#[derive(Debug, Deserialize, Serialize)]
pub(crate) struct Simple {
  pub(crate) message: String,
}

impl Simple {

  /// Create a new error
  pub(crate) fn new(msg: &str) -> Self {
    Self {
      message: msg.to_string(),
    }
  }
}