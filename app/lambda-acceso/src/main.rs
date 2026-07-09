use lambda_runtime::{service_fn, Error, LambdaEvent};
use reqwest::Client;
use serde_json::json;
use std::sync::Arc;
use tracing::error;

#[derive(serde::Serialize)]
struct ApiGatewayResponse {
    #[serde(rename = "statusCode")]
    status_code: i32,
    headers: std::collections::HashMap<String, String>,
    body: String,
    #[serde(rename = "isBase64Encoded")]
    is_base64_encoded: bool,
}

fn success_response<T: serde::Serialize>(data: T) -> ApiGatewayResponse {
    ApiGatewayResponse {
        status_code: 200,
        headers: {
            let mut h = std::collections::HashMap::new();
            h.insert("Content-Type".to_string(), "application/json".to_string());
            h.insert("Access-Control-Allow-Origin".to_string(), "*".to_string());
            h.insert(
                "Access-Control-Allow-Methods".to_string(),
                "GET,POST,OPTIONS".to_string(),
            );
            h.insert(
                "Access-Control-Allow-Headers".to_string(),
                "Content-Type,X-User-Email,X-User-Role".to_string(),
            );
            h
        },
        body: serde_json::to_string(&json!({
            "success": true,
            "data": data
        }))
        .unwrap_or_default(),
        is_base64_encoded: false,
    }
}

fn error_response(status: i32, msg: &str) -> ApiGatewayResponse {
    ApiGatewayResponse {
        status_code: status,
        headers: {
            let mut h = std::collections::HashMap::new();
            h.insert("Content-Type".to_string(), "application/json".to_string());
            h.insert("Access-Control-Allow-Origin".to_string(), "*".to_string());
            h.insert(
                "Access-Control-Allow-Methods".to_string(),
                "GET,POST,OPTIONS".to_string(),
            );
            h.insert(
                "Access-Control-Allow-Headers".to_string(),
                "Content-Type,X-User-Email,X-User-Role".to_string(),
            );
            h
        },
        body: serde_json::to_string(&json!({
            "success": false,
            "error": msg
        }))
        .unwrap_or_default(),
        is_base64_encoded: false,
    }
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    shared::logging::init_logging("lambda-acceso");

    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://user:pass@localhost:5432/voting_db".to_string());

    let mut retries = 5;
    let db_pool = loop {
        match shared::init_db(&database_url).await {
            Ok(pool) => break pool,
            Err(e) if retries > 0 => {
                error!(
                    service = "lambda-acceso",
                    event = "db_connection_retry",
                    retries_left = retries,
                    error = %e,
                    "Failed to connect to database"
                );
                retries -= 1;
                tokio::time::sleep(tokio::time::Duration::from_secs(2)).await;
            }
            Err(e) => {
                error!(
                    service = "lambda-acceso",
                    event = "db_connection_failed",
                    error = %e,
                    "Database connection failed"
                );
                panic!("Database connection failed: {}", e);
            }
        }
    };

    let blockchain_node_url = std::env::var("BLOCKCHAIN_NODE_URL")
        .unwrap_or_else(|_| "http://localhost:9944".to_string());

    let shared_state = Arc::new(SharedState {
        db_pool,
        blockchain_node_url,
        http_client: Client::new(),
    });

    lambda_runtime::run(service_fn(move |event| {
        let state = shared_state.clone();
        async move { handle_request(event, state).await }
    }))
    .await?;

    Ok(())
}

struct SharedState {
    db_pool: sqlx::PgPool,
    blockchain_node_url: String,
    http_client: Client,
}

