use crate::models::{Candidate, NewCandidate, NewVoter, VoteRequest, VoteResponse};
use crate::db;
use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::sync::Mutex;
use sqlx::PgPool;

pub struct AppState {
    pub db_pool: PgPool,
    pub http_client: Client,
    pub node_rpc_url: String,
}

#[derive(Serialize)]
pub struct ApiResponse<T> {
    pub success: bool,
    pub data: Option<T>,
    pub error: Option<String>,
}

impl<T> ApiResponse<T> {
    pub fn ok(data: T) -> Self {
        Self {
            success: true,
            data: Some(data),
            error: None,
        }
    }

    pub fn err(msg: String) -> Self {
        Self {
            success: false,
            data: None,
            error: Some(msg),
        }
    }
}

pub async fn register_voter(
    State(state): State<Arc<Mutex<AppState>>>,
    Json(payload): Json<NewVoter>,
) -> Result<impl IntoResponse, (StatusCode, Json<ApiResponse<i64>>)> {
    let state = state.lock().await;
    
    match db::register_voter(&state.db_pool, &payload.public_key, &payload.name, &payload.email).await {
        Ok(id) => {
            let _ = db::log_audit(&state.db_pool, "voter_registered", &format!("public_key: {}", payload.public_key)).await;
            Ok((StatusCode::CREATED, Json(ApiResponse::ok(id))))
        }
        Err(e) => {
            if e.to_string().contains("unique") || e.to_string().contains("duplicate") {
                Err((StatusCode::CONFLICT, Json(ApiResponse::err("Voter already registered".to_string()))))
            } else {
                Err((StatusCode::INTERNAL_SERVER_ERROR, Json(ApiResponse::err(format!("Database error: {}", e)))))
            }
        }
    }
}

pub async fn get_voter(
    State(state): State<Arc<Mutex<AppState>>>,
    Json(payload): Json<serde_json::Value>,
) -> Result<impl IntoResponse, (StatusCode, Json<ApiResponse<serde_json::Value>>)> {
    let state = state.lock().await;
    let public_key = payload.get("public_key").and_then(|v| v.as_str()).unwrap_or("");
    
    match db::get_voter_by_public_key(&state.db_pool, public_key).await {
        Ok(Some((name, email, has_voted))) => {
            Ok((StatusCode::OK, Json(ApiResponse::ok(serde_json::json!({
                "name": name,
                "email": email,
                "has_voted": has_voted
            })))))
        }
        Ok(None) => Err((StatusCode::NOT_FOUND, Json(ApiResponse::err("Voter not found".to_string())))),
        Err(e) => Err((StatusCode::INTERNAL_SERVER_ERROR, Json(ApiResponse::err(format!("Database error: {}", e))))),
    }
}

pub async fn submit_vote(
    State(state): State<Arc<Mutex<AppState>>>,
    Json(payload): Json<VoteRequest>,
) -> Result<impl IntoResponse, (StatusCode, Json<ApiResponse<VoteResponse>>)> {
    let state = state.lock().await;
    
    if let Ok(Some((_, _, true))) = db::get_voter_by_public_key(&state.db_pool, &payload.voter_public_key).await {
        return Err((StatusCode::FORBIDDEN, Json(ApiResponse::err("This voter has already voted".to_string()))));
    }

    let rpc_url = format!("{}/vote", state.node_rpc_url);
    
    match state.http_client
        .post(&rpc_url)
        .json(&payload)
        .send()
        .await
    {
        Ok(response) => {
            if response.status().is_success() {
                let _ = db::mark_voter_voted(&state.db_pool, &payload.voter_public_key).await;
                let _ = db::log_audit(&state.db_pool, "vote_submitted", &format!("voter: {}", payload.voter_public_key)).await;
                
                Ok((StatusCode::OK, Json(ApiResponse::ok(VoteResponse {
                    success: true,
                    block_index: None,
                    block_hash: None,
                    message: Some("Vote submitted successfully".to_string()),
                }))))
            } else {
                let error_text = response.text().await.unwrap_or_default();
                Err((StatusCode::BAD_REQUEST, Json(ApiResponse::err(format!("Blockchain rejected vote: {}", error_text)))))
            }
        }
        Err(e) => Err((StatusCode::SERVICE_UNAVAILABLE, Json(ApiResponse::err(format!("Failed to connect to blockchain node: {}", e))))),
    }
}

