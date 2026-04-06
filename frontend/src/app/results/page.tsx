'use client';

import { useState, useEffect } from 'react';
import { api } from '@/lib/api';
import { PieChart, Pie, Cell, BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Legend } from 'recharts';

interface Results {
  [key: string]: number;
}

const COLORS = ['#0ea5e9', '#22c55e', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899'];

export default function ResultsPage() {
  const [results, setResults] = useState<Results>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [candidates, setCandidates] = useState<Array<{ id: number; name: string; party: string }>>([]);

  useEffect(() => {
    const fetchData = async () => {
      const [resultsRes, candidatesRes] = await Promise.all([
        api.getResults(),
        api.getCandidates(),
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

    fetchData();
    const interval = setInterval(fetchData, 5000);
    return () => clearInterval(interval);
  }, []);

  const chartData = Object.entries(results).map(([candidateId, votes]) => {
    const candidate = candidates.find(c => c.id.toString() === candidateId);
    return {
      name: candidate?.name || `Candidato ${candidateId}`,
      party: candidate?.party || 'Independiente',
      votes,
    };
  });

  const totalVotes = Object.values(results).reduce((a, b) => a + b, 0);

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-xl text-gray-600">Cargando resultados...</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-primary-700 text-white p-4 shadow-lg">
        <div className="max-w-6xl mx-auto">
          <h1 className="text-2xl font-bold">TrueTally - Resultados en Tiempo Real</h1>
        </div>
      </header>

      <main className="max-w-6xl mx-auto p-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
          <div className="bg-white rounded-lg shadow-md p-6">
            <p className="text-sm text-gray-500">Total de Votos</p>
            <p className="text-3xl font-bold text-primary-600">{totalVotes}</p>
          </div>
          <div className="bg-white rounded-lg shadow-md p-6">
            <p className="text-sm text-gray-500">Candidatos</p>
            <p className="text-3xl font-bold text-green-600">{Object.keys(results).length}</p>
          </div>
          <div className="bg-white rounded-lg shadow-md p-6">
            <p className="text-sm text-gray-500">Estado</p>
            <p className="text-3xl font-bold text-emerald-600">✓ Activo</p>
          </div>
        </div>

        {error && (
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
            {error}
          </div>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-lg font-semibold mb-4">Distribución de Votos</h2>
            {chartData.length > 0 ? (
              <ResponsiveContainer width="100%" height={300}>
                <PieChart>
                  <Pie
                    data={chartData}
                    dataKey="votes"
                    nameKey="name"
                    cx="50%"
                    cy="50%"
                    outerRadius={100}
                    label={({ name, votes }) => `${name}: ${votes}`}
                  >
                    {chartData.map((_, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            ) : (
              <div className="text-center text-gray-500 py-12">
                No hay votos registrados
              </div>
            )}
          </div>

          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-lg font-semibold mb-4">Gráfico de Barras</h2>
            {chartData.length > 0 ? (
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={chartData}>
                  <XAxis dataKey="name" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Bar dataKey="votes" fill="#0ea5e9" name="Votos" />
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <div className="text-center text-gray-500 py-12">
                No hay votos registrados
              </div>
            )}
          </div>
        </div>

        <div className="mt-6 bg-white rounded-lg shadow-md p-6">
          <h2 className="text-lg font-semibold mb-4">Detalle por Candidato</h2>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b">
                  <th className="text-left py-2">Candidato</th>
                  <th className="text-left py-2">Partido</th>
                  <th className="text-right py-2">Votos</th>
                  <th className="text-right py-2">Porcentaje</th>
                </tr>
              </thead>
              <tbody>
                {chartData.map((item, index) => (
                  <tr key={index} className="border-b">
                    <td className="py-2">{item.name}</td>
                    <td className="py-2">{item.party}</td>
                    <td className="text-right py-2 font-mono">{item.votes}</td>
                    <td className="text-right py-2">
                      {totalVotes > 0 ? ((item.votes / totalVotes) * 100).toFixed(1) : 0}%
                    </td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr className="font-bold">
                  <td className="py-2">Total</td>
                  <td></td>
                  <td className="text-right py-2">{totalVotes}</td>
                  <td className="text-right py-2">100%</td>
                </tr>
              </tfoot>
            </table>
          </div>
        </div>
      </main>
    </div>
  );
}