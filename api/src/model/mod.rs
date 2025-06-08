/*!
 * Models for the application.
 */
pub(crate) mod user;
pub(crate) mod action;
pub(crate) mod config;
pub(crate) mod simple;
pub(crate) mod reward;
pub(crate) mod password;
pub(crate) mod role;
pub(crate) mod point;

pub(crate) use user::*;
pub(crate) use action::*;
pub(crate) use config::*;
pub(crate) use simple::*;
pub(crate) use reward::*;
pub(crate) use password::*;
pub(crate) use role::*;
pub(crate) use point::*;

/// Query parameter filters for various endpoints
#[derive(Debug, Clone, Copy, serde::Deserialize)]
pub(crate) struct Filter{

  // #[serde(default, deserialize_with = "empty_string_as_none")]
  pub(crate) user_id: Option<i64>,

  pub(crate) action_id: Option<i64>,
}

impl Filter {

  /// Create a filter for the specific user
  pub(crate) fn by_user(user_id: i64) -> Self {
    Self {
        user_id: Some(user_id),
        action_id: None,
    }
  }

  /// Create a filter for the specific action
  pub(crate) fn by_action(action_id: i64) -> Self {
    Self {
        user_id: None,
        action_id: Some(action_id),
    }
  }

  /// Create a filter for the specific user and action
  pub(crate) fn by_user_and_action(user_id: i64, action_id: i64) -> Self {
    Self {
        user_id: Some(user_id),
        action_id: Some(action_id),
    }
  }

  /// Are any of the filter values set?
  pub(crate) fn any(self) -> bool {
    self.user_id.is_some() || self.action_id.is_some()
  }
}