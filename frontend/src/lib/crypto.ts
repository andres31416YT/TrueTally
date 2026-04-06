export interface KeyPair {
  publicKey: string;
  secretKey: string;
}

export function generateKeyPair(): KeyPair {
  const box = nacl.box.keyPair();
  return {
    publicKey: toHex(box.publicKey),
    secretKey: toHex(box.secretKey),
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

export function importKeyPairFromHex(publicKey: string, secretKey: string): {
  publicKey: Uint8Array;
  secretKey: Uint8Array;
} {
  return {
    publicKey: fromHex(publicKey),
    secretKey: fromHex(secretKey),
  };
}

export function createVotePayload(
  voterPublicKey: string,
  candidateId: string
): string {
  return JSON.stringify({
    voter_public_key: voterPublicKey,
    candidate_id: candidateId,
    timestamp: Date.now(),
  });
}

function toHex(bytes: Uint8Array): string {
  return Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

function fromHex(hex: string): Uint8Array {
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < bytes.length; i++) {
    bytes[i] = parseInt(hex.substr(i * 2, 2), 16);
  }
  return bytes;
}