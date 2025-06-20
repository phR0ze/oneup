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
      let router = routes::init(std::sync::Arc::new(state));
      log::info!("Server started at: {}", addr);

      let listener = tokio::net::TcpListener::bind(addr).await?;
      axum::serve(listener, router.into_make_service()).await?;

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