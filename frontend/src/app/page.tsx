'use client';

import { useState, useEffect } from 'react';
import { generateKeyPair, signMessage, createVotePayload } from '@/lib/crypto';
import { api, Election, NewElection, Candidate } from '@/lib/api';

interface KeyPair {
  publicKey: string;
  secretKey: string;
}

type Step = 'home' | 'auth' | 'vote' | 'admin' | 'cast' | 'confirm';

interface UserSession {
  dni: string;
  dni_verifier: string;
  role: string;
  public_key: string | undefined;
  has_password: boolean;
  has_voted_election: string | undefined;
}

export default function VotingPage() {
  const [step, setStep] = useState<Step>('home');
  const [session, setSession] = useState<UserSession | null>(null);
  const [keyPair, setKeyPair] = useState<KeyPair | null>(null);
  
  const [elections, setElections] = useState<Election[]>([]);
  const [selectedElection, setSelectedElection] = useState<Election | null>(null);
  const [candidates, setCandidates] = useState<Candidate[]>([]);
  const [selectedCandidate, setSelectedCandidate] = useState<number | null>(null);
  const [blankVote, setBlankVote] = useState(false);
  
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  const [authMode, setAuthMode] = useState<'login' | 'register'>('login');
  const [authData, setAuthData] = useState({
    dni: '',
    dni_verifier: '',
    password: '',
  });

  const [newElection, setNewElection] = useState<NewElection>({
    name: '',
    description: '',
    visibility: 'public',
    election_type: 'general',
    election_category: 'general',
  });

  const [selectedElectionForEdit, setSelectedElectionForEdit] = useState<Election | null>(null);

  const [users, setUsers] = useState<{dni: string, dni_verifier: string, role: string}[]>([]);
  const [activeTab, setActiveTab] = useState<'elections' | 'users'>('elections');

  const [roleData, setRoleData] = useState({
    target_dni: '',
    target_dni_verifier: '',
    new_role: 'user',
  });

  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const ITEMS_PER_PAGE = 10;

  useEffect(() => {
    loadElections();
    const savedSession = localStorage.getItem('user_session');
    if (savedSession) {
      try {
        const parsed = JSON.parse(savedSession);
        setSession(parsed);
        if (parsed.public_key) {
          const keys = generateKeyPair();
          setKeyPair({ publicKey: parsed.public_key, secretKey: keys.secretKey });
        }
      } catch (e) {
        localStorage.removeItem('user_session');
      }
    }
  }, []);

  useEffect(() => {
    setCurrentPage(1);
  }, [searchTerm]);

  const loadElections = async () => {
    const res = await api.listElections();
    if (res.success && res.data) {
      setElections(res.data);
    }
  };

  const filteredElections = elections.filter(e => 
    searchTerm === '' || 
    e.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    (e.description && e.description.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  const paginatedElections = filteredElections.slice(
    (currentPage - 1) * ITEMS_PER_PAGE,
    currentPage * ITEMS_PER_PAGE
  );

  const filteredUsers = users.filter(u => 
    searchTerm === '' || 
    u.dni.includes(searchTerm) ||
    u.role.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const paginatedUsers = filteredUsers.slice(
    (currentPage - 1) * ITEMS_PER_PAGE,
    currentPage * ITEMS_PER_PAGE
  );

  const loadCandidates = async (electionId: string) => {
    const res = await api.getCandidates(electionId);
    if (res.success && res.data) {
      setCandidates(res.data);
    }
  };

  const loadUsers = async () => {
    if (!session) return;
    const res = await api.listUsers(session.dni, session.dni_verifier);
    if (res.success && res.data) {
      setUsers(res.data);
    }
  };

  const handleUpdateRole = async () => {
    if (!roleData.target_dni || roleData.target_dni.length !== 8) {
      setError('El DNI debe tener exactamente 8 dígitos');
      return;
    }
    if (!roleData.target_dni_verifier) {
      setError('El dígito verificador es requerido');
      return;
    }

    setLoading(true);
    setError(null);

    const res = await api.updateRole({
      target_dni: roleData.target_dni,
      target_dni_verifier: roleData.target_dni_verifier,
      new_role: roleData.new_role,
      admin_dni: session!.dni,
      admin_dni_verifier: session!.dni_verifier,
    });

    if (res.success) {
      await loadUsers();
      setRoleData({ target_dni: '', target_dni_verifier: '', new_role: 'user' });
    } else {
      setError(res.error || 'Error al actualizar rol');
    }
    setLoading(false);
  };

  useEffect(() => {
    if (step === 'admin' && isAdmin) {
      loadUsers();
    }
  }, [step]);

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
        password: authData.password || undefined,
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
        
        setStep('home');
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
    if (!newElection.name) {
      setError('El nombre es requerido');
      return;
    }
    setLoading(true);
    setError(null);

    const res = await api.createElection(newElection);
    if (res.success) {
      await loadElections();
      setStep('home');
    } else {
      setError(res.error || 'Error al crear elección');
    }
    setLoading(false);
  };

  const handleLogout = () => {
    localStorage.removeItem('user_session');
    setSession(null);
    setKeyPair(null);
    setStep('home');
  };

  const isAdmin = session?.role === 'admin' || session?.role === 'sudo_admin';
  const canVote = session && session.public_key && (!session.has_voted_election || session.has_voted_election !== selectedElection?.id);

  const electionVoted = selectedElection ? session?.has_voted_election === selectedElection.id : false;

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-blue-800 text-white p-4 shadow-lg">
        <div className="max-w-4xl mx-auto flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-bold">TRUE TALLY</h1>
            <p className="text-sm">Sistema de Votación Blockchain</p>
          </div>
          {session ? (
            <div className="text-right">
              <p className="text-sm">DNI: {session.dni}</p>
              <p className="text-xs">Rol: {session.role}</p>
              <button onClick={handleLogout} className="text-xs underline hover:text-gray-300">
                Cerrar sesión
              </button>
            </div>
          ) : (
            <div className="flex gap-2">
              <button
                onClick={() => { setAuthMode('login'); setStep('auth'); }}
                className="bg-green-600 px-4 py-2 rounded-lg hover:bg-green-700 text-sm font-medium"
              >
                Iniciar Sesión
              </button>
              <button
                onClick={() => { setAuthMode('register'); setStep('auth'); }}
                className="bg-white text-blue-800 px-4 py-2 rounded-lg hover:bg-gray-100 text-sm font-medium"
              >
                Registrarse
              </button>
            </div>
          )}
        </div>
      </header>

      <main className="max-w-4xl mx-auto p-6">
        {step === 'home' && (
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

            {!session && (
              <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 text-center mb-4">
                <p className="text-blue-700">
                  <button onClick={() => { setAuthMode('login'); setStep('auth'); }} className="underline font-medium">
                    Inicia sesión
                  </button> o 
                  <button onClick={() => { setAuthMode('register'); setStep('auth'); }} className="underline font-medium">
                    regístrate
                  </button> para poder votar
                </p>
              </div>
            )}

            {elections.length === 0 ? (
              <p className="text-gray-500 text-center py-8">No hay votaciones activas</p>
            ) : (
              <div className="grid gap-4">
                {paginatedElections.map((election) => (
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
                        {session && canVote && !electionVoted ? (
                          <button
                            onClick={() => handleSelectElection(election)}
                            className="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700"
                          >
                            Votar
                          </button>
                        ) : session && electionVoted ? (
                          <span className="text-gray-400 text-sm">✓ Ya has votado</span>
                        ) : session ? (
                          <span className="text-gray-400 text-sm">No puedes votar</span>
                        ) : (
                          <span className="text-gray-400 text-sm">Inicia sesión para votar</span>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {step === 'auth' && (
          <div className="bg-white rounded-lg shadow-md p-6 max-w-md mx-auto">
            <h2 className="text-xl font-semibold mb-4 text-center">
              {authMode === 'login' ? 'Iniciar Sesión' : 'Registrarse'}
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

              {authMode === 'register' && (
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

              {authMode === 'login' && (
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
                {loading ? 'Procesando...' : authMode === 'login' ? 'Iniciar Sesión' : 'Registrarse'}
              </button>

              <div className="text-center text-sm text-gray-600">
                {authMode === 'login' ? (
                  <>
                    ¿No tienes cuenta?{' '}
                    <button onClick={() => setAuthMode('register')} className="underline text-blue-600">
                      Regístrate
                    </button>
                  </>
                ) : (
                  <>
                    ¿Ya tienes cuenta?{' '}
                    <button onClick={() => setAuthMode('login')} className="underline text-blue-600">
                      Inicia sesión
                    </button>
                  </>
                )}
              </div>

              <button
                onClick={() => setStep('home')}
                className="w-full text-gray-500 py-2 text-sm hover:text-gray-700"
              >
                ← Volver sin iniciar sesión
              </button>
            </div>
          </div>
        )}

        {step === 'vote' && selectedElection && (
          <div className="space-y-4">
            <button onClick={() => setStep('home')} className="text-gray-600 hover:underline">
              ← Volver a votaciones
            </button>

            <h2 className="text-xl font-semibold">{selectedElection.name}</h2>
            
            {electionVoted ? (
              <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 text-center">
                <p className="text-yellow-700 font-medium">Ya has votado en esta elección</p>
              </div>
            ) : (
              <>
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
                          <h3 className="font-semibold">{candidate.name} {candidate.last_name}</h3>
                          <p className="text-blue-600 text-sm">{candidate.category}</p>
                          {candidate.party_id && <p className="text-xs text-gray-500">Partido ID: {candidate.party_id}</p>}
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
              </>
            )}
          </div>
        )}

        {step === 'admin' && isAdmin && (
          <div className="space-y-4">
            <div className="flex justify-between items-center">
              <h2 className="text-xl font-semibold">Panel de Administración</h2>
              <button onClick={() => setStep('home')} className="text-gray-600 hover:underline">
                ← Volver
              </button>
            </div>

            <div className="flex gap-2 border-b">
              <button
                onClick={() => { setActiveTab('elections'); setCurrentPage(1); setSearchTerm(''); }}
                className={`px-4 py-2 ${activeTab === 'elections' ? 'border-b-2 border-blue-600 text-blue-600' : 'text-gray-600'}`}
              >
                Votaciones
              </button>
              {session?.role === 'sudo_admin' && (
                <button
                  onClick={() => { setActiveTab('users'); setCurrentPage(1); setSearchTerm(''); }}
                  className={`px-4 py-2 ${activeTab === 'users' ? 'border-b-2 border-blue-600 text-blue-600' : 'text-gray-600'}`}
                >
                  Usuarios
                </button>
              )}
            </div>

            <div className="mb-4">
              <div className="flex gap-2">
                <input
                  type="text"
                  placeholder={activeTab === 'elections' ? "Buscar votaciones..." : "Buscar usuarios..."}
                  value={searchTerm}
                  onChange={(e) => { setSearchTerm(e.target.value); setCurrentPage(1); }}
                  onKeyDown={(e) => e.key === 'Enter' && setCurrentPage(1)}
                  className="flex-1 p-2 border rounded"
                />
                <button
                  onClick={() => setCurrentPage(1)}
                  className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
                >
                  Buscar
                </button>
              </div>
            </div>

            {activeTab === 'elections' && (

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
                    <p className="text-xs text-gray-500 mt-1">
                      {newElection.election_type === 'presidential_unicameral' && 'Presidente elegido por el pueblo (1 cámara)'}
                      {newElection.election_type === 'presidential_bicameral' && 'Presidente + 2 Vicepresidentes (2 cámaras: Senado + Diputados)'}
                      {newElection.election_type === 'mesa_directivo' && 'Elección de mesa directiva del congreso'}
                      {newElection.election_type === 'general' && 'Votación genérica personalizable'}
                    </p>
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
                      <option value="vice">Vicepresidente(s)</option>
                      <option value="senadores">Senadores</option>
                      <option value="diputados">Diputados</option>
                      <option value="mesa_presidente">Presidente de Mesa</option>
                      <option value="mesa_vice">Vicepresidente de Mesa</option>
                      <option value="mesa_secretario">Secretario de Mesa</option>
                    </select>
                    <p className="text-xs text-gray-500 mt-1">
                      {newElection.election_type === 'presidential_unicameral' && newElection.election_category === 'president' && '1 candidato a Presidente'}
                      {newElection.election_type === 'presidential_unicameral' && newElection.election_category === 'vice' && 'Candidatos a Vicepresidente'}
                      {newElection.election_type === 'presidential_bicameral' && newElection.election_category === 'president' && '1 candidato a Presidente'}
                      {newElection.election_type === 'presidential_bicameral' && newElection.election_category === 'vice' && '2 candidatos a Vicepresidente'}
                      {newElection.election_type === 'presidential_bicameral' && newElection.election_category === 'senadores' && 'Candidatos al Senado (5 por lista)'}
                      {newElection.election_type === 'presidential_bicameral' && newElection.election_category === 'diputados' && 'Candidatos a Cámara de Diputados'}
                      {newElection.election_type === 'mesa_directivo' && newElection.election_category === 'mesa_presidente' && 'Candidato a Presidente de Mesa'}
                      {newElection.election_type === 'mesa_directivo' && newElection.election_category === 'mesa_vice' && 'Candidato a Vicepresidente de Mesa'}
                      {newElection.election_type === 'mesa_directivo' && newElection.election_category === 'mesa_secretario' && 'Candidato a Secretario de Mesa'}
                    </p>
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium mb-1">Visibilidad</label>
                  <select
                    value={newElection.visibility || 'public'}
                    onChange={(e) => setNewElection({ ...newElection, visibility: e.target.value as 'public' | 'private' })}
                    className="w-full p-2 border rounded"
                  >
                    <option value="public">Pública - Todos pueden ver</option>
                    <option value="private">Privada - Requiere contraseña</option>
                  </select>
                </div>

                {newElection.visibility === 'private' && (
                  <div>
                    <label className="block text-sm font-medium mb-1">Contraseña del evento</label>
                    <input
                      type="password"
                      value={newElection.password || ''}
                      onChange={(e) => setNewElection({ ...newElection, password: e.target.value })}
                      className="w-full p-2 border rounded"
                      placeholder="Contraseña para acceder al evento"
                    />
                  </div>
                )}

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
            )}

            {activeTab === 'users' && (
              <div className="bg-white rounded-lg shadow-md p-6">
                <h3 className="font-semibold mb-4">Gestionar Usuarios</h3>
                
                <div className="mb-6">
                  <h4 className="text-sm font-medium mb-2">Lista de Usuarios</h4>
                  <div className="border rounded-lg overflow-hidden">
                    <table className="w-full text-sm">
                      <thead className="bg-gray-50">
                        <tr>
                          <th className="px-4 py-2 text-left">DNI</th>
                          <th className="px-4 py-2 text-left">Verificador</th>
                          <th className="px-4 py-2 text-left">Rol</th>
                        </tr>
                      </thead>
                      <tbody>
                        {users.map((user, i) => (
                          <tr key={i} className="border-t">
                            <td className="px-4 py-2">{user.dni}</td>
                            <td className="px-4 py-2">{user.dni_verifier}</td>
                            <td className="px-4 py-2">
                              <span className={`px-2 py-1 rounded text-xs ${
                                user.role === 'sudo_admin' ? 'bg-red-100 text-red-700' :
                                user.role === 'admin' ? 'bg-purple-100 text-purple-700' :
                                'bg-gray-100 text-gray-700'
                              }`}>
                                {user.role}
                              </span>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>

                {isAdmin && session?.role === 'sudo_admin' && (
                  <div className="border-t pt-4">
                    <h4 className="text-sm font-medium mb-2">Cambiar Rol de Usuario</h4>
                    <div className="grid grid-cols-3 gap-4 mb-4">
                      <div>
                        <label className="block text-xs mb-1">DNI</label>
                        <input
                          type="text"
                          value={roleData.target_dni}
                          onChange={(e) => setRoleData({...roleData, target_dni: e.target.value.replace(/\D/g, '').slice(0, 8)})}
                          className="w-full p-2 border rounded"
                          placeholder="12345678"
                          maxLength={8}
                        />
                      </div>
                      <div>
                        <label className="block text-xs mb-1">Verificador</label>
                        <input
                          type="text"
                          value={roleData.target_dni_verifier}
                          onChange={(e) => setRoleData({...roleData, target_dni_verifier: e.target.value.replace(/\D/g, '').slice(0, 1)})}
                          className="w-full p-2 border rounded"
                          maxLength={1}
                        />
                      </div>
                      <div>
                        <label className="block text-xs mb-1">Nuevo Rol</label>
                        <select
                          value={roleData.new_role}
                          onChange={(e) => setRoleData({...roleData, new_role: e.target.value})}
                          className="w-full p-2 border rounded"
                        >
                          <option value="user">User</option>
                          <option value="admin">Admin</option>
                        </select>
                      </div>
                    </div>
                    <button
                      onClick={handleUpdateRole}
                      disabled={loading || !roleData.target_dni || !roleData.target_dni_verifier}
                      className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 disabled:bg-gray-400"
                    >
                      {loading ? 'Actualizando...' : 'Actualizar Rol'}
                    </button>
                  </div>
                )}
              </div>
            )}
          </div>
        )}

        {step === 'confirm' && (
          <div className="bg-white rounded-lg shadow-md p-6 text-center">
            <h2 className="text-2xl font-bold text-green-600 mb-4">✓ Voto Confirmado</h2>
            <p className="text-gray-600 mb-6">Tu voto ha sido registrado en la blockchain.</p>
            <button
              onClick={() => { setStep('home'); setBlankVote(false); setSelectedCandidate(null); }}
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