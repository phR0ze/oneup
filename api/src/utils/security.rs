use crate::errors;
use ring::rand::SecureRandom;
use ring::{digest, pbkdf2, rand};
use std::num::NonZeroU32;

// Target algorithm for PBKDF2
static PBKDF2_ALG: pbkdf2::Algorithm = pbkdf2::PBKDF2_HMAC_SHA256;

// OWASP recommends for PBKDF2 with HMAC-SHA256 to use 6000000 iterations
// but in testing I found that takes noticeablly too much time to compute.
const PBKDF2_ITERS: NonZeroU32 = NonZeroU32::new(100_000).unwrap();

#[derive(Debug, Clone)]
pub(crate) struct Credential {
  pub(crate) salt: String,
  pub(crate) hash: String,
}

/// Generate the user's salt and password hash
/// - Hash the salt/password combination using PBKDF2 with HMAC-SHA256
/// - Returns the resulting salt and hash as a Credential struct
fn hash_password(password: &str) -> errors::Result<Credential> {

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
fn verify_password(credential: &Credential, password: &str) -> errors::Result<()> {
  pbkdf2::verify(
    PBKDF2_ALG, PBKDF2_ITERS,
    &base64::decode(&credential.salt)?,
    password.as_bytes(),
    &base64::decode(&credential.hash)?).map_err(|_| {
      errors::Error::http(axum::http::StatusCode::UNAUTHORIZED, "Password verification failed")
    })?;
  Ok(())
}

#[cfg(test)]
mod tests {
  use super::*;

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
