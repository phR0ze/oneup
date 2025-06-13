use serde::{ Deserialize, Serialize};

/// Used during posts to create a new password
#[derive(Debug, Deserialize, Serialize)]
pub struct CreatePassword {
    pub user_id: i64,
    pub password: String,
}

/// Passwords can be created and deleted but never updated

/// Full password object from database
#[derive(Debug, Clone, Deserialize, Serialize, sqlx::FromRow)]
pub struct Password {
    pub id: i64,
    pub salt: String,
    pub hash: String,
    pub user_id: i64,
    pub created_at: chrono::DateTime<chrono::Local>,
}