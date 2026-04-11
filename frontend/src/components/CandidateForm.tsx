'use client';

import { useState, useEffect } from 'react';
import { api, Election, Candidate, NewCandidate } from '@/lib/api';

interface CandidateFormProps {
  electionId: string;
  onSuccess?: () => void;
}

export default function CandidateForm({ electionId, onSuccess }: CandidateFormProps) {
  const [formData, setFormData] = useState({
    name: '',
    party: '',
    photo_url: '',
  });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(false);
  const [candidates, setCandidates] = useState<Candidate[]>([]);
  const [alert, setAlert] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const fetchCandidates = async () => {
    const result = await api.getCandidates(electionId);
    if (result.success && result.data) {
      setCandidates(result.data);
    }
  };

  useEffect(() => {
    fetchCandidates();
  }, [electionId]);

  const validateUrl = (url: string): boolean => {
    try {
      new URL(url);
      return true;
    } catch {
      return false;
    }
  };

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.name.trim()) {
      newErrors.name = 'El nombre es requerido';
    }
    if (!formData.party.trim()) {
      newErrors.party = 'El partido es requerido';
    }
    if (!formData.photo_url.trim()) {
      newErrors.photo_url = 'La URL de la foto es requerida';
    } else if (!validateUrl(formData.photo_url)) {
      newErrors.photo_url = 'La URL de la foto no es válida';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!validateForm()) {
      return;
    }

    setLoading(true);
    setAlert(null);

    const candidate: NewCandidate = {
      election_id: electionId,
      name: formData.name.trim(),
      party: formData.party.trim(),
      photo_url: formData.photo_url.trim(),
    };

    const result = await api.addCandidate(candidate);

    if (result.success) {
      setAlert({ type: 'success', message: 'Candidato registrado exitosamente' });
      setFormData({ name: '', party: '', photo_url: '' });
      fetchCandidates();
      onSuccess?.();
    } else {
      setAlert({ type: 'error', message: result.error || 'Error al registrar candidato' });
    }

    setLoading(false);
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    if (errors[name]) {
      setErrors((prev) => ({ ...prev, [name]: '' }));
    }
  };

  return (
    <div className="bg-white rounded-lg shadow-md p-6">
      <h2 className="text-xl font-bold mb-4 text-gray-800">Registrar Candidato</h2>

      {alert && (
        <div
          className={`p-4 mb-4 rounded ${
            alert.type === 'success'
              ? 'bg-green-100 border border-green-400 text-green-700'
              : 'bg-red-100 border border-red-400 text-red-700'
          }`}
        >
          {alert.message}
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-1">
            Nombre del Candidato
          </label>
          <input
            type="text"
            id="name"
            name="name"
            value={formData.name}
            onChange={handleInputChange}
            className={`w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent ${
              errors.name ? 'border-red-500' : 'border-gray-300'
            }`}
            placeholder="Ingrese el nombre completo"
            disabled={loading}
          />
          {errors.name && <p className="text-red-500 text-sm mt-1">{errors.name}</p>}
        </div>

        <div>
          <label htmlFor="party" className="block text-sm font-medium text-gray-700 mb-1">
            Partido Político
          </label>
          <input
            type="text"
            id="party"
            name="party"
            value={formData.party}
            onChange={handleInputChange}
            className={`w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent ${
              errors.party ? 'border-red-500' : 'border-gray-300'
            }`}
            placeholder="Ingrese el nombre del partido"
            disabled={loading}
          />
          {errors.party && <p className="text-red-500 text-sm mt-1">{errors.party}</p>}
        </div>

        <div>
          <label htmlFor="photo_url" className="block text-sm font-medium text-gray-700 mb-1">
            URL de la Foto
          </label>
          <input
            type="url"
            id="photo_url"
            name="photo_url"
            value={formData.photo_url}
            onChange={handleInputChange}
            className={`w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent ${
              errors.photo_url ? 'border-red-500' : 'border-gray-300'
            }`}
            placeholder="https://ejemplo.com/foto.jpg"
            disabled={loading}
          />
          {errors.photo_url && <p className="text-red-500 text-sm mt-1">{errors.photo_url}</p>}
        </div>

        <button
          type="submit"
          disabled={loading}
          className="w-full bg-primary-600 text-white py-2 px-4 rounded-lg hover:bg-primary-700 focus:ring-2 focus:ring-primary-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
        >
          {loading ? 'Registrando...' : 'Registrar Candidato'}
        </button>
      </form>

      {candidates.length > 0 && (
        <div className="mt-6">
          <h3 className="text-lg font-semibold mb-3 text-gray-800">Candidatos Registrados</h3>
          <div className="space-y-3">
            {candidates.map((candidate) => (
              <div key={candidate.id} className="flex items-center p-3 bg-gray-50 rounded-lg">
                {candidate.photo_url && (
                  <img
                    src={candidate.photo_url}
                    alt={candidate.name}
                    className="w-12 h-12 rounded-full object-cover mr-3"
                    onError={(e) => {
                      (e.target as HTMLImageElement).src = 'https://via.placeholder.com/48';
                    }}
                  />
                )}
                <div>
                  <p className="font-medium text-gray-800">{candidate.name}</p>
                  <p className="text-sm text-gray-600">{candidate.category}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}