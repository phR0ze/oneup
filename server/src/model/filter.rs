use axum::http::StatusCode;
use chrono::{DateTime, Local};
use sqlx::SqlitePool;
use crate::{db, errors};

/// Query parameter filters for various endpoints
#[derive(Debug, Default, Clone, serde::Deserialize, serde::Serialize)]
pub struct Filter {
  pub user_id: Option<i64>,
  pub action_id: Option<i64>,
  pub role_id: Option<i64>,
  pub role_id_ne: Option<i64>,
  pub role_name: Option<String>,
  pub role_name_ne: Option<String>,
  pub start_date: Option<DateTime<Local>>,
  pub end_date: Option<DateTime<Local>>,
  pub approved: Option<bool>,
}

impl Filter {

  /// Create a new filter
  pub fn new() -> Self {
    Self::default()
  }

  /// Set the date range
  pub fn with_date_range(mut self, start: DateTime<Local>, end: DateTime<Local>) -> Self {
    self.start_date = Some(start);
    self.end_date = Some(end);
    self
  }

  /// Set the user id
  pub fn with_user_id(mut self, user_id: i64) -> Self {
    self.user_id = Some(user_id);
    self
  }

  /// Set the action id
  pub fn with_action_id(mut self, action_id: i64) -> Self {
    self.action_id = Some(action_id);
    self
  }

  /// Set the role id
  pub fn with_role_id(mut self, role_id: i64) -> Self {
    self.role_id = Some(role_id);
    self
  }

  /// Set the role id not equal to
  pub fn with_role_id_ne(mut self, role_id: i64) -> Self {
    self.role_id_ne = Some(role_id);
    self
  }

  /// Set the role name
  pub fn with_role_name(mut self, role_name: &str) -> Self {
    self.role_name = Some(role_name.into());
    self
  }

  /// Set the role name not equal to
  pub fn with_role_name_ne(mut self, role_name: &str) -> Self {
    self.role_name_ne = Some(role_name.into());
    self
  }

  /// Set the action approved status
  pub fn with_approved(mut self, approved: bool) -> Self {
    self.approved = Some(approved);
    self
  }

  /// Set the role name
  /// Get the date range as DateTime objects if both dates are present
  pub fn date_range(&self) -> Option<(DateTime<Local>, DateTime<Local>)> {
    match (&self.start_date, &self.end_date) {
      (Some(start), Some(end)) => {
        Some((*start, *end))
      }
      _ => None,
    }
  }

  /// Are any of the user filter values set?
  pub fn any_user_filters(&self) -> bool {
    self.role_id.is_some() || self.role_id_ne.is_some() || self.role_name.is_some()
      || self.role_name_ne.is_some()
  }

  /// Are any of the points filter values set?
  pub fn any_points_filters(&self) -> bool {
    self.user_id.is_some() || self.action_id.is_some() || self.start_date.is_some()
      || self.end_date.is_some()
  }

  /// Are any of the action filter values set?
  pub fn any_action_filters(&self) -> bool {
    self.approved.is_some()
  }

  /// Convert the filter to a where clause for filtering users
  /// 
  /// - error on no valid filter options provided
  /// - error on both role_id and role_id_ne provided
  /// - error on both role_name and role_name_ne provided
  /// - error on both role_id and role_name provided
  /// - error on other SQL errors
  /// 
  /// #### Parameters
  /// - ***db*** - database connection pool 
  /// 
  /// #### Returns
  /// - ***String*** - where clause for query
  ///   - e.g. `WHERE user_id = ? AND action_id = ?`
  pub async fn to_users_where_clause(&self, _db: &SqlitePool) ->
    errors::Result<String>
  {
    // Error out if no filter values are provided
    if !self.any_user_filters()
    {
      let msg = format!("No valid filter options provided for users.");
      log::error!("{msg}");
      return Err(errors::Error::http(StatusCode::UNPROCESSABLE_ENTITY, &msg));
    }

    // Error out if both role_id and role_id_ne are provided
    if self.role_id.is_some() && self.role_id_ne.is_some() {
      let msg = format!("Both role_id and role_id_ne filter options cannot be provided for users.");
      log::error!("{msg}");
      return Err(errors::Error::http(StatusCode::UNPROCESSABLE_ENTITY, &msg));
   }

   // Error out if both role_name and role_name_ne are provided
    if self.role_name.is_some() && self.role_name_ne.is_some() {
      let msg = format!("Both role_name and role_name_ne filter options cannot be provided for users.");
      log::error!("{msg}");
      return Err(errors::Error::http(StatusCode::UNPROCESSABLE_ENTITY, &msg));
    }
 
    // Error out if both role_id and role_name are provided
    if self.role_id.is_some() && self.role_name.is_some() {
      let msg = format!("Both role_id and role_name filter options cannot be provided for users.");
      log::error!("{msg}");
      return Err(errors::Error::http(StatusCode::UNPROCESSABLE_ENTITY, &msg));
    }

    // Construct where clause and ensure the user and action exist if provided 
    let mut where_clause = "WHERE ".to_string();

    if self.role_id.is_some() {
      where_clause.push_str(&format!("role.id = ?"));
    } else if self.role_name.is_some() {
      where_clause.push_str(&format!("role.name = ?"));
    } else if self.role_id_ne.is_some() {
      where_clause.push_str(&format!("(role.id != ? OR role.id IS NULL)"));
    } else if self.role_name_ne.is_some() {
      where_clause.push_str(&format!("(role.name != ? OR role.name IS NULL)"));
    }

    Ok(where_clause)
  }