pub async fn get_results(
    State(state): State<Arc<Mutex<AppState>>>,
) -> Result<impl IntoResponse, (StatusCode, Json<ApiResponse<serde_json::Value>>)> {
    let state = state.lock().await;
    
    let rpc_url = format!("{}/results", state.node_rpc_url);
    
    match state.http_client.get(&rpc_url).send().await {
        Ok(response) => {
            if response.status().is_success() {
                if let Ok(data) = response.json::<serde_json::Value>().await {
                    let results = data.get("data")
                        .cloned()
                        .unwrap_or(serde_json::Value::Object(Default::default()));
                    return Ok((StatusCode::OK, Json(ApiResponse::ok(results))));
                }
            }
            Err((StatusCode::INTERNAL_SERVER_ERROR, Json(ApiResponse::err("Failed to get results from blockchain".to_string()))))
        }
        Err(e) => Err((StatusCode::SERVICE_UNAVAILABLE, Json(ApiResponse::err(format!("Failed to connect to blockchain node: {}", e))))),
    }
}

pub async fn get_blocks(
    State(state): State<Arc<Mutex<AppState>>>,
) -> Result<impl IntoResponse, (StatusCode, Json<ApiResponse<serde_json::Value>>)> {
    let state = state.lock().await;
    
    let rpc_url = format!("{}/blocks", state.node_rpc_url);
    
    match state.http_client.get(&rpc_url).send().await {
        Ok(response) => {
            if response.status().is_success() {
                if let Ok(data) = response.json::<serde_json::Value>().await {
                    return Ok((StatusCode::OK, Json(ApiResponse::ok(data))));
                }
            }
            Err((StatusCode::INTERNAL_SERVER_ERROR, Json(ApiResponse::err("Failed to get blocks from blockchain".to_string()))))
        }
        Err(e) => Err((StatusCode::SERVICE_UNAVAILABLE, Json(ApiResponse::err(format!("Failed to connect to blockchain node: {}", e))))),
    }
}

pub async fn list_candidates(
    State(state): State<Arc<Mutex<AppState>>>,
) -> Result<impl IntoResponse, (StatusCode, Json<ApiResponse<Vec<serde_json::Value>>>)> {
    let state = state.lock().await;
    
    match db::list_candidates(&state.db_pool).await {
        Ok(candidates) => {
            let result: Vec<serde_json::Value> = candidates
                .into_iter()
                .map(|(id, name, party, bio)| {
                    serde_json::json!({
                        "id": id,
                        "name": name,
                        "party": party,
                        "bio": bio
                    })
                })
                .collect();
            Ok((StatusCode::OK, Json(ApiResponse::ok(result))))
        }
        Err(e) => Err((StatusCode::INTERNAL_SERVER_ERROR, Json(ApiResponse::err(format!("Database error: {}", e))))),
    }
}

pub async fn add_candidate(
    State(state): State<Arc<Mutex<AppState>>>,
    Json(payload): Json<NewCandidate>,
) -> Result<impl IntoResponse, (StatusCode, Json<ApiResponse<i32>>)> {
    let state = state.lock().await;
    
    match db::add_candidate(&state.db_pool, &payload.name, &payload.party, payload.bio.as_deref()).await {
        Ok(id) => Ok((StatusCode::CREATED, Json(ApiResponse::ok(id)))),
        Err(e) => Err((StatusCode::INTERNAL_SERVER_ERROR, Json(ApiResponse::err(format!("Database error: {}", e))))),
    }
}

pub async fn health_check() -> &'static str {
    "OK"
}

pub async fn seed_candidates_internal(state: &Arc<Mutex<AppState>>) -> Result<String, String> {
    use crate::db;
    
    let state_guard = state.lock().await;
    
    let candidates_exist = db::list_candidates(&state_guard.db_pool).await
        .map(|c| !c.is_empty())
        .unwrap_or(false);
    
    if candidates_exist {
        return Ok("Candidates already exist".to_string());
    }
    
    let default_candidates = vec![
        ("Candidate A", "Party Alpha", Some("Candidate A - Proponent of technology and innovation")),
        ("Candidate B", "Party Beta", Some("Candidate B - Champion of education reform")),
        ("Candidate C", "Party Gamma", Some("Candidate C - Advocate for environmental protection")),
    ];
    
    let mut seeded = 0;
    for (name, party, bio) in default_candidates {
        if db::add_candidate(&state_guard.db_pool, name, party, bio.as_deref()).await.is_ok() {
            seeded += 1;
        }
    }
    
    Ok(format!("Seeded {} candidates", seeded))
}

pub async fn seed_candidates(
    State(state): State<Arc<Mutex<AppState>>>,
) -> Result<impl IntoResponse, (StatusCode, Json<ApiResponse<String>>)> {
    match seed_candidates_internal(&state).await {
        Ok(msg) => Ok((StatusCode::OK, Json(ApiResponse::ok(msg)))),
        Err(e) => Err((StatusCode::INTERNAL_SERVER_ERROR, Json(ApiResponse::err(e)))),
    }
}