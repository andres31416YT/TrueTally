pub fn init_logging(_service_name: &str) {
    let _ = tracing_subscriber::fmt()
        .with_env_filter(std::env::var("RUST_LOG").unwrap_or_else(|_| "info".into()))
        .json()
        .init();
}
