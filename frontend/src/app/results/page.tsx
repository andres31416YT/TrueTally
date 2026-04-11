'use client';

import { useState, useEffect, Suspense } from 'react';
import { api, Election } from '@/lib/api';
import { useSearchParams } from 'next/navigation';

function ResultsContent() {
  const searchParams = useSearchParams();
  const electionId = searchParams.get('election_id');
  
  const [results, setResults] = useState<Record<string, number>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [candidates, setCandidates] = useState<any[]>([]);
  const [elections, setElections] = useState<Election[]>([]);
  const [selectedElection, setSelectedElection] = useState<string>(electionId || '');

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
    const res = await api.listElections();
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

  const blankVotes = results['blank'] || 0;
  const totalVotes = Object.values(results).reduce((a, b) => a + b, 0) - blankVotes;

  const chartData = Object.entries(results).map(([candidateId, votes]) => {
    const candidate = candidates.find(c => c.id.toString() === candidateId);
    const category = candidate?.category || 'general';
    return {
      id: candidateId,
      externalId: candidate?.candidate_external_id || '',
      partyId: candidate?.party_id || '',
      name: candidate?.name || `Candidato ${candidateId}`,
      party: candidate?.party || 'Independiente',
      category: category,
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
          <label className="block text-sm font-medium mb-1">Seleccionar Elección</label>
          <select
            value={selectedElection}
            onChange={(e) => setSelectedElection(e.target.value)}
            className="w-full p-2 border rounded bg-white"
          >
            <option value="">Selecciona una elección</option>
            {elections.map((e) => (
              <option key={e.id} value={e.id}>{e.name}</option>
            ))}
          </select>
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
                      <th className="text-left py-2">ID</th>
                      <th className="text-left py-2">Candidato</th>
                      <th className="text-left py-2">Partido</th>
                      <th className="text-left py-2">Categoría</th>
                      <th className="text-right py-2">Votos</th>
                      <th className="text-right py-2">%</th>
                    </tr>
                  </thead>
                  <tbody>
                    {chartData.map((item, index) => (
                      <tr key={index} className="border-b">
                        <td className="py-2 font-mono text-xs">{item.externalId || item.id}</td>
                        <td className="py-2">{item.name}</td>
                        <td className="py-2">{item.party}</td>
                        <td className="py-2">{item.category}</td>
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
                      <td></td>
                      <td></td>
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
