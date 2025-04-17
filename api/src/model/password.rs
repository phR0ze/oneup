// use serde::{ Deserialize, Serialize};
// use sqlx::SqlitePool;

// use crate::errors;

// /// Used during posts to create a new password
// #[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
// pub(crate) struct CreatePassword {
//     pub(crate) salt: String,
//     pub(crate) hash: String,
//     pub(crate) user_id: i64,
// }

// /// Full password object from database
// #[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
// pub(crate) struct Password {
//     pub(crate) id: i64,
//     pub(crate) salt: String,
//     pub(crate) hash: String,
//     pub(crate) user_id: i64,
//     pub(crate) created_at: chrono::DateTime<chrono::Local>,
//     pub(crate) updated_at: chrono::DateTime<chrono::Local>,
// }

// /// Insert a new password into the database for the given user
// /// - only retains the last 4 passwords for the user, anything older is deleted
// /// - error on user_id not existing
// /// - error on other SQL errors
// /// - ***salt*** password salt
// /// - ***hash*** resulting hash of the salt+password
// /// - ***user_id*** owner of the password
// pub(crate) async fn insert(db: &SqlitePool, salt: &str, hash: &str, user_id: i64)
//   -> errors::Result<i64>
// {
//   // Ensure the user exists
//   super::user::fetch_by_id(db, user_id).await?;

//   // Insert the new password
//   let result = sqlx::query(r#"INSERT INTO passwords (salt, hash, user_id) VALUES (?, ?, ?)"#)
//     .bind(salt).bind(hash).bind(user_id).execute(db).await;
//   match result {
//     Ok(query) => Ok(query.last_insert_rowid()),
//     Err(e) => {
//       let msg = format!("Error inserting password for user_id '{}'", user_id);
//       log::error!("{msg}");
//       return Err(errors::Error::from_sqlx(e, &msg));
//     }
//   }

//   // TODO: Now delete any passwords beyond the last 4
// }

// /// Get a password by ID from the database
// /// - error on not found
// /// - error on other SQL errors
// /// - ***id*** password id
// pub(crate) async fn fetch_by_id(db: &SqlitePool, id: i64) -> errors::Result<Password> {
//   let result = sqlx::query_as::<_, Password>(r#"SELECT * FROM passwords WHERE id = ?"#)
//     .bind(id).fetch_one(db).await;
//   match result {
//     Ok(password) => Ok(password),
//     Err(e) => {
//       if errors::Error::is_sqlx_not_found(&e) {
//         let msg = format!("Password with id '{id}' was not found");
//         log::warn!("{msg}");
//         return Err(errors::Error::from_sqlx(e, &msg));
//       } 
//       let msg = format!("Error fetching password with id '{id}'");
//       log::error!("{msg}");
//       return Err(errors::Error::from_sqlx(e, &msg));
//     }
//   }
// }

// /// Get all passwords from the database for the given user
// /// - TODO: orders the passwords by date
// /// - error on other SQL errors
// /// - ***user_id*** owner of the passwords
// pub(crate) async fn fetch_all(db: &SqlitePool, user_id: i64) -> errors::Result<Vec<Password>> {
//   let result = sqlx::query_as::<_, Password>(r#"SELECT * FROM passwords where user_id = ?"#)
//     .bind(user_id).fetch_all(db).await;
//   match result {
//     Ok(passwords) => Ok(passwords),
//     Err(e) => {
//       let msg = format!("Error fetching passwords");
//       log::error!("{msg}");
//       return Err(errors::Error::from_sqlx(e, &msg));
//     }
//   }
// }

// // Delete a password from the database
// // - not exposed to the API, only used internally
// // - error on other SQL errors
// async fn delete(db: &SqlitePool, id: i64) -> errors::Result<()> {
//   let result = sqlx::query(r#"DELETE from passwords WHERE id = ?"#).bind(id).execute(db).await;
//   if let Err(e) = result {
//     let msg = format!("Error deleting password with id '{id}'");
//     log::error!("{msg}");
//     return Err(errors::Error::from_sqlx(e, &msg));
//   }
//   Ok(())
// }

