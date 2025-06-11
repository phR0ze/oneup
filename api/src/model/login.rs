use serde::{ Deserialize, Serialize};

/// Used during posts to login a user
#[derive(Debug, Deserialize, Serialize)]
pub(crate) struct LoginAttempt {
    pub(crate) user_id: i64,
    pub(crate) password: String,
}
