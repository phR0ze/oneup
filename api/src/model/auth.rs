use serde::{ Deserialize, Serialize};

/// Expected request body for login
#[derive(Debug, Deserialize, Serialize)]
pub struct LoginRequest {
    pub handle: String,
    pub password: String,
}

/// Login response going back to the caller
#[derive(Debug, Deserialize, Serialize)]
pub struct LoginResponse {
    pub access_token: String,
    pub token_type: String,
}

// Credential structure used to keep the salt and hash together
#[derive(Debug, Clone)]
pub struct Credential {
  pub salt: String,
  pub hash: String,
}

/// JWT claims structure used during toeken generation and validation
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct JwtClaims {
    pub sub: i64,                    // User ID
    pub username: String,            // User username
    pub email: String,               // User Email
    pub roles: Vec<super::Role>,     // User roles
    pub exp: usize,                  // Expiration time in seconds
}

/// Used during posts to login a user
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub struct ApiKey {
    pub id: i64,
    pub value: String,
    pub revoked: bool,
    pub created_at: chrono::DateTime<chrono::Local>,
    pub updated_at: chrono::DateTime<chrono::Local>,
}
