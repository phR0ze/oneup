use serde::{ Deserialize, Serialize};

/// Expected request body for login
#[derive(Debug, Deserialize, Serialize)]
pub(crate) struct LoginRequest {
    pub(crate) handle: String,
    pub(crate) password: String,
}

/// Login response going back to the caller
#[derive(Debug, Deserialize, Serialize)]
pub(crate) struct LoginResponse {
    pub(crate) access_token: String,
    pub(crate) token_type: String,
}

// Credential structure used to keep the salt and hash together
#[derive(Debug, Clone)]
pub(crate) struct Credential {
  pub(crate) salt: String,
  pub(crate) hash: String,
}

/// JWT claims structure used during toeken generation and validation
#[derive(Debug, Clone, Deserialize, Serialize)]
pub(crate) struct JwtClaims {
    pub(crate) sub: i64,                    // User ID
    pub(crate) username: String,            // User username
    pub(crate) email: String,               // User Email
    pub(crate) roles: Vec<super::UserRole>, // User Email
    pub(crate) exp: usize,                  // Expiration time in seconds
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