// #[cfg(test)]
// mod tests {
//   use super::*;
//   use crate::{model, state};
//   use axum::http::StatusCode;

//   // #[tokio::test]
//   // async fn test_delete_success() {
//   //   let state = state::test().await;
//   //   let password1 = 10;
//   //   let user1 = "user1";
//   //   let user_id = model::user::insert(state.db(), user1).await.unwrap();
//   //   let id = insert(state.db(), password1, user_id).await.unwrap();

//   //   delete(state.db(), id).await.unwrap();

//   //   let err = fetch_by_id(state.db(), id).await.unwrap_err();
//   //   assert_eq!(err.kind, errors::ErrorKind::NotFound);
//   // }

//   // #[tokio::test]
//   // async fn test_fetch_all_success() {
//   //   let state = state::test().await;
//   //   let password1 = 10;
//   //   let password2 = 20;
//   //   let user1 = "user1";
//   //   let user_id = model::user::insert(state.db(), user1).await.unwrap();

//   //   insert(state.db(), password1, user_id).await.unwrap();
//   //   insert(state.db(), password2, user_id).await.unwrap();
//   //   let passwords = fetch_all(state.db()).await.unwrap();
//   //   assert_eq!(passwords.len(), 2);
//   //   assert_eq!(passwords[0].value, password1);
//   //   assert_eq!(passwords[0].id, 1);
//   //   assert_eq!(passwords[0].user_id, user_id);
//   //   assert!(passwords[0].created_at <= chrono::Local::now());
//   //   assert!(passwords[0].updated_at <= chrono::Local::now());
//   //   assert_eq!(passwords[0].created_at, passwords[0].updated_at);
//   //   assert_eq!(passwords[1].value, password2);
//   //   assert_eq!(passwords[1].id, 2);
//   //   assert_eq!(passwords[1].user_id, user_id);
//   //   assert!(passwords[1].created_at <= chrono::Local::now());
//   //   assert!(passwords[1].updated_at <= chrono::Local::now());
//   //   assert_eq!(passwords[1].created_at, passwords[1].updated_at);
//   // }

//   // #[tokio::test]
//   // async fn test_fetch_by_id_failure_not_found() {
//   //   let state = state::test().await;

//   //   let err = fetch_by_id(state.db(), -1).await.unwrap_err().to_http();
//   //   assert_eq!(err.status, StatusCode::NOT_FOUND);
//   //   assert_eq!(err.msg, format!("Password with id '-1' was not found"));
//   // }

//   // #[tokio::test]
//   // async fn test_insert_success() {
//   //   let state = state::test().await;
//   //   let password1 = 10;
//   //   let user1 = "user1";
//   //   let user_id = model::user::insert(state.db(), user1).await.unwrap();

//   //   // Insert a new password
//   //   let id = insert(state.db(), password1, user_id).await.unwrap();
//   //   assert_eq!(id, 1);
//   //   let password = fetch_by_id(state.db(), id).await.unwrap();
//   //   assert_eq!(password.id, 1);
//   //   assert_eq!(password.value, password1);
//   //   assert_eq!(password.user_id, user_id);
//   //   assert!(password.created_at <= chrono::Local::now());
//   //   assert!(password.updated_at <= chrono::Local::now());
//   //   assert_eq!(password.created_at, password.updated_at);
//   // }

//   #[tokio::test]
//   async fn test_insert_failure_user_not_found() {
//     let state = state::test().await;
//     let salt1 = "salt1";
//     let hash1 = "hash1";
//     let user_id = -1;

//     let err = insert(state.db(), salt1, hash1, user_id).await.unwrap_err().to_http();
//     assert_eq!(err.status, StatusCode::NOT_FOUND);
//     assert_eq!(err.msg, format!("User with id '-1' was not found"));
//   }
// }