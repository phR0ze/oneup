use crate::errors;
use ring::rand::SecureRandom;
use ring::{digest, pbkdf2, rand};
use std::num::NonZeroU32;

/// Generate the user's password hash
/// - Generate a random salt and concate it with the password
/// - Hash the salt/password combination using SHA256
/// - `hash` is the resulting hash
fn hash_password(password: &str) {
  // Generate the random salt, recommended length is 16 bytes
  let rng = rand::SystemRandom::new();
  let mut salt = [0u8; 16];
  rng.fill(&mut salt).unwrap();

  // OWASP recommends for PBKDF2 with HMAC-SHA256 to use 6000000 iterations
  let iters = NonZeroU32::new(600_000).unwrap();

  // Create an array to hold the hashed password
  let mut pwd_hash = [0u8; digest::SHA256_OUTPUT_LEN];

  // Hash the password using PBKDF2 with HMAC-SHA256
  pbkdf2::derive(pbkdf2::PBKDF2_HMAC_SHA256, iters, &salt, password.as_bytes(), &mut pwd_hash);
}

#[cfg(test)]
mod tests {
  use super::*;
  use crate::{errors, routes, state};
  use axum::{
    body::Body,
    http::{Method, Request, StatusCode},
  };
  use http_body_util::BodyExt;
  use tower::ServiceExt;

  #[tokio::test]
  async fn test_hash_password() {}
}
