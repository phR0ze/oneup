/*!
 * Error handling for the application
 */
mod error;
mod http;
pub use http::*;
pub use error::*;

/// Simplify the return type slightly
pub type Result<T, E = Error> = core::result::Result<T, E>;