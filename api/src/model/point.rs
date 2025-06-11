use serde::{ Deserialize, Serialize};

/// Used during posts to create a new points entry
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct CreatePoints {
    pub(crate) value: i64,
    pub(crate) user_id: i64,
    pub(crate) action_id: i64,
}

/// Used during updates to change a points entry
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct UpdatePoints {
    pub(crate) id: i64,
    pub(crate) value: i64,
    pub(crate) action_id: i64,
}

/// Full points object from database
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct Points {
    pub(crate) id: i64,
    pub(crate) value: i64,
    pub(crate) user_id: i64,
    pub(crate) action_id: i64,
    pub(crate) created_at: chrono::DateTime<chrono::Local>,
    pub(crate) updated_at: chrono::DateTime<chrono::Local>,
}