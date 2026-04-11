'use client';

import { useState, useEffect } from 'react';
import { generateKeyPair, signMessage, createVotePayload } from '@/lib/crypto';
import { api, Election, NewElection, Candidate, User } from '@/lib/api';

interface KeyPair {
  publicKey: string;
  secretKey: string;
}

type Step = 'auth' | 'votations' | 'vote' | 'admin' | 'cast' | 'confirm';

interface UserSession {
  dni: string;
  dni_verifier: string;
  role: string;
  public_key: string | undefined;
  has_password: boolean;
  has_voted_election: string | undefined;
}

export default function VotingPage() {
  const [step, setStep] = useState<Step>('auth');
  const [session, setSession] = useState<UserSession | null>(null);
  const [keyPair, setKeyPair] = useState<KeyPair | null>(null);
  
  const [elections, setElections] = useState<Election[]>([]);
  const [selectedElection, setSelectedElection] = useState<Election | null>(null);
  const [candidates, setCandidates] = useState<Candidate[]>([]);
  const [selectedCandidate, setSelectedCandidate] = useState<number | null>(null);
  const [blankVote, setBlankVote] = useState(false);
  
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  const [authData, setAuthData] = useState({
    dni: '',
    dni_verifier: '',
    password: '',
  });

  const [newElection, setNewElection] = useState<NewElection>({
    name: '',
    description: '',
    admin_code: '',
    election_type: 'general',
    election_category: 'general',
  });

  useEffect(() => {
    loadElections();
    const savedSession = localStorage.getItem('user_session');
    if (savedSession) {
      try {
        const parsed = JSON.parse(savedSession);
        setSession(parsed);
        if (parsed.public_key) {
          setStep('votations');
        }
      } catch (e) {
        localStorage.removeItem('user_session');
      }
    }
  }, []);

  const loadElections = async () => {
    const res = await api.listElections();
    if (res.success && res.data) {
      setElections(res.data.filter((e: Election) => e.is_active));
    }
  };

  const loadCandidates = async (electionId: string) => {
    const res = await api.getCandidates(electionId);
    if (res.success && res.data) {
      setCandidates(res.data);
    }
  };

  const handleAuth = async () => {
    if (!authData.dni || authData.dni.length !== 8) {
      setError('El DNI debe tener exactamente 8 dígitos');
      return;
    }
    if (!authData.dni_verifier) {
      setError('El dígito verificador es requerido');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const res = await api.authenticate({
        dni: authData.dni,
        dni_verifier: authData.dni_verifier,
        password: authData.password,
      });

      if (res.success && res.data) {
        const newSession: UserSession = {
          dni: authData.dni,
          dni_verifier: authData.dni_verifier,
          role: res.data.role,
          public_key: res.data.public_key,
          has_password: res.data.has_password,
          has_voted_election: res.data.has_voted_election,
        };
        setSession(newSession);
        localStorage.setItem('user_session', JSON.stringify(newSession));
        
        if (res.data.public_key) {
          const keys = generateKeyPair();
          setKeyPair({ publicKey: res.data.public_key, secretKey: keys.secretKey });
        }
        
        setStep('votations');
      } else {
        setError(res.error || 'Error en autenticación');
      }
    } catch (err: any) {
      setError(err.message || 'Error en autenticación');
    }
    setLoading(false);
  };

  const handleSelectElection = async (election: Election) => {
    setSelectedElection(election);
    await loadCandidates(election.id);
    setStep('vote');
  };

  const handleSubmitVote = async () => {
    if (!keyPair || !selectedElection) return;
    if (!blankVote && !selectedCandidate) {
      setError('Selecciona un candidato');
      return;
    }

    setLoading(true);
    setError(null);

    const electionId = selectedElection.id;

    try {
      const candidateId = blankVote ? undefined : selectedCandidate?.toString();
      const payload = createVotePayload(
        keyPair.publicKey,
        blankVote ? "blank" : selectedCandidate!.toString(),
        electionId
      );
      const signature = signMessage(payload, keyPair.secretKey);

      const res = await api.submitVote({
        voter_public_key: keyPair.publicKey,
        candidate_id: candidateId,
        election_id: electionId,
        signature,
        is_blank_vote: blankVote,
      });

      if (res.success) {
        if (session) {
          session.has_voted_election = electionId;
          localStorage.setItem('user_session', JSON.stringify(session));
        }
        setStep('confirm');
      } else {
        setError(res.error || 'Error al enviar voto');
      }
    } catch (err: any) {
      setError(err.message || 'Error al firmar el voto');
    }
    setLoading(false);
  };

  const handleCreateElection = async () => {
    if (!newElection.name || !newElection.admin_code) {
      setError('Nombre y código de administrador son requeridos');
      return;
    }
    setLoading(true);
    setError(null);

    const res = await api.createElection(newElection);
    if (res.success) {
      await loadElections();
      setStep('votations');
    } else {
      setError(res.error || 'Error al crear elección');
    }
    setLoading(false);
  };

  const handleLogout = () => {
    localStorage.removeItem('user_session');
    setSession(null);
    setKeyPair(null);
    setStep('auth');
  };

  const isAdmin = session?.role === 'admin' || session?.role === 'sudo_admin';
  const canVote = session && session.public_key && (!session.has_voted_election || session.has_voted_election !== selectedElection?.id);

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-blue-800 text-white p-4 shadow-lg">
        <div className="max-w-4xl mx-auto flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-bold">TRUE TALLY</h1>
            <p className="text-sm">Sistema de Votación Blockchain</p>
          </div>
          {session && (
            <div className="text-right">
              <p className="text-sm">DNI: {session.dni}</p>
              <p className="text-xs">Rol: {session.role}</p>
              <button onClick={handleLogout} className="text-xs underline hover:text-gray-300">
                Cerrar sesión
              </button>
            </div>
          )}
        </div>
      </header>

      <main className="max-w-4xl mx-auto p-6">
        {step === 'auth' && (
          <div className="bg-white rounded-lg shadow-md p-6 max-w-md mx-auto">
            <h2 className="text-xl font-semibold mb-4 text-center">
              {session?.has_password ? 'Iniciar Sesión' : 'Registrarse'}
            </h2>
            
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium mb-1">DNI (8 dígitos)</label>
                <input
                  type="text"
                  value={authData.dni}
                  onChange={(e) => setAuthData({ ...authData, dni: e.target.value.replace(/\D/g, '').slice(0, 8) })}
                  className="w-full p-2 border rounded"
                  placeholder="12345678"
                  maxLength={8}
                />
              </div>

              <div>
                <label className="block text-sm font-medium mb-1">Dígito Verificador</label>
                <input
                  type="text"
                  value={authData.dni_verifier}
                  onChange={(e) => setAuthData({ ...authData, dni_verifier: e.target.value.replace(/\D/g, '').slice(0, 1) })}
                  className="w-full p-2 border rounded"
                  placeholder="0"
                  maxLength={1}
                />
              </div>

              {!session?.has_password && (
                <div>
                  <label className="block text-sm font-medium mb-1">Crear Contraseña</label>
                  <input
                    type="password"
                    value={authData.password}
                    onChange={(e) => setAuthData({ ...authData, password: e.target.value })}
                    className="w-full p-2 border rounded"
                    placeholder="Mínimo 6 caracteres"
                  />
                </div>
              )}

              {session?.has_password && (
                <div>
                  <label className="block text-sm font-medium mb-1">Contraseña</label>
                  <input
                    type="password"
                    value={authData.password}
                    onChange={(e) => setAuthData({ ...authData, password: e.target.value })}
                    className="w-full p-2 border rounded"
                    placeholder="Tu contraseña"
                  />
                </div>
              )}

              {error && (
                <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
                  {error}
                </div>
              )}

              <button
                onClick={handleAuth}
                disabled={loading || !authData.dni || !authData.dni_verifier}
                className="w-full bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 disabled:bg-gray-400"
              >
                {loading ? 'Procesando...' : session?.has_password ? 'Iniciar Sesión' : 'Registrarse'}
              </button>

              <button
                onClick={() => setStep('votations')}
                className="w-full text-gray-600 py-2 text-sm hover:underline"
              >
                Ver votaciones sin registrarme
              </button>
            </div>
          </div>
        )}

        {step === 'votations' && (
          <div className="space-y-4">
            <div className="flex justify-between items-center">
              <h2 className="text-xl font-semibold">Votaciones Disponibles</h2>
              {isAdmin && (
                <button
                  onClick={() => setStep('admin')}
                  className="bg-purple-600 text-white px-4 py-2 rounded-lg hover:bg-purple-700"
                >
                  Panel Admin
                </button>
              )}
            </div>

            {elections.length === 0 ? (
              <p className="text-gray-500 text-center py-8">No hay votaciones activas</p>
            ) : (
              <div className="grid gap-4">
                {elections.map((election) => (
                  <div key={election.id} className="bg-white rounded-lg shadow-md p-4 border-l-4 border-blue-500">
                    <div className="flex justify-between items-start">
                      <div>
                        <h3 className="font-bold text-lg">{election.name}</h3>
                        <p className="text-gray-600 text-sm">{election.description}</p>
                        <div className="mt-2 flex gap-2">
                          <span className="text-xs bg-gray-100 px-2 py-1 rounded">
                            Tipo: {election.election_type}
                          </span>
                          <span className="text-xs bg-gray-100 px-2 py-1 rounded">
                            Categoría: {election.election_category}
                          </span>
                          {election.is_official && (
                            <span className="text-xs bg-green-100 text-green-700 px-2 py-1 rounded">
                              Oficial
                            </span>
                          )}
                        </div>
                      </div>
                      <div className="text-right">
                        {session && canVote ? (
                          <button
                            onClick={() => handleSelectElection(election)}
                            className="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700"
                          >
                            Votar
                          </button>
                        ) : session ? (
                          <span className="text-gray-400 text-sm">Ya has votado</span>
                        ) : (
                          <button
                            onClick={() => handleSelectElection(election)}
                            className="text-blue-600 hover:underline text-sm"
                          >
                            Ver detalles
                          </button>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {!session && (
              <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 text-center">
                <p className="text-blue-700">
                  <button onClick={() => setStep('auth')} className="underline font-medium">
                    Inicia sesión
                  </button> para poder votar
                </p>
              </div>
            )}
          </div>
        )}

        {step === 'vote' && selectedElection && (
          <div className="space-y-4">
            <button onClick={() => setStep('votations')} className="text-gray-600 hover:underline">
              ← Volver a votaciones
            </button>

            <h2 className="text-xl font-semibold">{selectedElection.name}</h2>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {candidates.map((candidate) => (
                <div
                  key={candidate.id}
                  onClick={() => { setSelectedCandidate(candidate.id); setBlankVote(false); }}
                  className={`p-4 border-2 rounded-lg cursor-pointer transition-all ${
                    selectedCandidate === candidate.id
                      ? 'border-blue-500 bg-blue-50 shadow-lg'
                      : 'border-gray-200 hover:border-blue-300'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <div className={`w-10 h-10 rounded-full flex items-center justify-center font-bold text-white ${
                      selectedCandidate === candidate.id ? 'bg-blue-600' : 'bg-gray-400'
                    }`}>
                      {candidate.id}
                    </div>
                    <div>
                      <h3 className="font-semibold">{candidate.name}</h3>
                      <p className="text-blue-600 text-sm">{candidate.party}</p>
                      <p className="text-xs text-gray-500">ID: {candidate.candidate_external_id}</p>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            <div className="p-4 border-2 border-gray-300 rounded-lg">
              <label className="flex items-center cursor-pointer">
                <input
                  type="checkbox"
                  checked={blankVote}
                  onChange={() => { setBlankVote(!blankVote); setSelectedCandidate(null); }}
                  className="w-5 h-5 text-blue-600"
                />
                <span className="ml-2 font-medium">Voto en blanco</span>
              </label>
            </div>

            {error && (
              <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
                {error}
              </div>
            )}

            <button
              onClick={handleSubmitVote}
              disabled={loading || (!selectedCandidate && !blankVote)}
              className="w-full bg-green-600 text-white px-6 py-4 rounded-lg text-lg font-semibold hover:bg-green-700 disabled:bg-gray-400"
            >
              {loading ? 'Enviando...' : 'CONFIRMAR VOTO'}
            </button>
          </div>
        )}

        {step === 'admin' && isAdmin && (
          <div className="space-y-4">
            <div className="flex justify-between items-center">
              <h2 className="text-xl font-semibold">Panel de Administración</h2>
              <button onClick={() => setStep('votations')} className="text-gray-600 hover:underline">
                ← Volver
              </button>
            </div>

            <div className="bg-white rounded-lg shadow-md p-6">
              <h3 className="font-semibold mb-4">Crear Nueva Votación</h3>
              
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium mb-1">Nombre</label>
                  <input
                    type="text"
                    value={newElection.name}
                    onChange={(e) => setNewElection({ ...newElection, name: e.target.value })}
                    className="w-full p-2 border rounded"
                    placeholder="Elecciones 2026"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium mb-1">Descripción</label>
                  <textarea
                    value={newElection.description || ''}
                    onChange={(e) => setNewElection({ ...newElection, description: e.target.value })}
                    className="w-full p-2 border rounded"
                    placeholder="Descripción de la votación..."
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium mb-1">Tipo de Votación</label>
                    <select
                      value={newElection.election_type || 'general'}
                      onChange={(e) => setNewElection({ ...newElection, election_type: e.target.value })}
                      className="w-full p-2 border rounded"
                    >
                      <option value="general">General</option>
                      <option value="presidential_unicameral">Presidencial Unicameral</option>
                      <option value="presidential_bicameral">Presidencial Bicameral</option>
                      <option value="mesa_directivo">Mesa Directivo</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-1">Categoría</label>
                    <select
                      value={newElection.election_category || 'general'}
                      onChange={(e) => setNewElection({ ...newElection, election_category: e.target.value })}
                      className="w-full p-2 border rounded"
                    >
                      <option value="general">General</option>
                      <option value="president">Presidente</option>
                      <option value="vice">Vicepresidente</option>
                      <option value="diputados">Diputados</option>
                    </select>
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium mb-1">Código Admin</label>
                  <input
                    type="text"
                    value={newElection.admin_code}
                    onChange={(e) => setNewElection({ ...newElection, admin_code: e.target.value })}
                    className="w-full p-2 border rounded"
                    placeholder="Código para administrar"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium mb-1">Contraseña (opcional)</label>
                  <input
                    type="password"
                    value={newElection.password || ''}
                    onChange={(e) => setNewElection({ ...newElection, password: e.target.value })}
                    className="w-full p-2 border rounded"
                    placeholder="Proteger votación"
                  />
                </div>

                {error && (
                  <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
                    {error}
                  </div>
                )}

                <button
                  onClick={handleCreateElection}
                  disabled={loading}
                  className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 disabled:bg-gray-400"
                >
                  {loading ? 'Creando...' : 'Crear Votación'}
                </button>
              </div>
            </div>
          </div>
        )}

        {step === 'confirm' && (
          <div className="bg-white rounded-lg shadow-md p-6 text-center">
            <h2 className="text-2xl font-bold text-green-600 mb-4">✓ Voto Confirmado</h2>
            <p className="text-gray-600 mb-6">Tu voto ha sido registrado en la blockchain.</p>
            <button
              onClick={() => { setStep('votations'); setBlankVote(false); setSelectedCandidate(null); }}
              className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700"
            >
              Ver Votaciones
            </button>
          </div>
        )}
      </main>
    </div>
  );
}