async fn handle_request(
    event: LambdaEvent<serde_json::Value>,
    state: Arc<SharedState>,
) -> Result<ApiGatewayResponse, Error> {
    let path = event
        .payload
        .get("rawPath")
        .and_then(|v| v.as_str())
        .or_else(|| event.payload.get("path").and_then(|v| v.as_str()))
        .unwrap_or("");
    let method = event
        .payload
        .get("requestContext")
        .and_then(|c| c.get("http"))
        .and_then(|h| h.get("method"))
        .and_then(|v| v.as_str())
        .or_else(|| event.payload.get("httpMethod").and_then(|v| v.as_str()))
        .unwrap_or("GET");
    let body = event
        .payload
        .get("body")
        .and_then(|v| v.as_str())
        .unwrap_or("{}");

    match (method, path) {
        ("GET", "/health") => Ok(success_response("OK")),

        // Auth & Users
        ("POST", "/auth") => {
            let payload: shared::AuthRequest = serde_json::from_str(body)?;
            Ok(authenticate(&state.db_pool, &payload).await)
        }
        ("POST", "/register-user") => {
            let payload: shared::AuthRequest = serde_json::from_str(body)?;
            Ok(register(&state.db_pool, &payload).await)
        }
        ("POST", "/update-role") => {
            let payload: shared::RoleUpdateRequest = serde_json::from_str(body)?;
            Ok(update_role(&state.db_pool, &payload).await)
        }
        ("POST", "/users") => {
            let payload: shared::ListUsersRequest = serde_json::from_str(body)?;
            Ok(list_users_handler(&state.db_pool, &payload).await)
        }

        // Elections
        ("POST", "/elections") => {
            let payload: shared::NewElection = serde_json::from_str(body)?;
            Ok(create_election_handler(&state.db_pool, &payload).await)
        }
        ("GET", "/elections") => match shared::list_elections(&state.db_pool).await {
            Ok(elections) => {
                let result: Vec<_> = elections.into_iter().map(|(id, name, description, status, visibility, password)| {
                        json!({"id": id, "name": name, "description": description, "status": status, "visibility": visibility, "password": password.unwrap_or_default()})
                    }).collect();
                Ok(success_response(json!({ "elections": result })))
            }
            Err(e) => Ok(error_response(500, &format!("Database error: {}", e))),
        },
        ("GET", "/elections/all") => match shared::list_all_elections(&state.db_pool).await {
            Ok(elections) => {
                let result: Vec<_> = elections.into_iter().map(|(id, name, description, status, visibility, password)| {
                        json!({"id": id, "name": name, "description": description, "status": status, "visibility": visibility, "password": password.unwrap_or_default()})
                    }).collect();
                Ok(success_response(json!({ "elections": result })))
            }
            Err(e) => Ok(error_response(500, &format!("Database error: {}", e))),
        },
        ("POST", "/election") => {
            let payload: serde_json::Value = serde_json::from_str(body)?;
            let election_id = payload
                .get("election_id")
                .and_then(|v| v.as_str())
                .unwrap_or("");
            Ok(get_election_handler(&state.db_pool, election_id).await)
        }
        ("POST", "/update-election") => {
            let payload: shared::UpdateElectionRequest = serde_json::from_str(body)?;
            Ok(update_election_handler(&state.db_pool, &payload).await)
        }
        ("POST", "/delete-election") => {
            let payload: shared::DeleteElectionRequest = serde_json::from_str(body)?;
            Ok(delete_election_handler(&state.db_pool, &payload).await)
        }
        ("POST", "/my-elections") => {
            let payload: shared::MyElectionsRequest = serde_json::from_str(body)?;
            match shared::list_elections_by_creator(
                &state.db_pool,
                &payload.user_email,
                payload.search.as_deref(),
            )
            .await
            {
                Ok(elections) => {
                    let result: Vec<_> = elections.into_iter().map(|(id, name, description, status, visibility, password)| {
                        json!({"id": id, "name": name, "description": description, "status": status, "visibility": visibility, "password": password.unwrap_or_default()})
                    }).collect();
                    Ok(success_response(json!({ "elections": result })))
                }
                Err(e) => Ok(error_response(500, &format!("Database error: {}", e))),
            }
        }

        // Candidates
        ("POST", "/candidates") => {
            let payload: shared::NewCandidate = serde_json::from_str(body)?;
            Ok(add_candidate_handler(&state.db_pool, &payload).await)
        }
        ("GET", "/candidates") => {
            let election_id = event
                .payload
                .get("queryStringParameters")
                .and_then(|q| q.get("election_id").and_then(|v| v.as_str()))
                .unwrap_or("");
            match shared::list_candidates(&state.db_pool, election_id).await {
                Ok(candidates) => {
                    let result: Vec<_> = candidates
                        .into_iter()
                        .map(|(id, code, name)| json!({"id": id, "code": code, "name": name}))
                        .collect();
                    Ok(success_response(json!({ "candidates": result })))
                }
                Err(e) => Ok(error_response(500, &format!("Database error: {}", e))),
            }
        }
        ("POST", "/candidates/update") => {
            let payload: serde_json::Value = serde_json::from_str(body)?;
            let candidate_id = payload
                .get("candidate_id")
                .and_then(|v| v.as_i64())
                .unwrap_or(0) as i64;
            let name = payload.get("name").and_then(|v| v.as_str()).unwrap_or("");
            Ok(update_candidate_handler(&state.db_pool, candidate_id, name).await)
        }
        ("POST", "/candidates/delete") => {
            let payload: serde_json::Value = serde_json::from_str(body)?;
            let candidate_id = payload
                .get("candidate_id")
                .and_then(|v| v.as_i64())
                .unwrap_or(0) as i64;
            Ok(delete_candidate_handler(&state.db_pool, candidate_id).await)
        }

        // Voters
        ("POST", "/register") => {
            let payload: shared::RegistrationRequest = serde_json::from_str(body)?;
            Ok(register_voter_handler(&state.db_pool, &payload).await)
        }
        ("POST", "/voter") => {
            let payload: serde_json::Value = serde_json::from_str(body)?;
            let election_id = payload
                .get("election_id")
                .and_then(|v| v.as_str())
                .unwrap_or("");
            let public_key = payload
                .get("public_key")
                .and_then(|v| v.as_str())
                .unwrap_or("");
            Ok(get_voter_handler(&state.db_pool, election_id, public_key).await)
        }

        // Blockchain proxy
        ("GET", "/blocks") => Ok(proxy_to_blockchain(&state).await),
        ("POST", "/results") => Ok(proxy_results_to_blockchain(&state, body).await),

        _ => Ok(error_response(404, "Not found")),
    }
}

