use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct AuthRequest {
    pub email: String,
    pub password: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AuthResponse {
    pub role: String,
    pub public_key: Option<String>,
    pub has_password: bool,
    pub has_voted_election: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct RegistrationRequest {
    pub email: String,
    pub public_key: String,
    pub election_id: String,
}

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct Voter {
    pub id: i64,
    pub election_id: String,
    pub email: String,
    pub public_key: String,
    pub role: String,
    pub registered_at: chrono::DateTime<chrono::Utc>,
    pub has_voted: bool,
    pub has_created_password: bool,
}

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct User {
    pub id: i64,
    pub email: String,
    pub public_key: Option<String>,
    pub role: String,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct RoleUpdateRequest {
    pub target_email: String,
    pub new_role: String,
    pub admin_email: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ListUsersRequest {
    pub admin_email: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ElectionResultsRequest {
    pub election_id: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct DeleteCandidateRequest {
    pub election_id: String,
    pub candidate_id: i32,
    pub admin_email: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct VoteRequest {
    pub voter_public_key: String,
    pub candidate_id: String,
    pub election_id: String,
    pub signature: String,
    pub is_blank_vote: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UpdateElectionRequest {
    pub election_id: String,
    pub name: Option<String>,
    pub description: Option<String>,
    pub visibility: String,
    pub status: String,
    pub password: Option<String>,
    pub user_email: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct MyElectionsRequest {
    pub user_email: String,
    pub search: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct DeleteElectionRequest {
    pub election_id: String,
    pub user_email: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct VoteResponse {
    pub success: bool,
    pub block_index: Option<i32>,
    pub block_hash: Option<String>,
    pub message: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ApiResponse<T> {
    pub success: bool,
    pub data: Option<T>,
    pub error: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct Election {
    pub id: String,
    pub name: String,
    pub description: Option<String>,
    pub created_by: String,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub status: String,
    pub visibility: String,
    pub password: Option<String>,
    pub is_official: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct NewElection {
    pub name: String,
    pub description: Option<String>,
    pub created_by: Option<String>,
    pub visibility: String,
    pub status: String,
}

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct Candidate {
    pub id: i32,
    pub election_id: String,
    pub code: String,
    pub name: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct NewCandidate {
    pub election_id: String,
    pub code: String,
    pub name: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GetElectionRequest {
    pub election_id: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct VoterCheckRequest {
    pub election_id: String,
    pub email: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct VoterCheckResponse {
    pub registered: bool,
    pub has_voted: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AuditLog {
    pub id: i32,
    pub action: String,
    pub details: Option<String>,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ElectionResults {
    pub results: std::collections::HashMap<String, u32>,
    pub total_votes: u64,
    pub validated: bool,
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::Utc;

    #[test]
    fn test_vote_request_serialization() {
        let req = VoteRequest {
            voter_public_key: "pk_123".into(),
            candidate_id: "cand_1".into(),
            election_id: "elec_1".into(),
            signature: "sig_abc".into(),
            is_blank_vote: false,
        };

        let json = serde_json::to_string(&req).unwrap();
        let parsed: VoteRequest = serde_json::from_str(&json).unwrap();

        assert_eq!(parsed.voter_public_key, "pk_123");
        assert_eq!(parsed.candidate_id, "cand_1");
        assert_eq!(parsed.election_id, "elec_1");
        assert!(!parsed.is_blank_vote);
    }

    #[test]
    fn test_api_response_success() {
        let resp: ApiResponse<String> = ApiResponse {
            success: true,
            data: Some("ok".into()),
            error: None,
        };

        let json = serde_json::to_string(&resp).unwrap();
        let parsed: ApiResponse<String> = serde_json::from_str(&json).unwrap();

        assert!(parsed.success);
        assert_eq!(parsed.data, Some("ok".into()));
        assert!(parsed.error.is_none());
    }

    #[test]
    fn test_api_response_error() {
        let resp: ApiResponse<String> = ApiResponse {
            success: false,
            data: None,
            error: Some("invalid vote".into()),
        };

        let json = serde_json::to_string(&resp).unwrap();
        let parsed: ApiResponse<String> = serde_json::from_str(&json).unwrap();

        assert!(!parsed.success);
        assert!(parsed.data.is_none());
        assert_eq!(parsed.error, Some("invalid vote".into()));
    }

    #[test]
    fn test_election_results_serialization() {
        let mut results = std::collections::HashMap::new();
        results.insert("cand_1".into(), 10);
        results.insert("cand_2".into(), 5);

        let resp = ElectionResults {
            results: results.clone(),
            total_votes: 15,
            validated: true,
        };

        let json = serde_json::to_string(&resp).unwrap();
        let parsed: ElectionResults = serde_json::from_str(&json).unwrap();

        assert_eq!(parsed.total_votes, 15);
        assert!(parsed.validated);
        assert_eq!(parsed.results.get("cand_1"), Some(&10));
    }

    #[test]
    fn test_auth_request_roundtrip() {
        let req = AuthRequest {
            email: "user@test.com".into(),
            password: Some("secret".into()),
        };

        let json = serde_json::to_string(&req).unwrap();
        let parsed: AuthRequest = serde_json::from_str(&json).unwrap();

        assert_eq!(parsed.email, "user@test.com");
        assert_eq!(parsed.password, Some("secret".into()));
    }
}
