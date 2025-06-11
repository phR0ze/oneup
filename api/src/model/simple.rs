use serde::{Deserialize, Serialize};

/// Simple message type
#[derive(Debug, Deserialize, Serialize)]
pub(crate) struct Simple {
  pub(crate) message: String,
}

impl Simple {

  /// Create a new simple message
  pub(crate) fn new(msg: &str) -> Self {
    Self {
      message: msg.to_string(),
    }
  }
}