// Auth handlers
async fn authenticate(pool: &sqlx::PgPool, payload: &shared::AuthRequest) -> ApiGatewayResponse {
    if payload.email.is_empty() {
        return error_response(400, "El correo electrónico es requerido");
    }

    match shared::authenticate_user(pool, &payload.email, payload.password.as_deref()).await {
        Ok(Some((role, public_key, has_password))) => {
            match shared::check_user_voted(pool, &payload.email).await {
                Ok(has_voted) => success_response(json!({
                    "role": role,
                    "public_key": public_key,
                    "has_password": has_password,
                    "has_voted_election": has_voted
                })),
                Err(_) => success_response(json!({
                    "role": role,
                    "public_key": public_key,
                    "has_password": has_password,
                    "has_voted_election": serde_json::Value::Null
                })),
            }
        }
        Ok(None) => error_response(
            401,
            "Correo o contraseña incorrectos. Por favor, verifica tus datos.",
        ),
        Err(e) => error_response(500, &format!("Error de base de datos: {}", e)),
    }
}

async fn register(pool: &sqlx::PgPool, payload: &shared::AuthRequest) -> ApiGatewayResponse {
    if payload.email.is_empty() || payload.password.is_none() {
        return error_response(400, "Email y contraseña son requeridos");
    }

    let password = payload.password.as_ref().unwrap();
    if password.len() < 6 {
        return error_response(400, "La contraseña debe tener al menos 6 caracteres");
    }

    if let Ok(Some(_)) = shared::authenticate_user(pool, &payload.email, None).await {
        return error_response(409, "Este correo ya está registrado");
    }

    let keys = shared::generate_key_pair();
    match shared::create_user(pool, &payload.email, Some(&keys.0), Some(password), "user").await {
        Ok(_) => success_response(
            json!({"role": "user", "public_key": keys.0, "has_password": true, "has_voted_election": serde_json::Value::Null}),
        ),
        Err(e) => error_response(500, &format!("Error al crear usuario: {}", e)),
    }
}

