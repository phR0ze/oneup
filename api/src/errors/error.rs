/// An extensible way to capture various error message types
#[derive(Debug, PartialEq, Eq)]
pub enum ErrorKind {
  NotFound,
  NotUnique,
  Rejection,
  Unauthorized,
  Other,
}

/// The kind of parse errors that can be generated
#[derive(Debug)]
pub enum ErrorSource {
  Sqlx(sqlx::Error),
  Http(super::HttpError),
  Decode(base64::DecodeError),
  JsonRejection(axum::extract::rejection::JsonRejection),
}

#[derive(Debug)]
pub struct Error {
  pub msg: String,
  pub kind: ErrorKind,
  pub source: Option<ErrorSource>,
}

impl Error {
  /// Constructs a new HTTP error.
  ///
  /// #### Parameters
  /// - ***status*** - the HTTP status code associated with the error
  /// - ***msg*** - a descriptive message for the error
  /// 
  /// #### Returns
  /// - ***Error*** - the new error
  pub fn http(status: axum::http::StatusCode, msg: &str) -> Self 
  {
    Self {
      msg: msg.into(),
      kind: match status {
        axum::http::StatusCode::UNAUTHORIZED => ErrorKind::Unauthorized,
        _ => ErrorKind::Other,
      },
      source: Some(ErrorSource::Http(super::HttpError {
        msg: msg.into(),
        status,
      })),
    }
  }

  /// Create a new error from a SQLx error
  /// 
  /// #### Parameters
  /// - ***e*** - the SQLx error to check
  /// - ***msg*** - the error context message
  /// 
  /// #### Returns
  /// - ***Error*** - the new error
  pub fn from_sqlx(e: sqlx::Error, msg: &str) -> Self 
  {
    Self {
      msg: msg.into(),
      kind: if Self::is_sqlx_unique_violation(&e) {
        ErrorKind::NotUnique
      } else if Self::is_sqlx_not_found(&e) {
        ErrorKind::NotFound
      } else {
        ErrorKind::Other
      },
      source: Some(ErrorSource::Sqlx(e)),
    }
  }

  /// Determine if the given sqlx error is a unique violation error
  /// 
  /// #### Parameters
  /// - ***e*** - the SQLx error to check
  /// 
  /// #### Returns
  /// - ***bool*** - true if the error is a unique violation, false otherwise
  pub fn is_sqlx_unique_violation(e: &sqlx::Error) -> bool 
  {
    if let sqlx::Error::Database(db_err) = &e {
      if db_err.kind() == sqlx::error::ErrorKind::UniqueViolation {
        return true;
      }
    }
    false
  }

  /// Determine if the given sqlx error is a not found error
  /// 
  /// #### Parameters
  /// - ***e*** - the SQLx error to check
  /// 
  /// #### Returns
  /// - ***bool*** - true if the error is a not found error, false otherwise
  pub fn is_sqlx_foreign_key_constraint_failed(e: &sqlx::Error) -> bool 
  {
    if let sqlx::Error::Database(db_err) = &e {
      if db_err.kind() == sqlx::error::ErrorKind::ForeignKeyViolation {
        return true;
      }
    }
    false
  }

  /// Determine if the given sqlx error is a not found error
  /// 
  /// #### Parameters
  /// - ***e*** - the SQLx error to check
  /// 
  /// #### Returns
  /// - ***bool*** - true if the error is a not found error, false otherwise
  pub fn is_sqlx_not_found(e: &sqlx::Error) -> bool 
  {
    if let sqlx::Error::RowNotFound = &e {
      return true;
    }
    false
  }

  /// Expose the source variant directly
  pub fn as_http(&self) -> Option<&super::HttpError> 
  {
    if let Some(ErrorSource::Http(e)) = &self.source {
      return Some(e);
    }
    None
  }

  /// Convert the error into an HttpError equivalent
  pub fn to_http(self) -> super::HttpError 
  {
    super::HttpError {
      msg: self.msg,
      status: match self.source {
        Some(ErrorSource::Http(e)) => e.status,
        Some(ErrorSource::Decode(_)) => axum::http::StatusCode::UNAUTHORIZED,
        Some(ErrorSource::Sqlx(_)) => {
          match self.kind {
            ErrorKind::NotFound => axum::http::StatusCode::NOT_FOUND,
            ErrorKind::NotUnique => axum::http::StatusCode::CONFLICT,
            _ => axum::http::StatusCode::BAD_REQUEST,
          } 
        },
        Some(ErrorSource::JsonRejection(e)) => e.status(),
        None => axum::http::StatusCode::INTERNAL_SERVER_ERROR,
      },
    }
  }
}

impl std::fmt::Display for Error {
  fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result 
  {
    match &self.source {
      Some(ErrorSource::Http(e)) => write!(f, "{}", e)?,
      Some(ErrorSource::Sqlx(e)) => write!(f, "{}: {}", self.msg, e)?,
      Some(ErrorSource::Decode(e)) => write!(f, "{}: {}", self.msg, e)?,
      Some(ErrorSource::JsonRejection(e)) => write!(f, "{}: {}", self.msg, e)?,
      None => write!(f, "{}", self.msg)?,
    };
    Ok(())
  }
}

impl std::error::Error for Error {
  fn source(&self) -> Option<&(dyn std::error::Error + 'static)> 
  {
    match &self.source {
      Some(ErrorSource::Http(_)) => None,
      Some(ErrorSource::Sqlx(e)) => Some(e),
      Some(ErrorSource::Decode(e)) => Some(e),
      Some(ErrorSource::JsonRejection(e)) => Some(e),
      None => None,
    }
  }
}

// Provides the ability to use `Error` as an Axum response
impl axum::response::IntoResponse for Error {
  fn into_response(self) -> axum::response::Response 
  {
    self.to_http().into_response()
  }
}

impl From<base64::DecodeError> for Error {
  fn from(err: base64::DecodeError) -> Self 
  {
    Self {
      msg: "Base64 decode error".to_string(),
      kind: ErrorKind::Unauthorized,
      source: Some(ErrorSource::Decode(err)),
    }
  }
}

// Custom regjection implementation to convert `From<JsonRejection>` to `Error`
impl From<axum::extract::rejection::JsonRejection> for Error {
  fn from(rejection: axum::extract::rejection::JsonRejection) -> Self 
  {
    Self {
      msg: rejection.body_text(),
      kind: ErrorKind::Rejection,
      source: Some(ErrorSource::JsonRejection(rejection)),
    }
  }
}

#[cfg(test)]
mod tests {
  use super::*;
  use crate::state;

  #[tokio::test]
  async fn test_database_conflict() 
  {
    let state = state::test().await;
    let user1 = "user1";
    let email1 = "user1@foo.com";

    // Generate a conflict error
    sqlx::query(r#"INSERT INTO user (username, email) VALUES (?, ?)"#)
    .bind(user1).bind(email1).execute(state.db()).await.expect("can't insert user");
    let err = sqlx::query(r#"INSERT INTO user (username, email) VALUES (?, ?)"#)
    .bind(user1).bind(email1).execute(state.db()).await.unwrap_err();

    // Create the new error wrapping the SQLx error
    Error {
      kind: ErrorKind::NotUnique,
      msg: "Database conflict".to_string(),
      source: Some(ErrorSource::Sqlx(err)),
    };
  }
}