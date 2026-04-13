const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080';

interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

function getAuthHeaders(): Record<string, string> {
  const sessionData = typeof window !== 'undefined' ? localStorage.getItem('user_session') : null;
  if (!sessionData) return {};
  
  try {
    const session = JSON.parse(sessionData);
    return {
      'X-User-DNI': session.dni || '',
      'X-User-Verifier': session.dni_verifier || '',
      'X-User-Role': session.role || '',
    };
  } catch {
    return {};
  }
}

async function fetchApi<T>(endpoint: string, options?: RequestInit): Promise<ApiResponse<T>> {
  try {
    const authHeaders = getAuthHeaders();
    const response = await fetch(`${API_URL}${endpoint}`, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...authHeaders,
        ...options?.headers,
      },
    });

    const responseText = await response.text();
    
    if (!response.ok) {
      let errorMessage = 'Request failed';
      try {
        const errorData = JSON.parse(responseText);
        errorMessage = errorData.error || errorData.message || errorMessage;
      } catch {
        errorMessage = responseText || errorMessage;
      }
      return {
        success: false,
        error: errorMessage,
      };
    }

    try {
      const data = JSON.parse(responseText);
      return data;
    } catch {
      return {
        success: false,
        error: 'Invalid JSON response from server',
      };
    }
  } catch (error) {
    const errorMsg = error instanceof Error ? error.message : 'Unknown error';
    return {
      success: false,
      error: errorMsg,
    };
  }
}

export interface Election {
  id: string;
  name: string;
  description?: string;
  status: 'Borrador' | 'Publicado' | 'Terminado';
  visibility: 'public' | 'private';
  password?: string;
  is_official?: boolean;
  created_by?: string;
}

export interface NewElection {
  name: string;
  description?: string;
  visibility?: 'public' | 'private';
  status?: 'Borrador' | 'Publicado' | 'Terminado';
  password?: string;
}

export interface Party {
  id: number;
  election_id: string;
  name: string;
  abbreviation?: string;
  logo_url?: string;
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
  public_key?: string;
  email?: string;
  election_id?: string;
  password: string;
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
  election_id: number;
  code: string;
  name: string;
}

export interface NewCandidate {
  election_id: string;
  code: string;
  name: string;
}

export interface DeleteCandidateRequest {
  election_id: string;
  candidate_id: number;
  admin_dni: string;
  admin_dni_verifier: string;
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
    fetchApi<Election[]>('/elections/all', { method: 'GET' }),

  listAllElections: () =>
    fetchApi<Election[]>('/elections/all', { method: 'GET' }),

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

  deleteCandidate: (request: DeleteCandidateRequest) =>
    fetchApi<string>('/candidates/delete', {
      method: 'POST',
      body: JSON.stringify(request),
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

  updateRole: (data: { target_dni: string; target_dni_verifier: string; new_role: string; admin_dni: string; admin_dni_verifier: string }) =>
    fetchApi<string>('/update-role', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  listUsers: (admin_dni: string, admin_dni_verifier: string) =>
    fetchApi<{ dni: string; dni_verifier: string; role: string }[]>('/users', {
      method: 'POST',
      body: JSON.stringify({ admin_dni, admin_dni_verifier }),
    }),

  updateElection: (data: { election_id: string; name?: string; description?: string; visibility?: 'public' | 'private'; status?: 'Borrador' | 'Publicado' | 'Terminado'; password?: string; user_dni: string }) =>
    fetchApi<string>('/update-election', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  deleteElection: (election_id: string, user_dni: string) =>
    fetchApi<string>('/delete-election', {
      method: 'POST',
      body: JSON.stringify({ election_id, user_dni }),
    }),

  listMyElections: (user_dni: string) =>
    fetchApi<Election[]>('/my-elections', {
      method: 'POST',
      body: JSON.stringify({ user_dni }),
    }),

  health: () => fetchApi<{ status: string }>('/health', { method: 'GET' }),
};
