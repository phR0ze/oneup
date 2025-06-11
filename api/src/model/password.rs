use serde::{ Deserialize, Serialize};

/// Used during posts to create a new password
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct CreatePassword {
    pub(crate) user_id: i64,
    pub(crate) password: String,
}

/// Passwords can be created and deleted but never updated

/// Full password object from database
#[derive(Debug, Clone, Deserialize, Serialize, sqlx::FromRow)]
pub(crate) struct Password {
    pub(crate) id: i64,
    pub(crate) salt: String,
    pub(crate) hash: String,
    pub(crate) user_id: i64,
    pub(crate) created_at: chrono::DateTime<chrono::Local>,
}