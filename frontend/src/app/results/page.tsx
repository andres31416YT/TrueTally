'use client';

import { useState, useEffect, Suspense } from 'react';
import { api, Election, Candidate } from '@/lib/api';
import { useSearchParams } from 'next/navigation';

function ResultsContent() {
  const searchParams = useSearchParams();
  const electionId = searchParams.get('election_id');
  
  const [results, setResults] = useState<Record<string, number>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [candidates, setCandidates] = useState<Candidate[]>([]);
  const [elections, setElections] = useState<Election[]>([]);
  const [selectedElection, setSelectedElection] = useState<string>(electionId || '');
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    loadElections();
  }, []);

  useEffect(() => {
    if (selectedElection) {
      loadData();
      const interval = setInterval(loadData, 5000);
      return () => clearInterval(interval);
    }
  }, [selectedElection]);

  const loadElections = async () => {
    const res = await api.listAllElections();
    if (res.success && res.data) {
      setElections(res.data);
      if (res.data.length > 0 && !selectedElection) {
        setSelectedElection(res.data[0].id);
      }
    }
  };

  const loadData = async () => {
    if (!selectedElection) return;
    
    const [resultsRes, candidatesRes] = await Promise.all([
      api.getResults(selectedElection),
      api.getCandidates(selectedElection),
    ]);

    if (resultsRes.success && resultsRes.data) {
      setResults(resultsRes.data);
    } else {
      setError(resultsRes.error || 'Failed to fetch results');
    }

    if (candidatesRes.success && candidatesRes.data) {
      setCandidates(candidatesRes.data);
    }

    setLoading(false);
  };

  const filteredElections = elections.filter(e => 
    searchTerm === '' || 
    e.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    (e.description && e.description.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  const blankVotes = results['blank'] || 0;
  const totalVotes = Object.values(results).reduce((a, b) => a + b, 0) - blankVotes;

  const chartData = Object.entries(results)
    .filter(([key]) => key !== 'blank')
    .map(([candidateId, votes]) => {
      const candidate = candidates.find(c => c.code === candidateId);
      return {
        code: candidateId,
        name: candidate?.name || `Candidato ${candidateId}`,
        votes,
      };
    });

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-xl text-gray-600">Cargando resultados...</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-blue-600 text-white p-4 shadow-lg">
        <div className="max-w-4xl mx-auto">
          <h1 className="text-2xl font-bold">Resultados - TrueTally</h1>
        </div>
      </header>

      <main className="max-w-4xl mx-auto p-6">
        <div className="mb-4">
          <div className="flex gap-2 mb-4">
            <input
              type="text"
              placeholder="Buscar elecciones..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="flex-1 p-2 border rounded"
            />
            <button
              onClick={() => {}}
              className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
            >
              Buscar
            </button>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-2 mb-4">
            {filteredElections.map((election) => (
              <div
                key={election.id}
                onClick={() => setSelectedElection(election.id)}
                className={`p-3 border-2 rounded-lg cursor-pointer transition-all ${
                  selectedElection === election.id
                    ? 'border-blue-500 bg-blue-50'
                    : 'border-gray-200 hover:border-blue-300'
                }`}
              >
                <h3 className="font-semibold">{election.name}</h3>
                <p className="text-xs text-gray-500">{election.description}</p>
                <span className={`text-xs px-2 py-0.5 rounded ${
                  election.status === 'Publicado' ? 'bg-blue-100 text-blue-700' : 'bg-gray-100 text-gray-600'
                }`}>
                  {election.status === 'Publicado' ? 'Publicado' : 'Terminado'}
                </span>
              </div>
            ))}
          </div>
        </div>

        {error && (
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
            {error}
          </div>
        )}

        {selectedElection && (
          <>
            <div className="grid grid-cols-4 gap-4 mb-6">
              <div className="bg-white rounded-lg shadow p-4">
                <p className="text-sm text-gray-500">Total de Votos</p>
                <p className="text-2xl font-bold text-blue-600">{totalVotes + blankVotes}</p>
              </div>
              <div className="bg-white rounded-lg shadow p-4">
                <p className="text-sm text-gray-500">Votos en Blanco</p>
                <p className="text-2xl font-bold text-gray-600">{blankVotes}</p>
              </div>
              <div className="bg-white rounded-lg shadow p-4">
                <p className="text-sm text-gray-500">Candidatos</p>
                <p className="text-2xl font-bold text-green-600">{candidates.length}</p>
              </div>
              <div className="bg-white rounded-lg shadow p-4">
                <p className="text-sm text-gray-500">Estado</p>
                <p className="text-2xl font-bold text-emerald-600">✓ Activo</p>
              </div>
            </div>

            <div className="bg-white rounded-lg shadow-md p-6">
              <h2 className="text-lg font-semibold mb-4">Detalle por Candidato</h2>
              {chartData.length === 0 ? (
                <p className="text-gray-500">No hay votos registrados</p>
              ) : (
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b">
                      <th className="text-left py-2">Código</th>
                      <th className="text-left py-2">Candidato</th>
                      <th className="text-right py-2">Votos</th>
                      <th className="text-right py-2">%</th>
                    </tr>
                  </thead>
                  <tbody>
                    {chartData.map((item, index) => (
                      <tr key={index} className="border-b">
                        <td className="py-2 font-mono text-xs">{item.code}</td>
                        <td className="py-2">{item.name}</td>
                        <td className="text-right py-2 font-mono">{item.votes}</td>
                        <td className="text-right py-2">
                          {totalVotes > 0 ? ((item.votes / totalVotes) * 100).toFixed(1) : 0}%
                        </td>
                      </tr>
                    ))}
                  </tbody>
                  <tfoot>
                    <tr className="font-bold">
                      <td></td>
                      <td className="py-2">Total</td>
                      <td className="text-right py-2">{totalVotes}</td>
                      <td className="text-right py-2">100%</td>
                    </tr>
                  </tfoot>
                </table>
              )}
            </div>
          </>
        )}
      </main>
    </div>
  );
}

function Loading() {
  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center">
      <div className="text-xl text-gray-600">Cargando...</div>
    </div>
  );
}

export default function ResultsPage() {
  return (
    <Suspense fallback={<Loading />}>
      <ResultsContent />
    </Suspense>
  );
}