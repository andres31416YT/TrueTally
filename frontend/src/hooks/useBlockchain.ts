import { useState, useEffect, useCallback } from 'react';
import { api, Block, Candidate, VoteRequest, VoteResponse } from './api';

interface ConnectionStatus {
  isConnected: boolean;
  latency?: number;
  lastChecked?: Date;
  error?: string;
}

interface BlockchainState {
  blocks: Block[];
  candidates: Candidate[];
  results: Record<string, number>;
  isLoading: boolean;
  error: string | null;
}

export function useBlockchain(pollInterval = 5000) {
  const [connectionStatus, setConnectionStatus] = useState<ConnectionStatus>({
    isConnected: false,
  });
  
  const [state, setState] = useState<BlockchainState>({
    blocks: [],
    candidates: [],
    results: {},
    isLoading: true,
    error: null,
  });

  const checkConnection = useCallback(async () => {
    const start = Date.now();
    try {
      const result = await api.health();
      const latency = Date.now() - start;
      
      setConnectionStatus({
        isConnected: result.success,
        latency,
        lastChecked: new Date(),
        error: result.error || undefined,
      });
      
      return result.success;
    } catch (error) {
      setConnectionStatus({
        isConnected: false,
        lastChecked: new Date(),
        error: error instanceof Error ? error.message : 'Connection failed',
      });
      return false;
    }
  }, []);

  const fetchBlocks = useCallback(async () => {
    const result = await api.getBlocks();
    if (result.success && result.data) {
      setState(prev => ({ ...prev, blocks: result.data! }));
    }
    return result.success;
  }, []);

  const fetchCandidates = useCallback(async () => {
    const result = await api.getCandidates();
    if (result.success && result.data) {
      setState(prev => ({ ...prev, candidates: result.data! }));
    }
    return result.success;
  }, []);

  const fetchResults = useCallback(async () => {
    const result = await api.getResults();
    if (result.success && result.data) {
      setState(prev => ({ ...prev, results: result.data! }));
    }
    return result.success;
  }, []);

  const refreshAll = useCallback(async () => {
    setState(prev => ({ ...prev, isLoading: true, error: null }));
    
    const [blocksOk, candidatesOk, resultsOk] = await Promise.all([
      fetchBlocks(),
      fetchCandidates(),
      fetchResults(),
    ]);

    const allSuccess = blocksOk && candidatesOk && resultsOk;
    setState(prev => ({
      ...prev,
      isLoading: false,
      error: allSuccess ? null : 'Error al cargar datos',
    }));

    return allSuccess;
  }, [fetchBlocks, fetchCandidates, fetchResults]);

  const submitVote = useCallback(async (vote: VoteRequest): Promise<VoteResponse> => {
    const result = await api.submitVote(vote);
    if (result.success && result.data) {
      await fetchBlocks();
      await fetchResults();
    }
    return result.data || { success: false, message: result.error };
  }, [fetchBlocks, fetchResults]);

  useEffect(() => {
    checkConnection();
    refreshAll();

    const connectionInterval = setInterval(checkConnection, 10000);
    const pollIntervalId = setInterval(refreshAll, pollInterval);

    return () => {
      clearInterval(connectionInterval);
      clearInterval(pollIntervalId);
    };
  }, [checkConnection, refreshAll, pollInterval]);

  return {
    ...state,
    connectionStatus,
    refreshAll,
    submitVote,
    checkConnection,
  };
}