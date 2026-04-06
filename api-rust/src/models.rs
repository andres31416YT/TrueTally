use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Voter {
    pub id: i64,
    pub public_key: String,
    pub name: String,
    pub email: String,
    pub registered_at: chrono::DateTime<chrono::Utc>,
    pub has_voted: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NewVoter {
    pub public_key: String,
    pub name: String,
    pub email: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Candidate {
    pub id: i64,
    pub name: String,
    pub party: String,
    pub bio: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NewCandidate {
    pub name: String,
    pub party: String,
    pub bio: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VoteRequest {
    pub voter_public_key: String,
    pub candidate_id: String,
    pub signature: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VoteResponse {
    pub success: bool,
    pub block_index: Option<u64>,
    pub block_hash: Option<String>,
    pub message: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ElectionResults {
    pub results: std::collections::HashMap<String, u32>,
    pub total_votes: u64,
    pub validated: bool,
}