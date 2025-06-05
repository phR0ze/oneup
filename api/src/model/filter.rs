use axum::http::StatusCode;
use sqlx::SqlitePool;
use crate::errors;

// DTOs
// *************************************************************************************************

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

// Business logic
// *************************************************************************************************
