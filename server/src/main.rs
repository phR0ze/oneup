mod errors;
mod db;
mod model;
mod routes;
mod state;
mod security;
mod utils;

const APP_NAME: &str = "OneUp";

// Keeping non-async for configuration and observability
fn main() -> anyhow::Result<()> 
{
  // Init configuration and observability
  let config = state::config::init()?;
  utils::observe::init(APP_NAME, &config);

  // Start the api server
  serve(config)?;

  Ok(())
}

/// Start the tokio runtime manually to allow for:
/// * Customizing the runtime (e.g., number of threads)
/// * Handling configuration and observability setup before starting the server
fn serve(config: model::Config) -> anyhow::Result<()> 
{
  tokio::runtime::Builder::new_multi_thread()
    //.worker_threads(config.runtime.worker_threads)
    //.thread_name(APP_NAME)
    //.thread_stack_size(3 * 1024 * 1024)
    .enable_all()
    .build()?

    // Initialize Axum inside the tokio runtime
    .block_on(async move 
    {
      let addr = format!("{}:{}", &config.ip, config.port);
      let state = state::init(config).await?;
      let router = routes::init(std::sync::Arc::new(state.clone()));
      log::info!("Server started at: {}", addr);

      // Set up graceful shutdown support by handling SIGINT (i.e. Ctrl+c) and SIGTERM signals
      let listener = tokio::net::TcpListener::bind(addr).await?;
      let (shutdown_tx, shutdown_rx) = tokio::sync::oneshot::channel();
      tokio::spawn(async move {
        let mut sigterm = tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate()).unwrap();
        tokio::select! {
          _ = tokio::signal::ctrl_c() => {
            log::info!("Received Ctrl-C signal, initiating graceful shutdown...");
          }
          _ = sigterm.recv() => {
            log::info!("Received SIGTERM signal, initiating graceful shutdown...");
          }
        }
        let _ = shutdown_tx.send(());
      });

      // Start the server with graceful shutdown
      let server = axum::serve(listener, router.into_make_service())
        .with_graceful_shutdown(async {
          shutdown_rx.await.ok();
          log::info!("Graceful shutdown initiated, waiting for connections to close...");
        });

      // Run the server
      if let Err(e) = server.await {
        log::error!("Server error: {}", e);
        return Err(anyhow::anyhow!("Server error: {}", e));
      }

      // Perform cleanup after server shutdown
      log::info!("Server stopped, performing cleanup...");

      // Close database connections to ensure WAL checkpoint
      if let Err(e) = state.close_db().await {
        log::error!("Error closing database: {}", e);
      }

      log::info!("Cleanup completed, shutting down gracefully.");
      Ok::<(), anyhow::Error>(())
    })?;

  Ok(())
}

// use std::env;

// fn main() {
//   // Handle help command
//   if env::args().len() == 1 || env::args().any(|x| x == "--help" || x == "-h") {
//     usage();
//     return;
//   }

//   // Handle other commands
//   if let Some(cmd) = std::env::args().nth(1) {
//     match cmd.as_str() {
//       "token" => {
//         log::info!("Generate a new api token...");
//       }
//       "run" => {
//         log::info!("Running the project...");
//         // Add run logic here
//       }
//       _ => {
//         usage();
//         return;
//       }
//     }
//   }
// }

// /// Command line usage
// fn usage() {
//   println!("Usage: ./oneup [command]");
//   println!("Commands:");
//   println!("  token   Generate a new api token");
//   println!("  run     Run the api server");
// } 