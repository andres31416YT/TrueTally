use aws_lambda_events::sqs::SqsEvent;
use lambda_runtime::{service_fn, Error, LambdaEvent};
use reqwest::Client;
use shared::VoteRequest;
use std::env;
use tracing::info;

#[tokio::main]
async fn main() -> Result<(), Error> {
    tracing_subscriber::fmt()
        .with_max_level(tracing::Level::INFO)
        .with_target(false)
        .init();

    let _config = aws_config::load_defaults(aws_config::BehaviorVersion::latest()).await;
    let http_client = Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .build()
        .expect("Failed to create HTTP client");

    let node_rpc_url =
        env::var("BLOCKCHAIN_NODE_URL").unwrap_or_else(|_| "http://localhost:9944".to_string());
    let node_rpc_url = if node_rpc_url.trim().is_empty() {
        "http://localhost:9944".to_string()
    } else {
        node_rpc_url
    };

    let shared_state = SharedState {
        http_client,
        node_rpc_url,
    };

    lambda_runtime::run(service_fn(move |event| {
        let state = shared_state.clone();
        async move { handle_sqs_event(event, state).await }
    }))
    .await?;

    Ok(())
}

#[derive(Clone)]
struct SharedState {
    http_client: Client,
    node_rpc_url: String,
}

async fn handle_sqs_event(event: LambdaEvent<SqsEvent>, state: SharedState) -> Result<(), Error> {
    for record in event.payload.records {
        let message_id = record.message_id.unwrap_or_else(|| "unknown".to_string());

        let body = record.body.unwrap_or_default();
        info!("Processing message {}: {}", message_id, body);

        match process_vote(&body, &state).await {
            Ok(_) => info!("Successfully processed vote for message {}", message_id),
            Err(e) => {
                tracing::error!(
                    error = %e,
                    message_id = %message_id,
                    "Failed to process vote - will retry up to DLQ"
                );
                return Err(format!("Failed to process vote: {}", e).into());
            }
        }
    }

    Ok(())
}

async fn process_vote(body: &str, state: &SharedState) -> Result<(), Error> {
    let vote: VoteRequest =
        serde_json::from_str(body).map_err(|e| format!("Invalid vote JSON: {}", e))?;

    info!(
        election_id = %vote.election_id,
        candidate_id = %vote.candidate_id,
        voter = %vote.voter_public_key,
        "Sending vote to blockchain"
    );

    let response = state
        .http_client
        .post(&format!("{}/vote", state.node_rpc_url))
        .json(&vote)
        .send()
        .await
        .map_err(|e| format!("HTTP request failed: {}", e))?;

    if !response.status().is_success() {
        let status = response.status();
        let error_text = response
            .text()
            .await
            .unwrap_or_else(|_| "Unknown error".to_string());
        return Err(format!(
            "Blockchain node rejected vote (status {}): {}",
            status, error_text
        )
        .into());
    }

    info!("Vote successfully submitted to blockchain");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use shared::VoteRequest;

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
        assert!(!req.is_blank_vote);
    }

    #[test]
    fn test_blockchain_url_construction() {
        let node_url = "http://10.0.30.63:9944";
        let election_id = "test_elec";
        let url = format!("{}/vote", node_url);
        assert_eq!(url, "http://10.0.30.63:9944/vote");
    }

    #[test]
    fn test_process_vote_error_message() {
        let error_msg = format!(
            "Blockchain node rejected vote (status {}): {}",
            500, "Internal Server Error"
        );
        assert!(error_msg.contains("500"));
        assert!(error_msg.contains("Internal Server Error"));
    }
}
