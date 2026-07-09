export interface KeyPair {
  publicKey: string;
  secretKey: string;
}

import nacl from 'tweetnacl';

export function toHex(bytes: Uint8Array): string {
  return Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

export function fromHex(hex: string): Uint8Array {
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < bytes.length; i++) {
    bytes[i] = parseInt(hex.substr(i * 2, 2), 16);
  }
  return bytes;
}

export function generateKeyPair(): KeyPair {
  const keyPair = nacl.sign.keyPair();
  return {
    publicKey: toHex(keyPair.publicKey),
    secretKey: toHex(keyPair.secretKey),
  };
}

export function signMessage(message: string, secretKeyHex: string): string {
  const messageBytes = new TextEncoder().encode(message);
  const keyBytes = fromHex(secretKeyHex);
  const signature = nacl.sign.detached(messageBytes, keyBytes);
  return toHex(signature);
}

export function verifySignature(
  message: string,
  signatureHex: string,
  publicKeyHex: string
): boolean {
  const messageBytes = new TextEncoder().encode(message);
  const signatureBytes = fromHex(signatureHex);
  const keyBytes = fromHex(publicKeyHex);
  return nacl.sign.detached.verify(messageBytes, signatureBytes, keyBytes);
}

const ED25519_SECRET_KEY_BYTE_LENGTH = 64;
const ED25519_SECRET_KEY_HEX_LENGTH = ED25519_SECRET_KEY_BYTE_LENGTH * 2;

export function getValidKeyPair(storedPublicKey?: string): KeyPair {
  const storedSecretKey = typeof window !== 'undefined'
    ? localStorage.getItem('user_secret_key')
    : null;

  const secretKeyValue = storedSecretKey ?? '';
  const hasValidStoredSecretKey = Boolean(
    secretKeyValue.length === ED25519_SECRET_KEY_HEX_LENGTH &&
      /^[0-9a-f]+$/i.test(secretKeyValue)
  );

  if (hasValidStoredSecretKey && storedPublicKey) {
    return { publicKey: storedPublicKey, secretKey: storedSecretKey as string };
  }

  const keys = generateKeyPair();
  localStorage.setItem('user_secret_key', keys.secretKey);
  return keys;
}

export function sanitizeStoredSecretKey(): void {
  if (typeof window === 'undefined') return;
  const secretKey = localStorage.getItem('user_secret_key');
  const isValid = Boolean(
    secretKey &&
      secretKey.length === ED25519_SECRET_KEY_HEX_LENGTH &&
      /^[0-9a-f]+$/i.test(secretKey)
  );
  if (!isValid) {
    localStorage.removeItem('user_secret_key');
  }
}

export function createVotePayload(
  voterPublicKey: string,
  candidateId: string,
  electionId: string
): string {
  return JSON.stringify({
    voter_public_key: voterPublicKey,
    candidate_id: candidateId,
    election_id: electionId,
    timestamp: Date.now(),
  });
}
