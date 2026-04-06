'use client';

import { useState, useEffect } from 'react';
import { generateKeyPair, signMessage, createVotePayload } from '@/lib/crypto';
import { api, NewVoter } from '@/lib/api';

interface KeyPair {
  publicKey: string;
  secretKey: string;
}

export default function VotingPage() {
  const [step, setStep] = useState<'register' | 'keys' | 'vote' | 'confirm'>('register');
  const [keyPair, setKeyPair] = useState<KeyPair | null>(null);
  const [voterData, setVoterData] = useState<NewVoter>({
    public_key: '',
    name: '',
    email: '',
  });
  const [candidates, setCandidates] = useState<Array<{ id: number; name: string; party: string }>>([]);
  const [selectedCandidate, setSelectedCandidate] = useState<number | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [voteStatus, setVoteStatus] = useState<'pending' | 'confirmed' | 'failed'>('pending');
  const [voteHash, setVoteHash] = useState<string>('');

  useEffect(() => {
    api.getCandidates().then((res) => {
      if (res.success && res.data) {
        setCandidates(res.data);
      }
    });
  }, []);

  const handleRegister = async () => {
    if (!keyPair) return;
    
    setLoading(true);
    setError(null);

    const voterRegData = {
      ...voterData,
      public_key: keyPair.publicKey,
    };

    const result = await api.registerVoter(voterRegData);
    
    if (result.success) {
      setStep('vote');
    } else {
      setError(result.error || 'Registration failed');
    }
    setLoading(false);
  };

  const handleGenerateKeys = () => {
    const keys = generateKeyPair();
    setKeyPair(keys);
    setStep('keys');
  };

  const handleSubmitVote = async () => {
    if (!keyPair || !selectedCandidate) return;

    setLoading(true);
    setError(null);

    const payload = createVotePayload(keyPair.publicKey, selectedCandidate.toString());
    const signature = signMessage(payload, keyPair.secretKey);

    const voteRequest = {
      voter_public_key: keyPair.publicKey,
      candidate_id: selectedCandidate.toString(),
      signature,
    };

    const result = await api.submitVote(voteRequest);

    if (result.success) {
      setVoteStatus('confirmed');
      setStep('confirm');
    } else {
      setVoteStatus('failed');
      setError(result.error || 'Vote submission failed');
    }
    setLoading(false);
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-primary-700 text-white p-4 shadow-lg">
        <div className="max-w-4xl mx-auto">
          <h1 className="text-2xl font-bold">TrueTally - Votación Electrónica</h1>
        </div>
      </header>

      <main className="max-w-4xl mx-auto p-6">
        {step === 'register' && (
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-xl font-semibold mb-4">Registro de Votante</h2>
            <p className="text-gray-600 mb-4">
              Primero, genera tu par de claves criptográficas. Tu clave pública te identifica
              como votante, y la clave privada firma tu voto. Nunca compartas tu clave privada.
            </p>
            
            <button
              onClick={handleGenerateKeys}
              className="bg-primary-600 text-white px-6 py-3 rounded-lg hover:bg-primary-700 transition-colors"
            >
              Generar Par de Claves
            </button>
          </div>
        )}

        {step === 'keys' && keyPair && (
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-xl font-semibold mb-4">Claves Generadas</h2>
            
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Tu Clave Pública (ID de Votante)
              </label>
              <input
                type="text"
                value={keyPair.publicKey}
                readOnly
                className="w-full p-2 border rounded bg-gray-50 font-mono text-sm"
              />
            </div>

            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Tu Clave Privada (GUÁRDALA - No se puede recuperar)
              </label>
              <input
                type="text"
                value={keyPair.secretKey}
                readOnly
                className="w-full p-2 border rounded bg-red-50 font-mono text-sm text-red-700"
              />
            </div>

            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">Nombre</label>
              <input
                type="text"
                value={voterData.name}
                onChange={(e) => setVoterData({ ...voterData, name: e.target.value })}
                className="w-full p-2 border rounded"
                placeholder="Tu nombre completo"
              />
            </div>

            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
              <input
                type="email"
                value={voterData.email}
                onChange={(e) => setVoterData({ ...voterData, email: e.target.value })}
                className="w-full p-2 border rounded"
                placeholder="tu@email.com"
              />
            </div>

            {error && (
              <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
                {error}
              </div>
            )}

            <button
              onClick={handleRegister}
              disabled={loading || !voterData.name || !voterData.email}
              className="bg-primary-600 text-white px-6 py-3 rounded-lg hover:bg-primary-700 transition-colors disabled:bg-gray-400"
            >
              {loading ? 'Registrando...' : 'Registrarse y Continuar'}
            </button>
          </div>
        )}

        {step === 'vote' && (
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-xl font-semibold mb-4">Selecciona tu Candidato</h2>
            
            <div className="space-y-3 mb-6">
              {candidates.map((candidate) => (
                <label
                  key={candidate.id}
                  className={`block p-4 border rounded-lg cursor-pointer transition-colors ${
                    selectedCandidate === candidate.id
                      ? 'border-primary-500 bg-primary-50'
                      : 'hover:bg-gray-50'
                  }`}
                >
                  <input
                    type="radio"
                    name="candidate"
                    value={candidate.id}
                    checked={selectedCandidate === candidate.id}
                    onChange={() => setSelectedCandidate(candidate.id)}
                    className="sr-only"
                  />
                  <div className="flex items-center justify-between">
                    <div>
                      <span className="font-semibold">{candidate.name}</span>
                      <span className="text-gray-500 ml-2">({candidate.party})</span>
                    </div>
                    {selectedCandidate === candidate.id && (
                      <span className="text-primary-600">✓ Seleccionado</span>
                    )}
                  </div>
                </label>
              ))}
            </div>

            {error && (
              <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
                {error}
              </div>
            )}

            <button
              onClick={handleSubmitVote}
              disabled={loading || !selectedCandidate}
              className="bg-green-600 text-white px-6 py-3 rounded-lg hover:bg-green-700 transition-colors disabled:bg-gray-400"
            >
              {loading ? 'Firmando y Enviando Voto...' : 'Firmar y Enviar Voto'}
            </button>
          </div>
        )}

        {step === 'confirm' && (
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-xl font-semibold mb-4 text-green-600">Voto Confirmado</h2>
            
            <div className="bg-green-50 border border-green-200 rounded-lg p-4 mb-4">
              <p className="text-green-800">
                Tu voto ha sido registrado exitosamente en la blockchain.
              </p>
              <p className="text-sm text-green-600 mt-2">
                Estado: {voteStatus === 'confirmed' ? '✓ Confirmado' : 'Pendiente'}
              </p>
            </div>

            <div className="mt-4">
              <h3 className="font-medium text-gray-700 mb-2">Información del Voto:</h3>
              <div className="text-sm text-gray-600">
                <p>Clave pública: {keyPair?.publicKey.slice(0, 16)}...</p>
                <p>Candidato ID: {selectedCandidate}</p>
              </div>
            </div>

            <button
              onClick={() => window.location.reload()}
              className="mt-4 bg-primary-600 text-white px-6 py-2 rounded-lg hover:bg-primary-700"
            >
              Nueva Votación
            </button>
          </div>
        )}
      </main>
    </div>
  );
}