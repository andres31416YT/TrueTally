use api_gateway::{handlers, init_db, AuthRequest};
use std::sync::Arc;
use tokio::sync::Mutex;
use tower_http::cors::{Any, CorsLayer};
use axum::{Router, serve};

#[tokio::main]
async fn main() {
    env_logger::init();
    
    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://user:pass@localhost:5432/voting_db".to_string());
    
    let node_rpc_url = std::env::var("NODE_RPC_URL")
        .unwrap_or_else(|_| "http://blockchain-node:9944".to_string());
    
    let mut retries = 5;
    let db_pool = loop {
        match init_db(&database_url).await {
            Ok(pool) => {
                println!("Database connected successfully");
                break pool;
            }
            Err(e) if retries > 0 => {
                eprintln!("Failed to connect to database ({} retries left): {}", retries, e);
                retries -= 1;
                tokio::time::sleep(tokio::time::Duration::from_secs(2)).await;
            }
            Err(e) => {
                eprintln!("Failed to connect to database: {}", e);
                panic!("Database connection failed");
            }
        }
    };
    
    let state = Arc::new(Mutex::new(handlers::AppState {
        db_pool,
        http_client: reqwest::Client::new(),
        node_rpc_url,
    }));
    
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);
    
    let app = Router::new()
        .route("/health", axum::routing::get(handlers::health_check))
        .route("/auth", axum::routing::post(handlers::authenticate))
        .route("/elections", axum::routing::post(handlers::create_election))
        .route("/elections", axum::routing::get(handlers::list_elections))
        .route("/election", axum::routing::post(handlers::get_election))
        .route("/candidates", axum::routing::post(handlers::add_candidate))
        .route("/candidates", axum::routing::get(handlers::list_candidates))
        .route("/register", axum::routing::post(handlers::register_voter))
        .route("/voter", axum::routing::post(handlers::get_voter))
        .route("/vote", axum::routing::post(handlers::submit_vote))
        .route("/results", axum::routing::post(handlers::get_results))
        .route("/blocks", axum::routing::get(handlers::get_blocks))
        .layer(cors)
        .with_state(state);
    
    let addr = std::net::SocketAddr::from(([0, 0, 0, 0], 8080));
    
    println!("API Gateway running on http://{}", addr);
    
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    serve(listener, app)
        .await
        .expect("Failed to start server");
}
