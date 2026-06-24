pub mod models;
pub mod db;
pub mod handlers;
pub mod logging;

pub use models::*;
pub use db::*;
pub use logging::*;

pub fn generate_key_pair() -> (String, String) {
    use std::time::{SystemTime, UNIX_EPOCH};
    let timestamp = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_nanos();
    let public_key = format!("pk_{}", timestamp);
    let secret_key = format!("sk_{}", timestamp);
    (public_key, secret_key)
}