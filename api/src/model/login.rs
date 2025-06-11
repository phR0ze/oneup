use serde::{ Deserialize, Serialize};

/// Used during posts to login a user
#[derive(Debug, Deserialize, Serialize)]
pub(crate) struct LoginAttempt {
    pub(crate) user_id: i64,
    pub(crate) password: String,
}

/// Used during posts to login a user
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct ApiKey {
    pub(crate) id: i64,
    pub(crate) value: String,
    pub(crate) revoked: bool,
    pub(crate) created_at: chrono::DateTime<chrono::Local>,
    pub(crate) updated_at: chrono::DateTime<chrono::Local>,
}
