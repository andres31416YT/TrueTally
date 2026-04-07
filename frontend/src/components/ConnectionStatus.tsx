'use client';

import { Wifi, WifiOff, Loader2 } from 'lucide-react';
import { ConnectionStatus } from './useBlockchain';

interface ConnectionIndicatorProps {
  status: ConnectionStatus;
  showDetails?: boolean;
}

export function ConnectionIndicator({ status, showDetails = false }: ConnectionIndicatorProps) {
  const { isConnected, latency, lastChecked, error } = status;

  if (status.isConnected === undefined) {
    return (
      <div className="flex items-center gap-2 text-gray-500">
        <Loader2 className="w-4 h-4 animate-spin" />
        <span className="text-sm">Verificando conexión...</span>
      </div>
    );
  }

  if (isConnected) {
    return (
      <div className="flex items-center gap-2 text-green-600">
        <Wifi className="w-4 h-4" />
        <span className="text-sm font-medium">Conectado</span>
        {showDetails && latency !== undefined && (
          <span className="text-xs text-gray-500 ml-1">({latency}ms)</span>
        )}
      </div>
    );
  }

  return (
    <div className="flex items-center gap-2 text-red-600">
      <WifiOff className="w-4 h-4" />
      <span className="text-sm font-medium">Desconectado</span>
      {showDetails && error && (
        <span className="text-xs text-red-500 ml-1">- {error}</span>
      )}
    </div>
  );
}

interface ApiStatusCardProps {
  apiUrl: string;
  status: ConnectionStatus;
}

export function ApiStatusCard({ apiUrl, status }: ApiStatusCardProps) {
  return (
    <div className="bg-white rounded-lg shadow p-4 border border-gray-200">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-gray-500">Estado de Conexión</p>
          <p className="text-xs text-gray-400 font-mono mt-1">{apiUrl}</p>
        </div>
        <ConnectionIndicator status={status} showDetails />
      </div>
      {status.lastChecked && (
        <p className="text-xs text-gray-400 mt-2">
          Última verificación: {status.lastChecked.toLocaleTimeString('es-ES')}
        </p>
      )}
    </div>
  );
}