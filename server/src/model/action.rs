use serde::{ Deserialize, Serialize};

/// Used during posts to create a new Action
#[derive(Debug, Deserialize, Serialize)]
pub struct CreateAction {
  pub desc: String,
  pub value: Option<i64>,
  pub category_id: Option<i64>,
  pub approved: Option<bool>,
}

/// Used during updates to change a Action
#[derive(Debug, Deserialize, Serialize)]
pub struct UpdateAction {
  pub desc: Option<String>,
  pub value: Option<i64>,
  pub category_id: Option<i64>,
  pub approved: Option<bool>,
}

/// Full Action object from database
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub struct Action {
  pub id: i64,
  pub desc: String,
  pub value: i64,
  pub category_id: i64,
  pub approved: bool,
  pub created_at: chrono::DateTime<chrono::Local>,
  pub updated_at: chrono::DateTime<chrono::Local>,
}