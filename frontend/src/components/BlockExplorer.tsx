'use client';

import { Block, VoteData } from '@/lib/api';
import { Search, Hash, Clock, User, CheckCircle } from 'lucide-react';
import { useState, useMemo } from 'react';

interface BlockExplorerProps {
  blocks: Block[];
  isLoading?: boolean;
  onRefresh?: () => void;
}

interface VoteDataExt extends VoteData {
  timestamp?: number;
}

export function BlockExplorer({ blocks, isLoading, onRefresh }: BlockExplorerProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [expandedBlock, setExpandedBlock] = useState<number | null>(null);

  const filteredBlocks = useMemo(() => {
    if (!searchTerm) return blocks;
    const term = searchTerm.toLowerCase();
    return blocks.filter(
      (block) =>
        block.hash.toLowerCase().includes(term) ||
        block.previous_hash.toLowerCase().includes(term) ||
        block.data.voter_public_key.toLowerCase().includes(term)
    );
  }, [blocks, searchTerm]);

  const formatHash = (hash: string, prefixLength = 8) => {
    if (hash.length <= prefixLength * 2) return hash;
    return `${hash.slice(0, prefixLength)}...${hash.slice(-prefixLength)}`;
  };

  return (
    <div className="bg-white rounded-lg shadow-md p-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6">
        <h2 className="text-xl font-semibold flex items-center gap-2">
          <Hash className="w-5 h-5 text-primary-600" />
          Explorador de Bloques
        </h2>
        
        <div className="flex items-center gap-3 w-full sm:w-auto">
          <div className="relative flex-1 sm:flex-initial">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              placeholder="Buscar por hash o votante..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-10 pr-4 py-2 border rounded-lg w-full sm:w-64 text-sm"
            />
          </div>
          {onRefresh && (
            <button
              onClick={onRefresh}
              disabled={isLoading}
              className="px-4 py-2 bg-primary-600 text-white rounded-lg text-sm hover:bg-primary-700 disabled:opacity-50"
            >
              {isLoading ? 'Actualizando...' : 'Actualizar'}
            </button>
          )}
        </div>
      </div>

      <div className="text-sm text-gray-500 mb-4">
        Total de bloques: {filteredBlocks.length}
      </div>

      {filteredBlocks.length === 0 ? (
        <div className="text-center text-gray-500 py-12">
          No hay bloques en la cadena
        </div>
      ) : (
        <div className="space-y-3">
          {filteredBlocks.map((block, index) => (
            <div
              key={block.index}
              className="border rounded-lg overflow-hidden transition-all"
            >
              <div
                className="p-4 bg-gray-50 cursor-pointer hover:bg-gray-100 flex items-center justify-between"
                onClick={() => setExpandedBlock(expandedBlock === block.index ? null : block.index)}
              >
                <div className="flex items-center gap-4">
                  <span className="font-bold text-primary-600">#{block.index}</span>
                  {index === 0 && (
                    <span className="text-xs bg-yellow-100 text-yellow-800 px-2 py-1 rounded">
                      Genesis
                    </span>
                  )}
                </div>
                
                <div className="flex items-center gap-6 text-sm">
                  <div className="flex items-center gap-1 text-gray-500">
                    <Clock className="w-3 h-3" />
                    {new Date(block.timestamp).toLocaleString('es-ES')}
                  </div>
                  <div className="hidden md:block font-mono text-xs text-gray-500">
                    {formatHash(block.hash)}
                  </div>
                </div>
              </div>

              {expandedBlock === block.index && (
                <div className="p-4 border-t bg-white">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <p className="text-xs text-gray-500 mb-1">Hash del Bloque</p>
                      <p className="font-mono text-xs bg-gray-100 p-2 rounded break-all">
                        {block.hash}
                      </p>
                    </div>
                    <div>
                      <p className="text-xs text-gray-500 mb-1">Hash Anterior</p>
                      <p className="font-mono text-xs bg-gray-100 p-2 rounded break-all">
                        {block.previous_hash}
                      </p>
                    </div>
                  </div>

                  {index > 0 && block.data && (
                    <div className="mt-4 pt-4 border-t">
                      <p className="text-sm font-medium mb-3 flex items-center gap-2">
                        <CheckCircle className="w-4 h-4 text-green-500" />
                        Datos de la Transacción
                      </p>
                      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 text-sm">
                        <div className="bg-gray-50 p-3 rounded">
                          <p className="text-xs text-gray-500 flex items-center gap-1">
                            <User className="w-3 h-3" />
                            Votante
                          </p>
                          <p className="font-mono text-xs mt-1">
                            {formatHash(block.data.voter_public_key, 16)}
                          </p>
                        </div>
                        <div className="bg-gray-50 p-3 rounded">
                          <p className="text-xs text-gray-500">Candidato ID</p>
                          <p className="font-medium mt-1">{block.data.candidate_id}</p>
                        </div>
                        <div className="bg-gray-50 p-3 rounded">
                          <p className="text-xs text-gray-500">Nonce</p>
                          <p className="font-mono mt-1">{block.nonce}</p>
                        </div>
                      </div>
                      <div className="mt-3">
                        <p className="text-xs text-gray-500 mb-1">Firma</p>
                        <p className="font-mono text-xs bg-gray-100 p-2 rounded break-all">
                          {formatHash(block.data.signature, 24)}
                        </p>
                      </div>
                    </div>
                  )}
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}