mod model;
mod routes;
mod state;
mod utils;

const APP_NAME: &str = "oneup";

fn main() -> anyhow::Result<()> {

  // Init configuration and observability
  let config = utils::load_config()?;
  utils::observe(APP_NAME, &config);

  // Init api server
  serve(config)?;
  Ok(())
}

// Headers Accept-Version, Content-Version

/// Start the tokio runtime
fn serve(config: model::Config) -> anyhow::Result<()> {
  tokio::runtime::Builder::new_multi_thread()
    .enable_all().build()?

    // Initialize Axum inside the tokio runtime
    .block_on(async move
    {
      let addr = format!("{}:{}", &config.ip, config.port);
      let state = state::load(config).await?;
      let router = routes::init(state);
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