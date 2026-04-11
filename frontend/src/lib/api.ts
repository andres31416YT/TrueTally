const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080';

interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

async function fetchApi<T>(endpoint: string, options?: RequestInit): Promise<ApiResponse<T>> {
  try {
    const response = await fetch(`${API_URL}${endpoint}`, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...options?.headers,
      },
    });

    const data = await response.json();
    return data;
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

export interface Election {
  id: string;
  name: string;
  description?: string;
  is_active: boolean;
  election_type: string;
  election_category: string;
  password?: string;
  is_official: boolean;
  created_by?: string;
}

export interface NewElection {
  name: string;
  description?: string;
  admin_code: string;
  election_type?: string;
  election_category?: string;
  password?: string;
}

export interface User {
  dni: string;
  dni_verifier: string;
  public_key?: string;
  role: string;
  has_password: boolean;
  has_voted_election?: string;
}

export interface AuthRequest {
  dni: string;
  dni_verifier: string;
  password?: string;
}

export interface AuthResponse {
  role: string;
  public_key?: string;
  has_password: boolean;
  has_voted_election?: string;
}

export interface NewVoter {
  dni: string;
  dni_verifier: string;
  public_key: string;
  email?: string;
  election_id: string;
}

export interface VoteRequest {
  voter_public_key: string;
  candidate_id?: string;
  election_id: string;
  signature: string;
  is_blank_vote: boolean;
}

export interface Candidate {
  id: number;
  candidate_external_id?: string;
  party_id?: string;
  name: string;
  party: string;
  category: string;
  bio?: string;
  photo_url?: string;
}

export interface NewCandidate {
  election_id: string;
  candidate_external_id?: string;
  party_id?: string;
  name: string;
  party: string;
  category?: string;
  photo_url: string;
  bio?: string;
}

export interface VoteResponse {
  success: boolean;
  block_index?: number;
  block_hash?: string;
  message?: string;
}

export interface Block {
  index: number;
  timestamp: string;
  data: any;
  previous_hash: string;
  nonce: number;
  hash: string;
}

export const api = {
  authenticate: (auth: AuthRequest) =>
    fetchApi<AuthResponse>('/auth', {
      method: 'POST',
      body: JSON.stringify(auth),
    }),

  createElection: (election: NewElection) =>
    fetchApi<string>('/elections', {
      method: 'POST',
      body: JSON.stringify(election),
    }),

  listElections: () =>
    fetchApi<Election[]>('/elections', { method: 'GET' }),

  getElection: (electionId: string) =>
    fetchApi<Election>('/election', {
      method: 'POST',
      body: JSON.stringify({ election_id: electionId }),
    }),

  addCandidate: (candidate: NewCandidate) =>
    fetchApi<number>('/candidates', {
      method: 'POST',
      body: JSON.stringify(candidate),
    }),

  getCandidates: (electionId: string) =>
    fetchApi<Candidate[]>('/candidates', {
      method: 'POST',
      body: JSON.stringify({ election_id: electionId }),
    }),

  registerVoter: (voter: NewVoter) =>
    fetchApi<number>('/register', {
      method: 'POST',
      body: JSON.stringify(voter),
    }),

  getVoter: (electionId: string, publicKey: string) =>
    fetchApi<Voter>('/voter', {
      method: 'POST',
      body: JSON.stringify({ election_id: electionId, public_key: publicKey }),
    }),

  submitVote: (vote: VoteRequest) =>
    fetchApi<VoteResponse>('/vote', {
      method: 'POST',
      body: JSON.stringify(vote),
    }),

  getResults: (electionId: string) =>
    fetchApi<Record<string, number>>('/results', {
      method: 'POST',
      body: JSON.stringify({ election_id: electionId }),
    }),

  getBlocks: () =>
    fetchApi<Block[]>('/blocks', { method: 'GET' }),

  health: () => fetchApi<{ status: string }>('/health', { method: 'GET' }),
};
