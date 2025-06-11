use serde::{ Deserialize, Serialize};

/// Used during posts to create a new reward
#[derive(Debug, Deserialize, Serialize)]
pub(crate) struct CreateReward {
    pub(crate) value: i64,
    pub(crate) user_id: i64,
}

/// Used during updates to change a reward
#[derive(Debug, Deserialize, Serialize)]
pub(crate) struct UpdateReward {
    pub(crate) id: i64,
    pub(crate) value: i64,
}

/// Full reward object from database
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct Reward {
    pub(crate) id: i64,
    pub(crate) value: i64,
    pub(crate) user_id: i64,
    pub(crate) created_at: chrono::DateTime<chrono::Local>,
    pub(crate) updated_at: chrono::DateTime<chrono::Local>,
}