async fn update_role(
    pool: &sqlx::PgPool,
    payload: &shared::RoleUpdateRequest,
) -> ApiGatewayResponse {
    let is_sudo = payload.admin_email == "admin@truetally.com";

    if !is_sudo {
        match shared::authenticate_user(pool, &payload.admin_email, None).await {
            Ok(Some((role, _, _))) => {
                if role != "sudo_admin" {
                    return error_response(403, "Solo sudo_admin puede cambiar roles");
                }
            }
            _ => return error_response(401, "Usuario no autorizado"),
        }
    }

    match shared::update_user_role(pool, &payload.target_email, &payload.new_role).await {
        Ok(_) => {
            let _ = shared::log_audit(
                pool,
                "role_updated",
                &format!(
                    "user: {} new_role: {}",
                    payload.target_email, payload.new_role
                ),
            )
            .await;
            success_response("Rol actualizado")
        }
        Err(e) => error_response(500, &format!("Error: {}", e)),
    }
}

async fn list_users_handler(
    pool: &sqlx::PgPool,
    payload: &shared::ListUsersRequest,
) -> ApiGatewayResponse {
    let is_sudo = payload.admin_email == "admin@truetally.com";

    if !is_sudo {
        match shared::authenticate_user(pool, &payload.admin_email, None).await {
            Ok(Some((role, _, _))) => {
                if role != "sudo_admin" && role != "admin" {
                    return error_response(403, "No autorizado");
                }
            }
            _ => return error_response(401, "Usuario no autorizado"),
        }
    }

    match shared::list_users(pool).await {
        Ok(users) => success_response(json!(users
            .into_iter()
            .map(|(email, role)| json!({"email": email, "role": role}))
            .collect::<Vec<_>>())),
        Err(e) => error_response(500, &format!("Error: {}", e)),
    }
}

// Election handlers
async fn create_election_handler(
    pool: &sqlx::PgPool,
    payload: &shared::NewElection,
) -> ApiGatewayResponse {
    let election_id = uuid::Uuid::new_v4().to_string()[..8].to_string();

    match shared::create_election(
        pool,
        &election_id,
        &payload.name,
        payload.description.as_deref(),
        &payload.visibility,
        &payload.status,
        None,
        payload.created_by.as_deref(),
    )
    .await
    {
        Ok(_) => {
            let _ = shared::log_audit(
                pool,
                "election_created",
                &format!("election: {}", election_id),
            )
            .await;
            success_response(election_id)
        }
        Err(e) => error_response(500, &format!("Database error: {}", e)),
    }
}

async fn get_election_handler(pool: &sqlx::PgPool, election_id: &str) -> ApiGatewayResponse {
    match shared::get_election(pool, election_id).await {
        Ok(Some((id, name, description, is_active))) => success_response(
            json!({"id": id, "name": name, "description": description, "is_active": is_active}),
        ),
        Ok(None) => error_response(404, "Election not found"),
        Err(e) => error_response(500, &format!("Database error: {}", e)),
    }
}

