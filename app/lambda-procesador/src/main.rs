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
