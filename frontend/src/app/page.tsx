'use client';

import { useState, useEffect } from 'react';
import { generateKeyPair, signMessage, createVotePayload } from '@/lib/crypto';
import { api, Election, NewElection } from '@/lib/api';

interface KeyPair {
  publicKey: string;
  secretKey: string;
}

interface CandidateDemo {
  id: number;
  name: string;
  party: string;
  proposal: string;
  bio?: string;
  photo_url?: string;
}

const DEMO_CANDIDATES: CandidateDemo[] = [
  { id: 1, name: "Pedro Castillo", party: "Perú Libre", proposal: "Garantizar educación y salud gratuitas para todos los peruanos. Lucha contra la corrupción." },
  { id: 2, name: "Keiko Fujimori", party: "Fuerza Popular", proposal: "Orden y seguridad con mano dura. Incentivos a empresas para generar empleo." },
  { id: 3, name: "Yonhy Lescano", party: " Perú Nación", proposal: "Refundar el país con una nueva constituyente. Educación gratuita y universal." },
  { id: 4, name: "Verónika Mendoza", party: "Frente Popular", proposal: "Salud y educación públicas de calidad. Protectores del medio ambiente." },
  { id: 5, name: "Alberto Fujimori", party: "Nueva Mayoría", proposal: "Continuidad del modelo económico. Seguridad ciudadana reforzada." },
  { id: 6, name: "Rafael López Aliaga", party: "Renovación Popular", proposal: "Acabar con la delincuencia. Inversión en infraestructura vial." },
  { id: 7, name: "George Forsyth", party: "Victoria Nacional", proposal: "Manos a la obra. Desarrollo económico y reducción de pobreza." },
  { id: 8, name: "Ciro Gálvez", party: "Renacimiento Nacional", proposal: "Unidos por el desarrollo. Educación técnica para jóvenes." },
  { id: 9, name: "Daniel Urruti", party: "Juntos por el Perú", proposal: "Salud para todos. Redistribución de recursos a regiones." },
  { id: 10, name: "Marco Arana", party: "Verde Equo", proposal: "Economía sostenible. Cuidado del ambiente y recursos naturales." },
];

type Step = 'home' | 'create' | 'vote' | 'register' | 'cast' | 'confirm';

