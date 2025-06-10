use ring::rand::SecureRandom;
use ring::{digest, pbkdf2, rand};
use std::num::NonZeroU32;
use axum::http::StatusCode;
use serde::{ Deserialize, Serialize};
use crate::errors;

// Target algorithm for PBKDF2
static PBKDF2_ALG: pbkdf2::Algorithm = pbkdf2::PBKDF2_HMAC_SHA256;

// OWASP recommends for PBKDF2 with HMAC-SHA256 to use 6000000 iterations
// but in testing I found that takes noticeablly too much time to compute.
const PBKDF2_ITERS: NonZeroU32 = NonZeroU32::new(100_000).unwrap();

// Default expiration time in seconds (1 hour)
const JWT_EXP: usize = 3600;

#[derive(Debug, Clone)]
pub(crate) struct Credential {
  pub(crate) salt: String,
  pub(crate) hash: String,
}

/// Used during posts to create a new Action
#[derive(Debug, Deserialize, Serialize)]
pub(crate) struct JwtClaims {
    pub(crate) sub: i64,    // User ID
    pub(crate) exp: usize,  // Expiration time in seconds
}

/// Check the given password against the password policy
/// - ***password*** the password to check
pub fn check_password_policy(password: &str) -> errors::Result<()> {

  // Password must be at least 8 characters
  if password.len() < 8 {
    return Err(errors::Error::http(
      StatusCode::UNPROCESSABLE_ENTITY,
      "Password does not meet password policy requirements"));
  }

  Ok(())  
}

/// Generate the user's salt and password hash
/// - Hash the salt/password combination using PBKDF2 with HMAC-SHA256
/// - Returns the resulting salt and hash as a Credential struct
pub fn hash_password(password: &str) -> errors::Result<Credential> {

  // Generate the random salt, recommended length is 16 bytes
  let rng = rand::SystemRandom::new();
  let mut salt = [0u8; 16];
  rng.fill(&mut salt).unwrap();

  // Create an array to hold the hashed password
  let mut pwd_hash = [0u8; digest::SHA256_OUTPUT_LEN];

  // Hash the password using PBKDF2 with HMAC-SHA256
  pbkdf2::derive(PBKDF2_ALG, PBKDF2_ITERS, &salt, password.as_bytes(), &mut pwd_hash);

  Ok(Credential {
    salt: base64::encode(&salt),
    hash: base64::encode(&pwd_hash),
  })
}

/// Verify the password against the stored credential
/// - Uses PBKDF2 with HMAC-SHA256 to hash the input password with the stored salt
/// - ***credential*** is the stored salt and hash
/// - ***password*** is the input password to verify
/// - Returns true if the password matches, false otherwise
pub fn verify_password(credential: &Credential, password: &str) -> errors::Result<()> {
  pbkdf2::verify(
    PBKDF2_ALG, PBKDF2_ITERS,
    &base64::decode(&credential.salt)?,
    password.as_bytes(),
    &base64::decode(&credential.hash)?).map_err(|_| {
      errors::Error::http(axum::http::StatusCode::UNAUTHORIZED, "Password verification failed")
    })?;
  Ok(())
}

/// Generate a JWT token for the given user
/// 
/// - Default expiration is 1 hr
/// - ***secret*** is the JWT private key
/// - ***user_id*** is the ID of the user to include in the token
/// - ***exp*** is the expiration time in seconds from now
pub fn encode_jwt_token(secret: &str, user_id: i64) -> errors::Result<String> {
  let claims = serde_json::json!(JwtClaims {
    sub: user_id,
    exp: (chrono::Utc::now() + chrono::Duration::seconds(JWT_EXP as i64)).timestamp() as usize,
  });

  let header = jsonwebtoken::Header::default();
  let encoding_key = jsonwebtoken::EncodingKey::from_secret(secret.as_bytes());

  jsonwebtoken::encode(&header, &claims, &encoding_key).map_err(|_| {
    errors::Error::http(axum::http::StatusCode::INTERNAL_SERVER_ERROR, "Failed to generate JWT token")
  })
}

/// Decode a JWT token and return the claims
/// 
/// - ***secret*** is the JWT private key used to sign the token
/// - ***token*** is the JWT token to decode
pub fn decode_jwt_token(secret: &str, token: &str) -> errors::Result<JwtClaims> {
  let decoding_key = jsonwebtoken::DecodingKey::from_secret(secret.as_bytes());
  let validation = jsonwebtoken::Validation::default();

  jsonwebtoken::decode::<JwtClaims>(token, &decoding_key, &validation)
    .map(|data| data.claims)
    .map_err(|_| {
      errors::Error::http(axum::http::StatusCode::UNAUTHORIZED, "Invalid JWT token")
    })
}

#[cfg(test)]
mod tests {
  use super::*;

  #[test]
  fn test_encode_and_decode_jwt_token() {
    let private_key = "secret";

    let jwt = encode_jwt_token(private_key, 1).unwrap();
    let claims = decode_jwt_token(private_key, &jwt).unwrap();

    assert_eq!(claims.sub, 1);
    assert!(claims.exp > 0);

    //println!("jwt: {jwt}");
  }

  #[test]
  fn test_decode_jwt_token_failure_wrong_private_key() {
    let private_key = "secret";
    let jwt = encode_jwt_token(private_key, 1).unwrap();

    let err = decode_jwt_token("bad key", &jwt).unwrap_err();
    assert_eq!(err.kind, errors::ErrorKind::Unauthorized);
    assert_eq!(err.msg, "Invalid JWT token");
  }
  
  #[test]
  fn test_hash_and_verify_password() {
    let password  = "test123";
    let credential = hash_password(&password).unwrap();
    assert!(verify_password(&credential, &password).is_ok());

    let err = verify_password(&credential, "foobar").unwrap_err();
    assert_eq!(err.kind, errors::ErrorKind::Unauthorized);
    assert_eq!(err.msg, "Password verification failed");
  }
}