async fn update_election_handler(
    pool: &sqlx::PgPool,
    payload: &shared::UpdateElectionRequest,
) -> ApiGatewayResponse {
    match shared::get_election_creator(pool, &payload.election_id).await {
        Ok(Some(creator)) => {
            if creator != payload.user_email {
                return error_response(403, "Solo el creator puede modificar");
            }
        }
        Ok(None) => return error_response(404, "Elección no encontrada"),
        Err(e) => return error_response(500, &format!("Error: {}", e)),
    }

    match shared::update_election(
        pool,
        &payload.election_id,
        payload.name.as_deref(),
        payload.description.as_deref(),
        Some(&payload.visibility),
        Some(&payload.status),
        payload.password.as_deref(),
    )
    .await
    {
        Ok(_) => {
            let _ = shared::log_audit(
                pool,
                "election_updated",
                &format!("election: {}", payload.election_id),
            )
            .await;
            success_response("Elección actualizada")
        }
        Err(e) => error_response(500, &format!("Error: {}", e)),
    }
}

async fn delete_election_handler(
    pool: &sqlx::PgPool,
    payload: &shared::DeleteElectionRequest,
) -> ApiGatewayResponse {
    match shared::get_election_by_status(pool, &payload.election_id).await {
        Ok(Some(s)) => {
            if s == "Terminado" {
                return error_response(403, "No se puede eliminar una elección terminada");
            }
            if s == "Publicado" {
                return error_response(403, "No se puede eliminar una elección publicada");
            }
        }
        Ok(None) => return error_response(404, "Elección no encontrada"),
        Err(e) => return error_response(500, &format!("Error: {}", e)),
    }

    match shared::hard_delete_election(pool, &payload.election_id).await {
        Ok(_) => {
            let _ = shared::log_audit(
                pool,
                "election_deleted",
                &format!("election: {} (hard delete)", payload.election_id),
            )
            .await;
            success_response("Elección eliminada permanentemente")
        }
        Err(e) => error_response(500, &format!("Database error: {}", e)),
    }
}

// Candidate handlers
async fn add_candidate_handler(
    pool: &sqlx::PgPool,
    payload: &shared::NewCandidate,
) -> ApiGatewayResponse {
    if payload.name.trim().is_empty() {
        return error_response(400, "Name cannot be empty");
    }

    let uuid_part = &uuid::Uuid::new_v4().to_string()[..3].to_uppercase();
    let code = format!(
        "C{}A{}",
        &payload.election_id[..std::cmp::min(3, payload.election_id.len())].to_uppercase(),
        uuid_part
    );

    if let Ok(true) = shared::candidate_exists(pool, &payload.election_id, &payload.name).await {
        return error_response(
            409,
            "A candidate with this name already exists in this election",
        );
    }

    match shared::add_candidate(pool, &payload.election_id, &code, &payload.name).await {
        Ok(id) => {
            let _ = shared::log_audit(
                pool,
                "candidate_added",
                &format!("election: {}", payload.election_id),
            )
            .await;
            success_response(id)
        }
        Err(e) => error_response(500, &format!("Database error: {}", e)),
    }
}

async fn update_candidate_handler(
    pool: &sqlx::PgPool,
    candidate_id: i64,
    name: &str,
) -> ApiGatewayResponse {
    if candidate_id == 0 || name.trim().is_empty() {
        return error_response(400, "Candidate ID and name are required");
    }

    match shared::update_candidate(pool, candidate_id, name).await {
        Ok(_) => {
            let _ = shared::log_audit(
                pool,
                "candidate_updated",
                &format!("candidate: {}", candidate_id),
            )
            .await;
            success_response("Candidato actualizado")
        }
        Err(e) => error_response(500, &format!("Database error: {}", e)),
    }
}

async fn delete_candidate_handler(pool: &sqlx::PgPool, candidate_id: i64) -> ApiGatewayResponse {
    if candidate_id == 0 {
        return error_response(400, "Candidate ID is required");
    }

    match shared::delete_candidate(pool, candidate_id).await {
        Ok(_) => {
            let _ = shared::log_audit(
                pool,
                "candidate_deleted",
                &format!("candidate: {}", candidate_id),
            )
            .await;
            success_response("Candidato eliminado")
        }
        Err(e) => error_response(500, &format!("Database error: {}", e)),
    }
}