export default function VotingPage() {
  const [step, setStep] = useState<Step>('home');
  const [elections, setElections] = useState<Election[]>([]);
  const [selectedElection, setSelectedElection] = useState<Election | null>(null);
  const [candidates, setCandidates] = useState<CandidateDemo[]>(DEMO_CANDIDATES);
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
    dni: '',
    name: '',
    email: '',
  });

  useEffect(() => {
    loadElections();
  }, []);

  const loadElections = async () => {
    const res = await api.listElections();
    if (res.success && res.data) {
      const activeElections = res.data.filter((e: Election) => e.is_active);
      setElections(activeElections);
      if (activeElections.length === 0) {
        const createRes = await api.createElection({
          name: 'Elecciones Generales 2026',
          description: 'Elecciones generales del año 2026',
          admin_code: 'admin2026',
        });
        if (createRes.success && createRes.data) {
          const newRes = await api.getElection(createRes.data);
          if (newRes.success && newRes.data) {
            setSelectedElection(newRes.data);
            setElections([newRes.data]);
          }
        }
      }
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
    if (!selectedCandidate) {
      setError('Selecciona un candidato');
      return;
    }
    const keys = generateKeyPair();
    setKeyPair(keys);
    setStep('register');
  };

  const getActiveElectionId = (): string => {
    if (selectedElection) {
      return selectedElection.id;
    }
    if (elections.length > 0) {
      return elections[0].id;
    }
    return "election_2026";
  };

  const handleRegister = async () => {
    if (!keyPair || !selectedCandidate) {
      setError('Error de sesión');
      return;
    }
    if (!voterData.dni || voterData.dni.length !== 8) {
      setError('El DNI debe tener exactamente 8 dígitos');
      return;
    }
    if (!voterData.name) {
      setError('El nombre es requerido');
      return;
    }
    if (!voterData.email) {
      setError('El email es requerido');
      return;
    }
    if (!voterData.email.toLowerCase().endsWith('@gmail.com')) {
      setError('Solo se permiten correos @gmail.com');
      return;
    }
    
    setLoading(true);
    setError(null);

    const electionId = getActiveElectionId();

    try {
      const payload = createVotePayload(keyPair.publicKey, selectedCandidate.toString(), electionId);
      const signature = signMessage(payload, keyPair.secretKey);

      const res = await api.registerVoter({
        dni: voterData.dni,
        public_key: keyPair.publicKey,
        name: voterData.name,
        email: voterData.email,
        election_id: electionId,
      });

      if (res.success) {
        setStep('cast');
      } else {
        setError(res.error || 'Error al registrar');
      }
    } catch (err: any) {
      setError(err.message || 'Error al registrar cliente');
    }
    setLoading(false);
  };

  const handleSubmitVote = async () => {
    if (!keyPair || !selectedCandidate) return;

    setLoading(true);
    setError(null);

    const electionId = getActiveElectionId();

    try {
      const payload = createVotePayload(keyPair.publicKey, selectedCandidate.toString(), electionId);
      const signature = signMessage(payload, keyPair.secretKey);

      const res = await api.submitVote({
        voter_public_key: keyPair.publicKey,
        candidate_id: selectedCandidate.toString(),
        election_id: electionId,
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
      <header className="bg-blue-800 text-white p-4 shadow-lg">
        <div className="max-w-4xl mx-auto">
          <h1 className="text-2xl font-bold text-center">TRUE TALLY</h1>
          <p className="text-center text-sm">Sistema de Votación Blockchain</p>
        </div>
      </header>

      <main className="max-w-4xl mx-auto p-6">
        {step === 'home' && (
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-2xl font-bold mb-2 text-center">ELECCIONES GENERALES 2026</h2>
            <p className="text-gray-600 text-center mb-6">Selecciona al candidato de tu preferencia</p>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {candidates.map((candidate) => (
                <div
                  key={candidate.id}
                  onClick={() => setSelectedCandidate(candidate.id)}
                  className={`p-4 border-2 rounded-lg cursor-pointer transition-all ${
                    selectedCandidate === candidate.id
                      ? 'border-blue-500 bg-blue-50 shadow-lg'
                      : 'border-gray-200 hover:border-blue-300 hover:bg-gray-50'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <div className={`w-10 h-10 rounded-full flex items-center justify-center font-bold text-white ${
                      selectedCandidate === candidate.id ? 'bg-blue-600' : 'bg-gray-400'
                    }`}>
                      {candidate.id}
                    </div>
                    <div>
                      <h3 className="font-semibold text-lg">{candidate.name}</h3>
                      <p className="text-blue-600 font-medium">{candidate.party}</p>
                    </div>
                  </div>
                  <p className="text-gray-600 text-sm mt-3 italic">"{candidate.proposal}"</p>
                  <div className="mt-2 text-center">
                    {selectedCandidate === candidate.id && (
                      <span className="text-blue-600 font-medium">✓ Seleccionado</span>
                    )}
                  </div>
                </div>
              ))}
            </div>

            {selectedCandidate && (
              <button
                onClick={() => setStep('vote')}
                className="mt-6 w-full bg-green-600 text-white px-6 py-4 rounded-lg text-lg font-semibold hover:bg-green-700"
              >
                CONTINUAR CON MI VOTO
              </button>
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

        {step === 'vote' && selectedCandidate && (
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-xl font-semibold mb-4 text-center">Tu candidato seleccionado</h2>
            
            {(() => {
              const cand = candidates.find(c => c.id === selectedCandidate);
              if (!cand) return null;
              return (
                <div className="p-6 border-2 border-blue-500 rounded-lg bg-blue-50 mb-6">
                  <h3 className="font-bold text-2xl text-blue-800">{cand.name}</h3>
                  <p className="text-lg text-blue-600 mb-2">{cand.party}</p>
                  <p className="text-gray-700 italic">"{cand.proposal}"</p>
                </div>
              );
            })()}
            
            <p className="text-gray-600 mb-4">
              Antes de votar, genera tu par de claves criptográficas.
              Tu clave pública te identifica como votante, y la clave privada firma tu voto.
            </p>
            
            <button
              onClick={handleGenerateKeys}
              className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700"
            >
              Generar Par de Claves
            </button>

            <button
              onClick={() => setStep('home')}
              className="ml-4 text-gray-600 hover:underline"
            >
              Cambiar
            </button>
          </div>
        )}

        {step === 'register' && keyPair && (
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
              <label className="block text-sm font-medium text-gray-700 mb-1">DNI (8 dígitos)</label>
              <input
                type="text"
                value={voterData.dni}
                onChange={(e) => {
                  const value = e.target.value.replace(/\D/g, '').slice(0, 8);
                  setVoterData({ ...voterData, dni: value });
                }}
                className="w-full p-2 border rounded"
                placeholder="Ejemplo: 12345678"
                maxLength={8}
              />
              <p className="text-xs text-gray-500 mt-1">{voterData.dni.length}/8 dígitos</p>
            </div>

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
              <label className="block text-sm font-medium text-gray-700 mb-1">Email (@gmail.com)</label>
              <input
                type="email"
                value={voterData.email}
                onChange={(e) => setVoterData({ ...voterData, email: e.target.value })}
                className={`w-full p-2 border rounded ${
                  voterData.email && !voterData.email.toLowerCase().endsWith('@gmail.com') 
                    ? 'border-red-500 bg-red-50' 
                    : ''
                }`}
                placeholder="correo@gmail.com"
              />
              {voterData.email && !voterData.email.toLowerCase().endsWith('@gmail.com') && (
                <p className="text-red-500 text-xs mt-1">Solo se permiten correos @gmail.com</p>
              )}
            </div>

            {error && (
              <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
                {error}
              </div>
            )}

            <button
              onClick={handleRegister}
              disabled={loading || !voterData.dni || !voterData.name || !voterData.email}
              className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 disabled:bg-gray-400"
            >
              {loading ? 'Registrando...' : 'Registrarse y Continuar'}
            </button>
          </div>
        )}

        {step === 'cast' && (
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-xl font-semibold mb-4">Confirma tu voto</h2>
            
            {(() => {
              const cand = candidates.find(c => c.id === selectedCandidate);
              if (!cand) return null;
              return (
                <div className="p-4 border-2 border-green-500 rounded-lg bg-green-50 mb-4">
                  <p className="text-gray-600">Votas por:</p>
                  <h3 className="font-bold text-xl">{cand.name}</h3>
                  <p className="text-green-700">{cand.party}</p>
                  <p className="text-gray-600 text-sm mt-2 italic">"{cand.proposal}"</p>
                </div>
              );
            })()}

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
              {loading ? 'Firmando y Enviando...' : 'CONFIRMAR Y ENVIAR VOTO'}
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
