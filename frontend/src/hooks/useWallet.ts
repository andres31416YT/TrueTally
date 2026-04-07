import { useState, useCallback, useEffect } from 'react';
import { generateKeyPair, signMessage, createVotePayload, KeyPair as CryptoKeyPair } from '@/lib/crypto';

interface WalletState {
  keyPair: CryptoKeyPair | null;
  isUnlocked: boolean;
  publicKey: string | null;
}

const MEMORY_KEY = 'truetally_wallet_session';

export function useWallet() {
  const [walletState, setWalletState] = useState<WalletState>({
    keyPair: null,
    isUnlocked: false,
    publicKey: null,
  });

  const clearWallet = useCallback(() => {
    setWalletState({
      keyPair: null,
      isUnlocked: false,
      publicKey: null,
    });
    sessionStorage.removeItem(MEMORY_KEY);
  }, []);

  const importKeyPair = useCallback((publicKey: string, secretKey: string) => {
    const keyPair: CryptoKeyPair = { publicKey, secretKey };
    setWalletState({
      keyPair,
      isUnlocked: true,
      publicKey,
    });
    sessionStorage.setItem(MEMORY_KEY, JSON.stringify({ publicKey, secretKey }));
    return keyPair;
  }, []);

  const generateNewKeyPair = useCallback(() => {
    const keyPair = generateKeyPair();
    setWalletState({
      keyPair,
      isUnlocked: true,
      publicKey: keyPair.publicKey,
    });
    sessionStorage.setItem(MEMORY_KEY, JSON.stringify(keyPair));
    return keyPair;
  }, []);

  const signVote = useCallback((candidateId: string): { payload: string; signature: string } | null => {
    if (!walletState.keyPair) return null;
    
    const payload = createVotePayload(walletState.publicKey!, candidateId);
    const signature = signMessage(payload, walletState.keyPair.secretKey);
    
    return { payload, signature };
  }, [walletState.keyPair, walletState.publicKey]);

  useEffect(() => {
    try {
      const stored = sessionStorage.getItem(MEMORY_KEY);
      if (stored) {
        const { publicKey, secretKey } = JSON.parse(stored);
        setWalletState({
          keyPair: { publicKey, secretKey },
          isUnlocked: true,
          publicKey,
        });
      }
    } catch {
      clearWallet();
    }
  }, [clearWallet]);

  return {
    ...walletState,
    generateNewKeyPair,
    importKeyPair,
    signVote,
    clearWallet,
  };
}