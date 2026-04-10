use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Voter {
    pub id: i64,
    pub dni: String,
    pub public_key: String,
    pub name: String,
    pub email: String,
    pub election_id: String,
    pub registered_at: chrono::DateTime<chrono::Utc>,
    pub has_voted: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NewVoter {
    pub dni: String,
    pub public_key: String,
    pub name: String,
    pub email: String,
    pub election_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Election {
    pub id: String,
    pub name: String,
    pub description: Option<String>,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub is_active: bool,
    pub admin_code: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NewElection {
    pub name: String,
    pub description: Option<String>,
    pub admin_code: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Candidate {
    pub id: i64,
    pub election_id: String,
    pub name: String,
    pub party: String,
    pub bio: Option<String>,
    pub photo_url: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NewCandidate {
    pub election_id: String,
    pub name: String,
    pub party: String,
    pub photo_url: String,
    pub bio: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VoteRequest {
    pub voter_public_key: String,
    pub candidate_id: String,
    pub election_id: String,
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
