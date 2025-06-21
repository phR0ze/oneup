pub(crate) mod config;

use sqlx::sqlite::{ SqlitePool, Sqlite };
use sqlx::migrate::{MigrateDatabase, Migrator};
use anyhow::{ anyhow, Result, Context };

use crate::{db, model, security::auth};

// Embed migrations from the `./migrations` directory into the app.
// - Relative to the project root i.e. where `Cargo.toml` is located.
static MIGRATOR: Migrator = sqlx::migrate!();

/// Application state
#[derive(Clone)]
pub(crate) struct State {
  config: model::Config,
  db: SqlitePool,
}

impl State 
{
  /// Create a new state
  pub(crate) fn new(config: model::Config, db: SqlitePool) -> Self 
  {
    Self { config, db }
  }

  /// Get the ip from the config
  pub(crate) fn ip(&self) -> String 
  {
    self.config.ip.clone()
  }

  /// Get the port from the config
  pub(crate) fn port(&self) -> u16 
  {
    self.config.port
  }

  /// Get the log level
  pub(crate) fn log_level(&self) -> log::LevelFilter 
  {
    self.config.rust_log.clone()
  }

  /// Get a reference to the database connection pool
  pub(crate) fn db(&self) -> &SqlitePool 
  {
    &self.db
  }

  /// Close the database connection pool
  /// This ensures WAL checkpoint and proper cleanup
  pub(crate) async fn close_db(&self) -> Result<()>
  {
    log::info!("Closing database connection pool...");
    self.db.close().await;
    log::info!("Database connection pool closed successfully");
    Ok(())
  }
}

/// Initialize state
///  
/// - Load configuration
/// - Connect to the database
/// - Pre-populate database as needed for first run
pub(crate) async fn init(config: model::Config) -> Result<State> 
{
  // Connect to the database
  let db = connect(&config.database_url).await?;

  // Run migrations automatically to ensure the database is up to date
  MIGRATOR.run(&db).await.with_context(|| "Error migrating database")?;
  log::info!("Database migrated successfully");

  // Pre-populate database as needed for first run
  if !db::user::any(&db).await?  {
    let (admin, email, password) = ("admin", "admin@oneup.local", "admin");
    let admin_id = db::user::insert(&db, admin, email).await.unwrap();
    let creds = auth::hash_password(&password).unwrap();
    db::password::insert(&db, admin_id, &creds.salt, &creds.hash).await.unwrap();
    let role = db::role::fetch_by_name(&db, admin).await.unwrap();
    db::user::assign_roles(&db, admin_id, vec![role.id]).await.unwrap();
  }

  // Return state
  Ok(State::new(config, db))
}

/// Create a new instance that is useful for testing.
/// Sqlite in-memory databases are unique for each connection. This means it is safe
/// to call this function at the beginning of each test and each in memory db instance
/// will be unique and isolated i.e. no concurrency issues.
#[cfg(test)]
pub(crate) async fn test() -> std::sync::Arc::<State> 
{
  let config = model::Config::test();
  let state = init(config).await.unwrap();
  std::sync::Arc::new(state)
}

/// Connect to the given DB
/// 
/// - Creates a new SQLite database if needed
/// - Returns a connection pool
async fn connect(db_url: &str) -> Result<SqlitePool> 
{
  // Create the database if it doesn't exist
  if !Sqlite::database_exists(db_url).await
    .with_context(|| format!("checking if database exists: {}", db_url))? 
  {
    log::info!("Creating database at {}", db_url);
    Sqlite::create_database(db_url).await
      .with_context(|| format!("creating database: {}", db_url))?;
  }

  // Open the database connection
  match SqlitePool::connect(db_url).await {
    Ok(pool) => {
      log::info!("Database connection pool created successfully");
      return Ok(pool);
    },
    Err(e) => Err(anyhow!("initial database connection: {}", e)),
  }
}

#[cfg(test)]
mod tests 
{
  use super::*;

  #[tokio::test]
  async fn test_load() 
  {
    let config = model::Config::test();
    let state = init(config).await.expect("can't load state");

    // Validate we can connect and get back admin user
    let result = sqlx::query_scalar::<_, i32>(
      r#"SELECT COUNT(*) FROM user"#).fetch_one(state.db())
      .await.expect("can't query users");
    assert_eq!(result, 1);
  }

  #[tokio::test]
  async fn test_connect() 
  {
    connect("sqlite::memory:").await.expect("can't connect to db");
  }
}