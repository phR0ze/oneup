use serde::{ Deserialize, Serialize};

/// Used during posts to create a new points entry
#[derive(Debug, Deserialize, Serialize)]
pub struct CreatePoints {
    pub value: i64,
    pub user_id: i64,
    pub action_id: i64,
}

/// Used during updates to change a points entry
#[derive(Debug, Deserialize, Serialize)]
pub struct UpdatePoints {
    pub value: i64,
    pub action_id: i64,
}

/// Full points object from database
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub struct Points {
    pub id: i64,
    pub value: i64,
    pub user_id: i64,
    pub action_id: i64,
    pub created_at: chrono::DateTime<chrono::Local>,
    pub updated_at: chrono::DateTime<chrono::Local>,
}