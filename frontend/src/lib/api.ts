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

export interface Voter {
  name: string;
  email: string;
  has_voted: boolean;
}

export interface NewVoter {
  public_key: string;
  name: string;
  email: string;
}

export interface VoteRequest {
  voter_public_key: string;
  candidate_id: string;
  signature: string;
}

export interface Candidate {
  id: number;
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

export interface VoteData {
  voter_public_key: string;
  candidate_id: string;
  signature: string;
}

export interface Block {
  index: number;
  timestamp: string;
  data: VoteData;
  previous_hash: string;
  nonce: number;
  hash: string;
}

export const api = {
  registerVoter: (voter: NewVoter) =>
    fetchApi<number>('/register', {
      method: 'POST',
      body: JSON.stringify(voter),
    }),

  getVoter: (publicKey: string) =>
    fetchApi<Voter>('/voter', {
      method: 'POST',
      body: JSON.stringify({ public_key: publicKey }),
    }),

  submitVote: (vote: VoteRequest) =>
    fetchApi<VoteResponse>('/vote', {
      method: 'POST',
      body: JSON.stringify(vote),
    }),

  getResults: () =>
    fetchApi<Record<string, number>>('/results', { method: 'GET' }),

  getBlocks: () =>
    fetchApi<Block[]>('/blocks', { method: 'GET' }),

  getCandidates: () =>
    fetchApi<Candidate[]>('/candidates', { method: 'GET' }),

  addCandidate: (candidate: { name: string; party: string; bio?: string }) =>
    fetchApi<number>('/candidates', {
      method: 'POST',
      body: JSON.stringify(candidate),
    }),

  deleteCandidate: (id: number) =>
    fetchApi<boolean>('/candidates', {
      method: 'DELETE',
      body: JSON.stringify({ id }),
    }),

  health: () => fetchApi<{ status: string }>('/health', { method: 'GET' }),
};