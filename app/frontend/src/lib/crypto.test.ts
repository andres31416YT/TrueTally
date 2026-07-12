import {
  generateKeyPair,
  createVotePayload,
  toHex,
  fromHex,
  getValidKeyPair,
  sanitizeStoredSecretKey,
} from '@/lib/crypto';

if (typeof global.TextEncoder === 'undefined') {
  const { TextEncoder, TextDecoder } = require('util');
  global.TextEncoder = TextEncoder as unknown as typeof globalThis.TextEncoder;
  global.TextDecoder = TextDecoder as unknown as typeof globalThis.TextDecoder;
}

beforeEach(() => {
  localStorage.clear();
});

describe('crypto utilities', () => {
  describe('toHex / fromHex', () => {
    it('round-trips bytes correctly', () => {
      const original = new Uint8Array([0, 1, 2, 255]);
      const hex = toHex(original);
      expect(hex).toBe('000102ff');
      expect(fromHex(hex)).toEqual(original);
    });

    it('converts full Ed25519 public key length (32 bytes -> 64 hex chars)', () => {
      const pubKey = new Uint8Array(32);
      expect(toHex(pubKey).length).toBe(64);
    });

    it('converts full Ed25519 secret key length (64 bytes -> 128 hex chars)', () => {
      const secretKey = new Uint8Array(64);
      expect(toHex(secretKey).length).toBe(128);
    });
  });

  describe('generateKeyPair', () => {
    it('returns public key of 64 hex chars and secret key of 128 hex chars', () => {
      const keys = generateKeyPair();
      expect(keys.publicKey).toHaveLength(64);
      expect(keys.secretKey).toHaveLength(128);
      expect(/^[0-9a-f]+$/i.test(keys.publicKey)).toBe(true);
      expect(/^[0-9a-f]+$/i.test(keys.secretKey)).toBe(true);
    });

    it('generates unique keys across calls', () => {
      const a = generateKeyPair();
      const b = generateKeyPair();
      expect(a.publicKey).not.toBe(b.publicKey);
      expect(a.secretKey).not.toBe(b.secretKey);
    });
  });

  describe('createVotePayload', () => {
    it('returns deterministic JSON with expected fields', () => {
      const payload = createVotePayload('pk_test', 'cand_1', 'elec_1');
      const parsed = JSON.parse(payload);

      expect(parsed).toEqual({
        voter_public_key: 'pk_test',
        candidate_id: 'cand_1',
        election_id: 'elec_1',
        timestamp: expect.any(Number),
      });
    });
  });

  describe('getValidKeyPair', () => {
    it('generates a fresh keypair when localStorage is empty', () => {
      const keys = getValidKeyPair('pk_test');
      expect(keys.secretKey).toHaveLength(128);
      expect(localStorage.getItem('user_secret_key')).toHaveLength(128);
    });

    it('reuses a valid 128-char hex stored secret key with provided publicKey', () => {
      const secret = toHex(new Uint8Array(64));
      localStorage.setItem('user_secret_key', secret);

      const keys = getValidKeyPair('pk_test');
      expect(keys.publicKey).toBe('pk_test');
      expect(keys.secretKey).toBe(secret);
    });

    it('rejects the legacy placeholder string sk_session_active', () => {
      localStorage.setItem('user_secret_key', 'sk_session_active');

      const keys = getValidKeyPair('pk_test');
      expect(keys.secretKey).not.toBe('sk_session_active');
      expect(keys.secretKey).toHaveLength(128);
    });

    it('rejects a short invalid hex string (deadbeef)', () => {
      localStorage.setItem('user_secret_key', 'deadbeef');

      const keys = getValidKeyPair('pk_test');
      expect(keys.secretKey).not.toBe('deadbeef');
      expect(keys.secretKey).toHaveLength(128);
    });
  });

  describe('sanitizeStoredSecretKey', () => {
    it('removes invalid stored secret keys', () => {
      localStorage.setItem('user_secret_key', 'sk_session_active');
      sanitizeStoredSecretKey();
      expect(localStorage.getItem('user_secret_key')).toBeNull();
    });

    it('keeps valid 128-hex stored secret keys', () => {
      const valid = toHex(new Uint8Array(64));
      localStorage.setItem('user_secret_key', valid);
      sanitizeStoredSecretKey();
      expect(localStorage.getItem('user_secret_key')).toBe(valid);
    });

    it('removes non-hex stored values', () => {
      localStorage.setItem('user_secret_key', 'not-hex-at-all');
      sanitizeStoredSecretKey();
      expect(localStorage.getItem('user_secret_key')).toBeNull();
    });
  });
});