  /// Convert the filter to a where clause for filtering points
  /// 
  /// - error on no valid filter options provided
  /// - error on user not found if user_id is provided
  /// - error on action not found if action_id is provided
  /// - error on other SQL errors
  /// 
  /// #### Parameters
  /// - ***db*** - database connection pool 
  /// 
  /// #### Returns
  /// - ***String*** - where clause for query
  ///   - e.g. `WHERE user_id = ? AND action_id = ?`
  pub async fn to_points_where_clause(&self, db: &SqlitePool) ->
    errors::Result<String>
  {
    // Error out if no filter values are provided
    if !self.any_points_filters() {
      let msg = format!("No valid filter options provided for points.");
      log::error!("{msg}");
      return Err(errors::Error::http(StatusCode::UNPROCESSABLE_ENTITY, &msg));
    }

    // Construct where clause and ensure the user and action exist if provided 
    let mut where_clause = "WHERE ".to_string();
    let mut first_condition = true;

    if let Some(user_id) = self.user_id {
      db::user::fetch_by_id(db, user_id).await?;
      where_clause.push_str(&format!("user_id = ?"));
      first_condition = false;
    }
    
    if let Some(action_id) = self.action_id {
      db::action::fetch_by_id(db, action_id).await?;
      if !first_condition {
        where_clause.push_str(" AND ");
      }
      where_clause.push_str(&format!("action_id = ?"));
      first_condition = false;
    }

    if let Some((_, _)) = self.date_range() {
      if !first_condition {
        where_clause.push_str(" AND ");
      }
      where_clause.push_str("datetime(created_at) >= datetime(?) AND datetime(created_at) <= datetime(?)");
    }
    Ok(where_clause)
  }

  /// Convert the filter to a where clause for filtering rewards
  /// 
  /// - error on no valid filter options provided
  /// - error on user not found if user_id is provided
  /// - error on other SQL errors
  /// 
  /// #### Parameters
  /// - ***db*** - database connection pool 
  /// 
  /// #### Returns
  /// - ***String*** - where clause for query
  ///   - e.g. `WHERE user_id = ? AND action_id = ?`
  pub async fn to_rewards_where_clause(&self, db: &SqlitePool) ->
    errors::Result<String>
  {
    // Error out if no filter values are provided
    if self.user_id.is_none() && self.date_range().is_none() {
      let msg = format!("No valid filter options provided for rewards.");
      log::error!("{msg}");
      return Err(errors::Error::http(StatusCode::UNPROCESSABLE_ENTITY, &msg));
    }

    // Construct where clause and ensure the user and action exist if provided 
    let mut where_clause = "WHERE ".to_string();
    let mut first_condition = true;

    if let Some(user_id) = self.user_id {
      db::user::fetch_by_id(db, user_id).await?;
      where_clause.push_str(&format!("user_id = ?"));
      first_condition = false;
    }
    
    if let Some((_, _)) = self.date_range() {
      if !first_condition {
        where_clause.push_str(" AND ");
      }
      where_clause.push_str("datetime(created_at) >= datetime(?) AND datetime(created_at) <= datetime(?)");
    }
    Ok(where_clause)
  }

  /// Convert the filter to a where clause for filtering actions
  /// 
  /// - error on no valid filter options provided
  /// - error on category not found if category_id is provided
  /// - error on other SQL errors
  /// 
  /// #### Parameters
  /// - ***db*** - database connection pool 
  /// 
  /// #### Returns
  /// - ***String*** - where clause for query
  ///   - e.g. `WHERE approved = ?`
  pub async fn to_actions_where_clause(&self, _db: &SqlitePool) ->
    errors::Result<String>
  {
    // Error out if no filter values are provided
    if !self.any_action_filters() {
      let msg = format!("No valid filter options provided for actions.");
      log::error!("{msg}");
      return Err(errors::Error::http(StatusCode::UNPROCESSABLE_ENTITY, &msg));
    }

    // Construct where clause and ensure the approved status is set if provided 
    let mut where_clause = "WHERE ".to_string();

    if self.approved.is_some() {
      where_clause.push_str(&format!("approved = ?"));
    }
    Ok(where_clause)
  }
} 