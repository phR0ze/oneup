use serde::{ Deserialize, Serialize};

/// Used during posts to create a new reward
#[derive(Debug, Deserialize, Serialize)]
pub struct CreateReward {
    pub value: i64,
    pub user_id: i64,
}

/// Used during updates to change a reward
#[derive(Debug, Deserialize, Serialize)]
pub struct UpdateReward {
    pub value: i64,
}

/// Full reward object from database
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub struct Reward {
    pub id: i64,
    pub value: i64,
    pub user_id: i64,
    pub created_at: chrono::DateTime<chrono::Local>,
    pub updated_at: chrono::DateTime<chrono::Local>,
}