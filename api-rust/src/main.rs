use api_gateway::{handlers, init_db};
use std::sync::Arc;
use tokio::sync::Mutex;
use tower_http::cors::{Any, CorsLayer};
use axum::Router;

#[derive(Clone)]
struct AppState {
    db_pool: sqlx::PgPool,
    http_client: reqwest::Client,
    node_rpc_url: String,
}

#[tokio::main]
async fn main() {
    env_logger::init();
    
    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://user:pass@localhost:5432/voting_db".to_string());
    
    let node_rpc_url = std::env::var("NODE_RPC_URL")
        .unwrap_or_else(|_| "http://blockchain-node:9944".to_string());
    
    let db_pool = match init_db(&database_url).await {
        Ok(pool) => {
            println!("Database connected successfully");
            pool
        }
        Err(e) => {
            eprintln!("Failed to connect to database: {}", e);
            panic!("Database connection failed");
        }
    };
    
    let state = Arc::new(Mutex::new(AppState {
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
        .route("/register", axum::routing::post(handlers::register_voter))
        .route("/voter", axum::routing::post(handlers::get_voter))
        .route("/vote", axum::routing::post(handlers::submit_vote))
        .route("/results", axum::routing::get(handlers::get_results))
        .route("/blocks", axum::routing::get(handlers::get_blocks))
        .route("/candidates", axum::routing::get(handlers::list_candidates))
        .route("/candidates", axum::routing::post(handlers::add_candidate))
        .layer(cors)
        .with_state(state);
    
    let addr = std::net::SocketAddr::from(([0, 0, 0, 0], 8080));
    
    println!("API Gateway running on http://{}", addr);
    
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await
        .expect("Failed to start server");
}