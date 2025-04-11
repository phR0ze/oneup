use sqlx::sqlite::{ SqlitePool, Sqlite };
use sqlx::migrate::{MigrateDatabase, Migrator};
use super::model::Config;
use anyhow::{ anyhow, Result, Context };

// Embed migrations from the `./migrations` directory into the app.
// - Relative to the project root i.e. where `Cargo.toml` is located.
static MIGRATOR: Migrator = sqlx::migrate!();

/// Application state
pub(crate) struct State {
  config: Config,
  db: SqlitePool,
}
impl State {

  /// Create a new state
  pub(crate) fn new(config: Config, db: SqlitePool) -> Self {
    Self { config, db }
  }

  /// Get the ip from the config
  pub(crate) fn ip(&self) -> String {
    self.config.ip.clone()
  }

  /// Get the port from the config
  pub(crate) fn port(&self) -> u16 {
    self.config.port
  }

  /// Get the log level
  pub(crate) fn log_level(&self) -> log::LevelFilter {
    self.config.log_level.clone()
  }

  /// Get a reference to the database connection pool
  pub(crate) fn db(&self) -> &SqlitePool {
    &self.db
  }
}

/// Load state
/// 
/// - Load configuration
/// - Connect to the database
#[fastrace::trace]
pub(crate) async fn load(config: Config) -> Result<State> {

  // Connect to the database
  let db = connect(&config.db_url).await?;

  // Run migrations automatically to ensure the database is up to date
  MIGRATOR.run(&db).await.with_context(|| "Error migrating database")?;
  log::info!("Database migrated successfully");

  // Return state
  Ok(State::new(config, db))
}

/// Connect to the given DB
/// 
/// - Creates a new SQLite database if needed
/// - Returns a connection pool
async fn connect(db_url: &str) -> Result<SqlitePool> {

  // Create the database if it doesn't exist
  if !Sqlite::database_exists(db_url).await
    .with_context(|| format!("checking if database exists: {}", db_url))? {

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