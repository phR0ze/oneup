use sqlx::SqlitePool;
use ring::rand::{ self, SecureRandom};
use axum::http::StatusCode;
use crate::{ errors, model };

/// Insert a new apikey into the database
/// 
/// - error on other SQL errors
/// - ***db*** - the database connection pool
/// - ***value*** - the value of the apikey to insert
pub(crate) async fn insert(db: &SqlitePool, value: &str) -> errors::Result<i64> {
  validate_apikey(&value)?;

  // Create new apikey in the database
  let result = sqlx::query(r#"INSERT INTO apikey (value) VALUES (?)"#)
    .bind(value).execute(db).await;
  match result {
    Ok(query) => Ok(query.last_insert_rowid()),
    Err(e) => {
      if errors::Error::is_sqlx_unique_violation(&e) {
        let msg = format!("ApiKey '{value}' already exists");
        log::warn!("{msg}");
        return Err(errors::Error::from_sqlx(e, &msg));
      }
      let msg = format!("Error inserting apikey '{value}'");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

/// Get the most recent un-revvoked apikey from the database
/// 
/// - Generates a new one if none exists
/// - error on other SQL errors
/// - ***db*** - the database connection pool
pub(crate) async fn fetch_latest(db: &SqlitePool) -> errors::Result<model::ApiKey> {

  // Fetch the latest un-revoked apikey
  let result = sqlx::query_as::<_, model::ApiKey>(
    r#"SELECT * FROM apikey WHERE revoked = 0 ORDER BY created_at DESC LIMIT 1"#)
    .fetch_optional(db).await;

  match result {
    Ok(Some(apikey)) => Ok(apikey),
    Ok(None) => {
      // If no un-revoked apikey exists, generate a new one
      let rng = rand::SystemRandom::new();
      let mut bytes = [0u8; 96];
      rng.fill(&mut bytes).unwrap();
      let key = base64::encode(&bytes);

      // Store the new apikey in the database
      let id = insert(db, &key).await?;
      fetch_by_id(db, id).await
    },
    Err(e) => {
      let msg = "Error fetching latest apikey";
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, msg));
    }
  }
}

/// Get a apikey by ID from the database
/// 
/// - error on apikey not found
/// - error on other SQL errors
/// - ***db*** - the database connection pool
/// - ***id*** - the ID of the apikey to fetch
pub(crate) async fn fetch_by_id(db: &SqlitePool, id: i64) -> errors::Result<model::ApiKey> {

  let result = sqlx::query_as::<_, model::ApiKey>(r#"SELECT * FROM apikey WHERE id = ?"#)
    .bind(id).fetch_one(db).await;
  match result {
    Ok(apikey) => Ok(apikey),
    Err(e) => {
      if errors::Error::is_sqlx_not_found(&e) {
        let msg = format!("ApiKey with id '{id}' was not found");
        log::warn!("{msg}");
        return Err(errors::Error::from_sqlx(e, &msg));
      } 
      let msg = format!("Error fetching apikey with id '{id}'");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

/// Get all apikeys from the database
/// 
/// - error on other SQL errors
/// - ***db*** - the database connection pool
pub(crate) async fn fetch_all(db: &SqlitePool) -> errors::Result<Vec<model::ApiKey>> {
  let result = sqlx::query_as::<_, model::ApiKey>(r#"SELECT * FROM apikey"#).fetch_all(db).await;
  match result {
    Ok(apikeys) => Ok(apikeys),
    Err(e) => {
      let msg = format!("Error fetching apikeys");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
}

/// Update a apikey in the database
/// 
/// - only the revoked field can be updated
/// - error on not found
/// - error on other SQL errors
/// - ***db*** - the database connection pool
/// - ***id*** - the ID of the apikey to update
/// - ***revoked*** - the revoked status to set
pub(crate) async fn update_by_id(db: &SqlitePool, id: i64, revoked: bool) -> errors::Result<()> {
  let apikey = fetch_by_id(db, id).await?;

  // Update apikey revoked if changed
  if apikey.revoked != revoked {
    let result = sqlx::query(r#"UPDATE apikey SET revoked = ? WHERE id = ?"#)
      .bind(&revoked).bind(&id).execute(db).await;
    if let Err(e) = result {
      let msg = format!("Error updating apikey with id '{id}'");
      log::error!("{msg}");
      return Err(errors::Error::from_sqlx(e, &msg));
    }
  }
  Ok(())
}

/// Delete a apikey in the database
/// 
/// - error on other SQL errors
/// - ***db*** - the database connection pool
/// - ***id*** - the ID of the apikey to delete
pub(crate) async fn delete_by_id(db: &SqlitePool, id: i64) -> errors::Result<()> {

  let result = sqlx::query(r#"DELETE from apikey WHERE id = ?"#).bind(id).execute(db).await;
  if let Err(e) = result {
    let msg = format!("Error deleting apikey with id '{id}'");
    log::error!("{msg}");
    return Err(errors::Error::from_sqlx(e, &msg));
  }
  Ok(())
}

// Check if the apikey value is a valid length
fn validate_apikey(value: &str) -> errors::Result<()> {
  if value.is_empty() {
    let msg = "ApiKey value is required";
    log::warn!("{msg}");
    return Err(errors::Error::http(StatusCode::UNPROCESSABLE_ENTITY, msg));
  }
  Ok(())
}

#[cfg(test)]
mod tests {
  use super::*;
  use crate::state;
  use axum::http::StatusCode;

  #[tokio::test]
  async fn test_fetch_latest_success_existing_apikey() {
    let state = state::test().await;
    let apikey1 = "apikey1";

    // Insert an existing apikey
    insert(state.db(), apikey1).await.unwrap();

    // Fetch the latest apikey
    let apikey = fetch_latest(state.db()).await.unwrap();
    assert_eq!(apikey.value, apikey1);
    assert_eq!(apikey.revoked, false);
    assert!(apikey.created_at <= chrono::Local::now());
    assert!(apikey.updated_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_fetch_latest_success_generate_new_apikey() {
    let state = state::test().await;

    // Fetch the latest apikey when none exists
    let apikey = fetch_latest(state.db()).await.unwrap();
    assert!(!apikey.value.is_empty());
    assert_eq!(apikey.revoked, false);
    assert!(apikey.created_at <= chrono::Local::now());
    assert!(apikey.updated_at <= chrono::Local::now());

    println!("Generated new apikey: {}", apikey.value);
  }

  #[tokio::test]
  async fn test_delete_success() {
    let state = state::test().await;
    let apikey1 = "apikey1";
    let id = insert(state.db(), apikey1).await.unwrap();

    delete_by_id(state.db(), id).await.unwrap();

    let err = fetch_by_id(state.db(), id).await.unwrap_err();
    assert_eq!(err.kind, errors::ErrorKind::NotFound);
  }

  #[tokio::test]
  async fn test_update_success() {
    let state = state::test().await;
    let apikey1 = "apikey1";
    let id = insert(state.db(), apikey1).await.unwrap();

    update_by_id(state.db(), id, true).await.unwrap();

    let apikey = fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(apikey.id, id);
    assert_eq!(apikey.value, apikey1);
    assert_eq!(apikey.revoked, true);
  }

  #[tokio::test]
  async fn test_update_failure_not_found() {
    let state = state::test().await;

    let err = update_by_id(state.db(), -1, true).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::NOT_FOUND);
    assert_eq!(err.msg, format!("ApiKey with id '-1' was not found"));
  }

  #[tokio::test]
  async fn test_insert_success() {
    let state = state::test().await;
    let apikey1 = "apikey1";

    // Insert a new apikey
    let id = insert(state.db(), apikey1).await.unwrap();
    assert_eq!(id, 1);

    let apikey = fetch_by_id(state.db(), id).await.unwrap();
    assert_eq!(apikey.id, 1);
    assert_eq!(apikey.value, apikey1);
    assert_eq!(apikey.revoked, false);
    assert!(apikey.created_at <= chrono::Local::now());
    assert!(apikey.updated_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_fetch_all_success() {
    let state = state::test().await;
    let apikey1 = "apikey1";
    let apikey2 = "apikey2";

    insert(state.db(), apikey1).await.unwrap();
    insert(state.db(), apikey2).await.unwrap();

    let apikeys = fetch_all(state.db()).await.unwrap();
    assert_eq!(apikeys.len(), 2);

    assert_eq!(apikeys[0].id, 1);
    assert_eq!(apikeys[0].value, apikey1);
    assert_eq!(apikeys[0].revoked, false);
    assert!(apikeys[0].created_at <= chrono::Local::now());
    assert!(apikeys[0].updated_at <= chrono::Local::now());

    assert_eq!(apikeys[1].id, 2);
    assert_eq!(apikeys[1].value, apikey2);
    assert_eq!(apikeys[1].revoked, false);
    assert!(apikeys[1].created_at <= chrono::Local::now());
    assert!(apikeys[1].updated_at <= chrono::Local::now());
  }

  #[tokio::test]
  async fn test_fetch_by_id_failure_not_found() {
    let state = state::test().await;

    let err = fetch_by_id(state.db(), -1).await.unwrap_err().to_http();
    assert_eq!(err.status, StatusCode::NOT_FOUND);
    assert_eq!(err.msg, format!("ApiKey with id '-1' was not found"));
  }
}