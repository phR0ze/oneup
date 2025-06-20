use serde::{ Deserialize, Serialize};

/// Used during updates to change a Category
#[derive(Debug, Deserialize, Serialize)]
pub struct CategoryPartial {
  pub name: String,
}

/// Full Category object from database
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub struct Category {
  pub id: i64,
  pub name: String,
  pub created_at: chrono::DateTime<chrono::Local>,
  pub updated_at: chrono::DateTime<chrono::Local>,
}