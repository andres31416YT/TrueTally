'use client';

import { useState, useEffect } from 'react';
import { generateKeyPair, signMessage, createVotePayload } from '@/lib/crypto';
import { api, Election, Candidate, NewElection } from '@/lib/api';

interface KeyPair {
  publicKey: string;
  secretKey: string;
}

type Step = 'home' | 'create' | 'vote' | 'register' | 'cast' | 'confirm';

export default function VotingPage() {
  const [step, setStep] = useState<Step>('home');
  const [elections, setElections] = useState<Election[]>([]);
  const [selectedElection, setSelectedElection] = useState<Election | null>(null);
  const [candidates, setCandidates] = useState<Candidate[]>([]);
  const [keyPair, setKeyPair] = useState<KeyPair | null>(null);
  const [selectedCandidate, setSelectedCandidate] = useState<number | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  const [newElection, setNewElection] = useState<NewElection>({
    name: '',
    description: '',
    admin_code: '',
  });
  
  const [voterData, setVoterData] = useState({
    name: '',
    email: '',
  });

  useEffect(() => {
    loadElections();
  }, []);

  const loadElections = async () => {
    const res = await api.listElections();
    if (res.success && res.data) {
      setElections(res.data.filter((e: Election) => e.is_active));
    }
  };

  const handleCreateElection = async () => {
    if (!newElection.name || !newElection.admin_code) {
      setError('Nombre y código de administrador son requeridos');
      return;
    }
    setLoading(true);
    setError(null);
    
    const res = await api.createElection(newElection);
    if (res.success && res.data) {
      await loadElections();
      const election = await api.getElection(res.data);
      if (election.success && election.data) {
        setSelectedElection(election.data);
        setStep('vote');
      }
    } else {
      setError(res.error || 'Error al crear elección');
    }
    setLoading(false);
  };

  const handleSelectElection = async (election: Election) => {
    setSelectedElection(election);
    setStep('vote');
  };

  const handleGenerateKeys = () => {
    const keys = generateKeyPair();
    setKeyPair(keys);
    setStep('register');
  };

  const handleRegister = async () => {
    if (!keyPair || !selectedElection || !voterData.name || !voterData.email) return;
    
    setLoading(true);
    setError(null);

    const res = await api.registerVoter({
      public_key: keyPair.publicKey,
      name: voterData.name,
      email: voterData.email,
      election_id: selectedElection.id,
    });

    if (res.success) {
      const candRes = await api.getCandidates(selectedElection.id);
      if (candRes.success && candRes.data) {
        setCandidates(candRes.data);
      }
      setStep('cast');
    } else {
      setError(res.error || 'Error al registrar');
    }
    setLoading(false);
  };

  const handleSubmitVote = async () => {
    if (!keyPair || !selectedCandidate || !selectedElection) return;

    setLoading(true);
    setError(null);

    try {
      const payload = createVotePayload(keyPair.publicKey, selectedCandidate.toString(), selectedElection.id);
      const signature = signMessage(payload, keyPair.secretKey);

      const res = await api.submitVote({
        voter_public_key: keyPair.publicKey,
        candidate_id: selectedCandidate.toString(),
        election_id: selectedElection.id,
        signature,
      });

      if (res.success) {
        setStep('confirm');
      } else {
        setError(res.error || 'Error al enviar voto');
      }
    } catch (err: any) {
      setError(err.message || 'Error al firmar el voto');
    }
    setLoading(false);
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-blue-600 text-white p-4 shadow-lg">
        <div className="max-w-4xl mx-auto">
          <h1 className="text-2xl font-bold">TrueTally - Votación Blockchain</h1>
        </div>
      </header>

      <main className="max-w-4xl mx-auto p-6">
        {step === 'home' && (
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-xl font-semibold mb-4">Selecciona una elección</h2>
            
            <button
              onClick={() => setStep('create')}
              className="mb-6 bg-green-600 text-white px-6 py-3 rounded-lg hover:bg-green-700"
            >
              + Crear Nueva Elección
            </button>

            {elections.length === 0 ? (
              <p className="text-gray-500">No hay elecciones activas</p>
            ) : (
              <div className="space-y-3">
                {elections.map((election) => (
                  <div
                    key={election.id}
                    onClick={() => handleSelectElection(election)}
                    className="p-4 border rounded-lg cursor-pointer hover:bg-blue-50 hover:border-blue-300"
                  >
                    <h3 className="font-semibold text-lg">{election.name}</h3>
                    <p className="text-gray-600 text-sm">{election.description || 'Sin descripción'}</p>
                    <p className="text-xs text-gray-400 mt-2">ID: {election.id}</p>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {step === 'create' && (
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-xl font-semibold mb-4">Crear Nueva Elección</h2>
            
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium mb-1">Nombre de la elección</label>
                <input
                  type="text"
                  value={newElection.name}
                  onChange={(e) => setNewElection({ ...newElection, name: e.target.value })}
                  className="w-full p-2 border rounded"
                  placeholder="Elección Presidencial 2026"
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium mb-1">Descripción (opcional)</label>
                <textarea
                  value={newElection.description || ''}
                  onChange={(e) => setNewElection({ ...newElection, description: e.target.value })}
                  className="w-full p-2 border rounded"
                  placeholder="Descripción de la elección..."
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium mb-1">Código de administrador</label>
                <input
                  type="text"
                  value={newElection.admin_code}
                  onChange={(e) => setNewElection({ ...newElection, admin_code: e.target.value })}
                  className="w-full p-2 border rounded"
                  placeholder="Código para administrar la elección"
                />
              </div>

              {error && (
                <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
                  {error}
                </div>
              )}

              <div className="flex gap-3">
                <button
                  onClick={handleCreateElection}
                  disabled={loading}
                  className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 disabled:bg-gray-400"
                >
                  {loading ? 'Creando...' : 'Crear Elección'}
                </button>
                <button
                  onClick={() => setStep('home')}
                  className="bg-gray-500 text-white px-6 py-2 rounded-lg hover:bg-gray-600"
                >
                  Cancelar
                </button>
              </div>
            </div>
          </div>
        )}

        {step === 'vote' && selectedElection && (
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-xl font-semibold mb-2">{selectedElection.name}</h2>
            <p className="text-gray-600 mb-4">ID: {selectedElection.id}</p>
            
            <p className="text-gray-600 mb-4">
              Para votar, primero genera tu par de claves criptográficas.
              Tu clave pública te identifica como votante, y la clave privada firma tu voto.
            </p>
            
            <button
              onClick={handleGenerateKeys}
              className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700"
            >
              Generar Par de Claves
            </button>

            <button
              onClick={() => { setSelectedElection(null); setStep('home'); }}
              className="ml-4 text-gray-600 hover:underline"
            >
              Volver
            </button>
          </div>
        )}

        {step === 'register' && keyPair && selectedElection && (
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-xl font-semibold mb-4">Tus Claves</h2>
            
            <div className="mb-4 p-3 bg-yellow-50 border border-yellow-200 rounded">
              <p className="text-sm font-medium text-yellow-800">Importante:</p>
              <p className="text-sm text-yellow-700">Guarda tu clave privada. No se puede recuperar si la pierdes.</p>
            </div>
            
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">Tu Clave Pública</label>
              <input
                type="text"
                value={keyPair.publicKey}
                readOnly
                className="w-full p-2 border rounded bg-gray-50 font-mono text-sm"
              />
            </div>

            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">Tu Clave Privada (GUÁRDALA)</label>
              <input
                type="text"
                value={keyPair.secretKey}
                readOnly
                className="w-full p-2 border rounded bg-red-50 font-mono text-sm text-red-700"
              />
            </div>

            <hr className="my-4" />

            <h3 className="font-semibold mb-3">Regístrate para votar</h3>
            
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">Nombre</label>
              <input
                type="text"
                value={voterData.name}
                onChange={(e) => setVoterData({ ...voterData, name: e.target.value })}
                className="w-full p-2 border rounded"
              />
            </div>

            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
              <input
                type="email"
                value={voterData.email}
                onChange={(e) => setVoterData({ ...voterData, email: e.target.value })}
                className="w-full p-2 border rounded"
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
              className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 disabled:bg-gray-400"
            >
              {loading ? 'Registrando...' : 'Registrarse y Continuar'}
            </button>
          </div>
        )}

        {step === 'cast' && selectedElection && (
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-xl font-semibold mb-4">Selecciona tu candidato</h2>
            
            {candidates.length === 0 ? (
              <div className="text-center py-8">
                <p className="text-gray-500 mb-4">No hay candidatos disponibles</p>
                <p className="text-sm text-gray-400">Como administrador, agrega candidatos usando la API</p>
              </div>
            ) : (
              <div className="space-y-3 mb-6">
                {candidates.map((candidate) => (
                  <label
                    key={candidate.id}
                    className={`block p-4 border rounded-lg cursor-pointer ${
                      selectedCandidate === candidate.id
                        ? 'border-blue-500 bg-blue-50'
                        : 'hover:bg-gray-50'
                    }`}
                  >
                    <input
                      type="radio"
                      name="candidate"
                      checked={selectedCandidate === candidate.id}
                      onChange={() => setSelectedCandidate(candidate.id)}
                      className="mr-3"
                    />
                    <span className="font-semibold">{candidate.name}</span>
                    <span className="text-gray-500 ml-2">({candidate.party})</span>
                    {candidate.bio && (
                      <p className="text-sm text-gray-600 mt-1">{candidate.bio}</p>
                    )}
                  </label>
                ))}
              </div>
            )}

            {error && (
              <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
                {error}
              </div>
            )}

            <button
              onClick={handleSubmitVote}
              disabled={loading || !selectedCandidate}
              className="bg-green-600 text-white px-6 py-3 rounded-lg hover:bg-green-700 disabled:bg-gray-400"
            >
              {loading ? 'Firmando y Enviando...' : 'Firmar y Enviar Voto'}
            </button>
          </div>
        )}

        {step === 'confirm' && (
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-xl font-semibold mb-4 text-green-600">✓ Voto Confirmado</h2>
            
            <div className="bg-green-50 border border-green-200 rounded-lg p-4 mb-4">
              <p className="text-green-800">Tu voto ha sido registrado exitosamente en la blockchain.</p>
            </div>

            <button
              onClick={() => window.location.reload()}
              className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700"
            >
              Nueva Votación
            </button>
          </div>
        )}
      </main>
    </div>
  );
}
