pub mod db;
pub mod handlers;
pub mod logging;
pub mod models;

pub use db::*;
pub use logging::*;
pub use models::*;

pub fn generate_key_pair() -> (String, String) {
    use std::time::{SystemTime, UNIX_EPOCH};
    let timestamp = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_nanos();
    let public_key = format!("pk_{}", timestamp);
    let secret_key = format!("sk_{}", timestamp);
    (public_key, secret_key)
}

#[cfg(test)]
mod tests {
    #[test]
    fn test_generate_key_pair_returns_valid_keys() {
        let (public_key, secret_key) = crate::generate_key_pair();

        assert!(public_key.starts_with("pk_"));
        assert!(secret_key.starts_with("sk_"));
        assert!(!public_key.is_empty());
        assert!(!secret_key.is_empty());
    }

    #[test]
    fn test_generate_key_pair_unique() {
        let (pk1, sk1) = crate::generate_key_pair();
        let (pk2, sk2) = crate::generate_key_pair();

        assert_ne!(pk1, pk2);
        assert_ne!(sk1, sk2);
    }
}
