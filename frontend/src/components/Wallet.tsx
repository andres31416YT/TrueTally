'use client';

import { useState, useCallback } from 'react';
import { Key, Lock, Unlock, AlertTriangle, Copy, Check } from 'lucide-react';
import { useWallet } from '@/hooks/useWallet';

interface WalletProps {
  onVoteReady?: (publicKey: string, signedVote: { payload: string; signature: string }) => void;
  candidateId?: string;
}

export function Wallet({ onVoteReady, candidateId }: WalletProps) {
  const {
    keyPair,
    isUnlocked,
    publicKey,
    generateNewKeyPair,
    importKeyPair,
    signVote,
    clearWallet,
  } = useWallet();

  const [importMode, setImportMode] = useState(false);
  const [importPublicKey, setImportPublicKey] = useState('');
  const [importSecretKey, setImportSecretKey] = useState('');
  const [copied, setCopied] = useState<'public' | 'secret' | null>(null);
  const [error, setError] = useState<string | null>(null);

  const handleGenerate = useCallback(() => {
    setError(null);
    generateNewKeyPair();
  }, [generateNewKeyPair]);

  const handleImport = useCallback(() => {
    setError(null);
    if (!importPublicKey || !importSecretKey) {
      setError('Ambas claves son requeridas');
      return;
    }
    if (importSecretKey.length !== 64) {
      setError('La clave privada debe tener 64 caracteres hexadecimales');
      return;
    }
    importKeyPair(importPublicKey, importSecretKey);
    setImportMode(false);
    setImportPublicKey('');
    setImportSecretKey('');
  }, [importPublicKey, importSecretKey, importKeyPair]);

  const handleSignVote = useCallback(() => {
    if (!candidateId || !onVoteReady || !publicKey) return;
    const signed = signVote(candidateId);
    if (signed) {
      onVoteReady(publicKey, signed);
    }
  }, [candidateId, onVoteReady, publicKey, signVote]);

  const copyToClipboard = useCallback((text: string, type: 'public' | 'secret') => {
    navigator.clipboard.writeText(text);
    setCopied(type);
    setTimeout(() => setCopied(null), 2000);
  }, []);

  return (
    <div className="bg-white rounded-lg shadow-md p-6">
      <div className="flex items-center gap-3 mb-6">
        <div className="p-2 bg-primary-100 rounded-lg">
          {isUnlocked ? (
            <Unlock className="w-6 h-6 text-primary-600" />
          ) : (
            <Lock className="w-6 h-6 text-gray-400" />
          )}
        </div>
        <div>
          <h2 className="text-xl font-semibold">Wallet Criptográfica</h2>
          <p className="text-sm text-gray-500">
            {isUnlocked ? 'Desbloqueada' : 'Sin conectar'}
          </p>
        </div>
      </div>

      {!isUnlocked ? (
        <div className="space-y-4">
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
            <div className="flex items-start gap-2">
              <AlertTriangle className="w-5 h-5 text-yellow-600 mt-0.5" />
              <div>
                <p className="text-sm font-medium text-yellow-800">Advertencia de Seguridad</p>
                <p className="text-xs text-yellow-700 mt-1">
                  Tu clave privada se almacenará únicamente en memoria. Nunca se enviará al servidor.
                  Al cerrar esta pestaña, perderás acceso a tu wallet.
                </p>
              </div>
            </div>
          </div>

          {!importMode ? (
            <div className="flex gap-3">
              <button
                onClick={handleGenerate}
                className="flex-1 flex items-center justify-center gap-2 px-4 py-3 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors"
              >
                <Key className="w-4 h-4" />
                Generar Nuevo Par de Claves
              </button>
              <button
                onClick={() => setImportMode(true)}
                className="flex-1 flex items-center justify-center gap-2 px-4 py-3 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
              >
                <Unlock className="w-4 h-4" />
                Importar Claves
              </button>
            </div>
          ) : (
            <div className="space-y-3">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Clave Pública
                </label>
                <input
                  type="text"
                  value={importPublicKey}
                  onChange={(e) => setImportPublicKey(e.target.value)}
                  placeholder="Ingresa tu clave pública (64 caracteres hex)"
                  className="w-full p-2 border rounded-lg font-mono text-sm"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Clave Privada
                </label>
                <input
                  type="password"
                  value={importSecretKey}
                  onChange={(e) => setImportSecretKey(e.target.value)}
                  placeholder="Ingresa tu clave privada (64 caracteres hex)"
                  className="w-full p-2 border rounded-lg font-mono text-sm"
                />
              </div>
              {error && (
                <p className="text-sm text-red-600">{error}</p>
              )}
              <div className="flex gap-3">
                <button
                  onClick={handleImport}
                  className="flex-1 px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700"
                >
                  Importar
                </button>
                <button
                  onClick={() => {
                    setImportMode(false);
                    setError(null);
                  }}
                  className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
                >
                  Cancelar
                </button>
              </div>
            </div>
          )}
        </div>
      ) : keyPair && (
        <div className="space-y-4">
          <div className="bg-green-50 border border-green-200 rounded-lg p-4">
            <div className="flex items-center gap-2 text-green-700">
              <Check className="w-4 h-4" />
              <span className="text-sm font-medium">Wallet Desbloqueada</span>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Tu Clave Pública (ID de Votante)
            </label>
            <div className="flex items-center gap-2">
              <input
                type="text"
                value={keyPair.publicKey}
                readOnly
                className="flex-1 p-2 border rounded bg-gray-50 font-mono text-sm"
              />
              <button
                onClick={() => copyToClipboard(keyPair.publicKey, 'public')}
                className="p-2 text-gray-500 hover:text-gray-700"
                title="Copiar"
              >
                {copied === 'public' ? (
                  <Check className="w-4 h-4 text-green-600" />
                ) : (
                  <Copy className="w-4 h-4" />
                )}
              </button>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Clave Privada (Solo en memoria)
            </label>
            <div className="flex items-center gap-2">
              <input
                type="password"
                value={keyPair.secretKey}
                readOnly
                className="flex-1 p-2 border rounded bg-red-50 font-mono text-sm text-red-700"
              />
              <button
                onClick={() => copyToClipboard(keyPair.secretKey, 'secret')}
                className="p-2 text-gray-500 hover:text-gray-700"
                title="Copiar"
              >
                {copied === 'secret' ? (
                  <Check className="w-4 h-4 text-green-600" />
                ) : (
                  <Copy className="w-4 h-4" />
                )}
              </button>
            </div>
          </div>

          {candidateId && onVoteReady && (
            <button
              onClick={handleSignVote}
              className="w-full flex items-center justify-center gap-2 px-4 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
            >
              <Key className="w-4 h-4" />
              Firmar Voto para Candidato {candidateId}
            </button>
          )}

          <button
            onClick={clearWallet}
            className="w-full px-4 py-2 border border-red-300 text-red-600 rounded-lg hover:bg-red-50 transition-colors"
          >
            Cerrar Wallet (Limpiar Memoria)
          </button>
        </div>
      )}
    </div>
  );
}