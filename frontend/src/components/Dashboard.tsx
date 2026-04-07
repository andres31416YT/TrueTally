'use client';

import { useEffect, useState } from 'react';
import { api } from '@/lib/api';
import { ConnectionIndicator } from '@/components/ConnectionIndicator';

interface SystemStatus {
  apiConnected: boolean;
  blockchainConnected: boolean;
  totalVotes: number;
  totalBlocks: number;
  lastBlockTime: string | null;
  latency: number;
}

export function Dashboard() {
  const [status, setStatus] = useState<SystemStatus>({
    apiConnected: false,
    blockchainConnected: false,
    totalVotes: 0,
    totalBlocks: 0,
    lastBlockTime: null,
    latency: 0,
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const checkStatus = async () => {
    const start = Date.now();
    
    try {
      const healthResult = await api.health();
      const latency = Date.now() - start;
      
      const [blocksResult, resultsResult] = await Promise.all([
        api.getBlocks(),
        api.getResults(),
      ]);

      const totalVotes = resultsResult.success && resultsResult.data
        ? Object.values(resultsResult.data).reduce((a, b) => a + b, 0)
        : 0;

      const blocks = blocksResult.success && blocksResult.data ? blocksResult.data : [];
      const lastBlock = blocks.length > 0 ? blocks[blocks.length - 1] : null;

      setStatus({
        apiConnected: healthResult.success,
        blockchainConnected: blocksResult.success,
        totalVotes,
        totalBlocks: blocks.length,
        lastBlockTime: lastBlock?.timestamp || null,
        latency,
      });
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error de conexión');
    }
    setLoading(false);
  };

  useEffect(() => {
    checkStatus();
    const interval = setInterval(checkStatus, 10000);
    return () => clearInterval(interval);
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Verificando conexión con la API...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="bg-white rounded-lg shadow-md p-6">
        <h2 className="text-xl font-semibold mb-4">Estado del Sistema</h2>
        
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-4">
            <p className="text-red-700">Error: {error}</p>
          </div>
        )}

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="p-4 border rounded-lg">
            <p className="text-sm text-gray-500 mb-1">API Gateway</p>
            <ConnectionIndicator 
              status={{ 
                isConnected: status.apiConnected,
                latency: status.latency,
                lastChecked: new Date()
              }} 
              showDetails 
            />
          </div>

          <div className="p-4 border rounded-lg">
            <p className="text-sm text-gray-500 mb-1">Blockchain</p>
            <ConnectionIndicator 
              status={{ 
                isConnected: status.blockchainConnected,
                lastChecked: new Date()
              }} 
            />
          </div>

          <div className="p-4 border rounded-lg">
            <p className="text-sm text-gray-500 mb-1">Total de Votos</p>
            <p className="text-2xl font-bold text-primary-600">{status.totalVotes}</p>
          </div>

          <div className="p-4 border rounded-lg">
            <p className="text-sm text-gray-500 mb-1">Bloques en Cadena</p>
            <p className="text-2xl font-bold text-green-600">{status.totalBlocks}</p>
          </div>
        </div>

        {status.lastBlockTime && (
          <p className="text-sm text-gray-500 mt-4">
            Último bloque: {new Date(status.lastBlockTime).toLocaleString('es-ES')}
          </p>
        )}
      </div>

      {!status.apiConnected && (
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <h3 className="font-medium text-yellow-800 mb-2">Advertencia de Conexión</h3>
          <p className="text-sm text-yellow-700">
            No se puede conectar con el API Gateway. Asegúrate de que el contenedor 
            <code className="bg-yellow-100 px-1 rounded">api-gateway</code> esté corriendo.
          </p>
          <p className="text-sm text-yellow-700 mt-2">
            Ejecuta: <code className="bg-yellow-100 px-1 rounded">docker compose up api-gateway</code>
          </p>
        </div>
      )}
    </div>
  );
}