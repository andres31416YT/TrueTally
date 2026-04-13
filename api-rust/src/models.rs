use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Voter {
    pub id: i64,
    pub dni: String,
    pub dni_verifier: String,
    pub public_key: String,
    pub email: Option<String>,
    pub election_id: String,
    pub registered_at: chrono::DateTime<chrono::Utc>,
    pub has_voted: bool,
    pub role: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NewVoter {
    pub dni: String,
    pub dni_verifier: String,
    pub public_key: Option<String>,
    pub email: Option<String>,
    pub election_id: Option<String>,
    pub password: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Election {
    pub id: String,
    pub name: String,
    pub description: Option<String>,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub is_active: bool,
    pub admin_code: String,
    pub status: String,
    pub visibility: String,
    pub password: Option<String>,
    pub is_official: bool,
    pub created_by: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NewElection {
    pub name: String,
    pub description: Option<String>,
    pub visibility: Option<String>,
    pub status: Option<String>,
    pub password: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Candidate {
    pub id: i64,
    pub election_id: String,
    pub code: String,
    pub name: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NewCandidate {
    pub election_id: String,
    pub code: String,
    pub name: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeleteCandidateRequest {
    pub election_id: String,
    pub candidate_id: i64,
    pub admin_dni: String,
    pub admin_dni_verifier: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VoteRequest {
    pub voter_public_key: String,
    pub candidate_id: Option<String>,
    pub election_id: String,
    pub signature: String,
    pub is_blank_vote: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct User {
    pub id: i64,
    pub dni: String,
    pub dni_verifier: String,
    pub public_key: Option<String>,
    pub role: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuthRequest {
    pub dni: String,
    pub dni_verifier: String,
    pub password: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuthResponse {
    pub role: String,
    pub public_key: Option<String>,
    pub has_password: bool,
    pub has_voted_election: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateRoleRequest {
    pub target_dni: String,
    pub target_dni_verifier: String,
    pub new_role: String,
    pub admin_dni: String,
    pub admin_dni_verifier: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ListUsersRequest {
    pub admin_dni: String,
    pub admin_dni_verifier: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateElectionRequest {
    pub election_id: String,
    pub name: Option<String>,
    pub description: Option<String>,
    pub visibility: Option<String>,
    pub status: Option<String>,
    pub password: Option<String>,
    pub user_dni: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeleteElectionRequest {
    pub election_id: String,
    pub user_dni: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ListMyElectionsRequest {
    pub user_dni: String,
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
