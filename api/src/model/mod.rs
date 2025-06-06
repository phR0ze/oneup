/*!
 * Models for the application.
 */
pub(crate) mod user;
pub(crate) mod category;
pub(crate) mod config;
pub(crate) mod simple;
pub(crate) mod reward;
pub(crate) mod password;
pub(crate) mod roles;
pub(crate) mod points;

pub(crate) use user::*;
pub(crate) use category::*;
pub(crate) use config::*;
pub(crate) use simple::*;
pub(crate) use reward::*;
pub(crate) use password::*;
pub(crate) use roles::*;
pub(crate) use points::*;

/// Query parameter filters for various endpoints
#[derive(Debug, Clone, Copy, serde::Deserialize)]
pub(crate) struct Filter{

  // #[serde(default, deserialize_with = "empty_string_as_none")]
  pub(crate) user_id: Option<i64>,

  pub(crate) category_id: Option<i64>,
}

impl Filter {

  /// Create a filter for the specific user
  pub(crate) fn by_user(user_id: i64) -> Self {
    Self {
        user_id: Some(user_id),
        category_id: None,
    }
  }

  /// Create a filter for the specific category
  pub(crate) fn by_category(category_id: i64) -> Self {
    Self {
        user_id: None,
        category_id: Some(category_id),
    }
  }

  /// Create a filter for the specific user and category
  pub(crate) fn by_user_and_category(user_id: i64, category_id: i64) -> Self {
    Self {
        user_id: Some(user_id),
        category_id: Some(category_id),
    }
  }

  /// Are any of the filter values set?
  pub(crate) fn any(self) -> bool {
    self.user_id.is_some() || self.category_id.is_some()
  }
}