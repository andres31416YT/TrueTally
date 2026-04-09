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
}

export interface NewElection {
  name: string;
  description?: string;
  admin_code: string;
}

export interface Voter {
  name: string;
  email: string;
  has_voted: boolean;
}

export interface NewVoter {
  public_key: string;
  name: string;
  email: string;
  election_id: string;
}

export interface VoteRequest {
  voter_public_key: string;
  candidate_id: string;
  election_id: string;
  signature: string;
}

export interface Candidate {
  id: number;
  name: string;
  party: string;
  bio?: string;
}

export interface NewCandidate {
  election_id: string;
  name: string;
  party: string;
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
