
/// Query parameter filters for various endpoints
#[derive(Debug, Clone, Copy, serde::Deserialize)]
pub struct Filter{

  // #[serde(default, deserialize_with = "empty_string_as_none")]
  pub user_id: Option<i64>,

  // #[serde(default, deserialize_with = "empty_string_as_none")]
  pub action_id: Option<i64>,
}

impl Filter {

  /// Create a filter for the specific user
  pub fn by_user(user_id: i64) -> Self {
    Self {
      user_id: Some(user_id),
      action_id: None,
    }
  }

  /// Create a filter for the specific action
  pub fn by_action(action_id: i64) -> Self {
    Self {
      user_id: None,
      action_id: Some(action_id),
    }
  }

  /// Create a filter for the specific user and action
  pub fn by_user_and_action(user_id: i64, action_id: i64) -> Self {
    Self {
      user_id: Some(user_id),
      action_id: Some(action_id),
    }
  }

  /// Are any of the filter values set?
  pub fn any(self) -> bool {
    self.user_id.is_some() || self.action_id.is_some()
  }
}