// Voter handlers
async fn register_voter_handler(
    pool: &sqlx::PgPool,
    payload: &shared::RegistrationRequest,
) -> ApiGatewayResponse {
    if payload.email.trim().is_empty() {
        return error_response(400, "Email is required");
    }

    match shared::check_voter_by_email(pool, &payload.election_id, &payload.email).await {
        Ok(Some((_, true))) => {
            return error_response(409, "Este email ya ha emitido un voto en esta elección");
        }
        Ok(Some((_, false))) => {}
        Ok(None) => {}
        Err(_) => {}
    }

    match shared::register_voter(
        pool,
        &payload.election_id,
        &payload.email,
        &payload.public_key,
    )
    .await
    {
        Ok(id) => {
            let _ = shared::log_audit(
                pool,
                "voter_registered",
                &format!(
                    "election: {} email: {} public_key: {}",
                    payload.election_id, payload.email, payload.public_key
                ),
            )
            .await;
            success_response(id)
        }
        Err(e) => error_response(500, &format!("Database error: {}", e)),
    }
}

async fn get_voter_handler(
    pool: &sqlx::PgPool,
    election_id: &str,
    public_key: &str,
) -> ApiGatewayResponse {
    match shared::get_voter_by_public_key(pool, election_id, public_key).await {
        Ok(Some((name, has_voted))) => {
            success_response(json!({"name": name, "has_voted": has_voted}))
        }
        Ok(None) => error_response(404, "Voter not found"),
        Err(e) => error_response(500, &format!("Database error: {}", e)),
    }
}

async fn proxy_to_blockchain(state: &Arc<SharedState>) -> ApiGatewayResponse {
    let url = format!("{}/blocks", state.blockchain_node_url);

    match state
        .http_client
        .get(&url)
        .timeout(std::time::Duration::from_secs(3))
        .send()
        .await
    {
        Ok(resp) => {
            let status = resp.status().as_u16() as i32;
            match resp.text().await {
                Ok(body) => {
                    let mut headers = std::collections::HashMap::new();
                    headers.insert("Content-Type".to_string(), "application/json".to_string());
                    ApiGatewayResponse {
                        status_code: status,
                        headers,
                        body,
                        is_base64_encoded: false,
                    }
                }
                Err(e) => error_response(502, &format!("Error reading blockchain response: {}", e)),
            }
        }
        Err(e) => error_response(502, &format!("Error connecting to blockchain: {}", e)),
    }
}

async fn proxy_results_to_blockchain(state: &Arc<SharedState>, body: &str) -> ApiGatewayResponse {
    let election_id = serde_json::from_str::<serde_json::Value>(body)
        .ok()
        .and_then(|v| {
            v.get("election_id")
                .and_then(|e| e.as_str())
                .map(|s| s.to_string())
        })
        .unwrap_or_default();

    let url = format!("{}/results/{}", state.blockchain_node_url, election_id);

    match state
        .http_client
        .get(&url)
        .timeout(std::time::Duration::from_secs(5))
        .send()
        .await
    {
        Ok(resp) => {
            let status = resp.status().as_u16() as i32;
            match resp.text().await {
                Ok(body) => {
                    let mut headers = std::collections::HashMap::new();
                    headers.insert("Content-Type".to_string(), "application/json".to_string());
                    ApiGatewayResponse {
                        status_code: status,
                        headers,
                        body,
                        is_base64_encoded: false,
                    }
                }
                Err(e) => error_response(502, &format!("Error reading blockchain response: {}", e)),
            }
        }
        Err(e) => error_response(502, &format!("Error connecting to blockchain: {}", e)),
    }
}
