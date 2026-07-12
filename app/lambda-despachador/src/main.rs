use aws_sdk_sqs::Client as SqsClient;
use lambda_runtime::{service_fn, Error, LambdaEvent};
use serde_json::json;
use shared::logging;
use shared::VoteRequest;
use std::sync::Arc;
use tracing::{error, info};

#[derive(serde::Serialize)]
struct ApiGatewayResponse {
    #[serde(rename = "statusCode")]
    status_code: i32,
    #[serde(rename = "headers")]
    headers: std::collections::HashMap<String, String>,
    body: String,
    #[serde(rename = "isBase64Encoded")]
    is_base64_encoded: bool,
}

fn success_response(msg: &str) -> ApiGatewayResponse {
    ApiGatewayResponse {
        status_code: 202,
        headers: {
            let mut h = std::collections::HashMap::new();
            h.insert("Content-Type".to_string(), "application/json".to_string());
            h
        },
        body: serde_json::to_string(&json!({
            "success": true,
            "data": msg
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
    logging::init_logging("lambda-despachador");

    let config = aws_config::load_defaults(aws_config::BehaviorVersion::latest()).await;
    let sqs_client = SqsClient::new(&config);

    let vote_queue_url =
        std::env::var("VOTE_QUEUE_URL").expect("VOTE_QUEUE_URL environment variable is not set");

    let shared_state = Arc::new(SharedState {
        sqs_client,
        vote_queue_url,
    });

    lambda_runtime::run(service_fn(move |event| {
        let state = shared_state.clone();
        async move { handle_request(event, state).await }
    }))
    .await?;

    Ok(())
}

struct SharedState {
    sqs_client: SqsClient,
    vote_queue_url: String,
}

async fn handle_request(
    event: LambdaEvent<serde_json::Value>,
    state: Arc<SharedState>,
) -> Result<ApiGatewayResponse, Error> {
    let path = event
        .payload
        .get("path")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    let method = event
        .payload
        .get("httpMethod")
        .and_then(|v| v.as_str())
        .unwrap_or("GET");

    if method != "POST" || path != "/vote" {
        return Ok(error_response(404, "Not found"));
    }

    let body = event
        .payload
        .get("body")
        .and_then(|v| v.as_str())
        .unwrap_or("{}");
    let payload: VoteRequest = serde_json::from_str(body).map_err(|e| {
        error!(
            service = "lambda-despachador",
            event = "json_parse_error",
            error = %e,
            "Failed to parse vote request"
        );
        format!("Invalid JSON: {}", e)
    })?;

    let message_body = serde_json::to_string(&payload).map_err(|e| {
        error!(
            service = "lambda-despachador",
            event = "serialization_error",
            error = %e,
            "Failed to serialize vote"
        );
        format!("Serialization error: {}", e)
    })?;

    state
        .sqs_client
        .send_message()
        .queue_url(&state.vote_queue_url)
        .message_body(message_body)
        .send()
        .await
        .map_err(|e| {
            error!(
                service = "lambda-despachador",
                event = "sqs_send_error",
                error = %e,
                "Failed to send message to SQS"
            );
            format!("Failed to send message to SQS: {}", e)
        })?;

    info!(
        service = "lambda-despachador",
        event = "vote_queued",
        "Vote successfully queued for processing"
    );

    Ok(success_response("Vote queued for processing"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_success_response_structure() {
        let response = success_response("queued");

        assert_eq!(response.status_code, 202);
        assert_eq!(response.is_base64_encoded, false);
        assert!(response.headers.contains_key("Content-Type"));
        assert_eq!(
            response.headers.get("Content-Type").unwrap(),
            "application/json"
        );

        let body: serde_json::Value =
            serde_json::from_str(&response.body).expect("Body should be valid JSON");
        assert_eq!(body.get("success").unwrap(), &true);
        assert_eq!(body.get("data").unwrap(), "queued");
    }

    #[test]
    fn test_error_response_structure() {
        let response = error_response(404, "Not found");

        assert_eq!(response.status_code, 404);
        assert_eq!(response.is_base64_encoded, false);
        assert!(response.headers.contains_key("Content-Type"));
        assert_eq!(
            response.headers.get("Content-Type").unwrap(),
            "application/json"
        );

        let body: serde_json::Value =
            serde_json::from_str(&response.body).expect("Body should be valid JSON");
        assert_eq!(body.get("success").unwrap(), &false);
        assert_eq!(body.get("error").unwrap(), "Not found");
    }

    #[test]
    fn test_vote_request_deserialization() {
        let json = r#"{
            "voter_public_key": "pk_123",
            "candidate_id": "cand_1",
            "election_id": "elec_1",
            "signature": "sig_abc",
            "is_blank_vote": false
        }"#;

        let req: VoteRequest = serde_json::from_str(json).unwrap();
        assert_eq!(req.voter_public_key, "pk_123");
        assert_eq!(req.candidate_id, "cand_1");
        assert_eq!(req.election_id, "elec_1");
        assert_eq!(req.signature, "sig_abc");
        assert!(!req.is_blank_vote);
    }
}
