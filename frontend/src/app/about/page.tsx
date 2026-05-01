export default function AboutPage() {
  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-4xl mx-auto py-12 px-4 sm:px-6 lg:px-8">
        <div className="text-center">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">
            Acerca de TrueTally
          </h1>
          <p className="text-xl text-gray-600 mb-8">
            Sistema de votación blockchain seguro y transparente
          </p>
        </div>

        <div className="bg-white shadow-lg rounded-lg p-8">
          <h2 className="text-2xl font-bold text-gray-900 mb-4">¿Qué es TrueTally?</h2>
          <p className="text-gray-700 mb-6">
            TrueTally es un sistema revolucionario de votación electrónica que utiliza tecnología blockchain
            para garantizar la integridad, transparencia y seguridad de los procesos electorales.
          </p>

          <h2 className="text-2xl font-bold text-gray-900 mb-4">Características Principales</h2>
          <ul className="list-disc list-inside text-gray-700 mb-6 space-y-2">
            <li>Votación anónima pero verificable</li>
            <li>Cadena de bloques inmutable</li>
            <li>Criptografía avanzada</li>
            <li>Prevención de doble voto</li>
            <li>Resultados en tiempo real</li>
            <li>Transparencia total del proceso</li>
          </ul>

          <h2 className="text-2xl font-bold text-gray-900 mb-4">Tecnología</h2>
          <p className="text-gray-700 mb-6">
            Utilizamos algoritmos de consenso avanzados y criptografía de curva elíptica para asegurar
            que cada voto sea único, secreto y contabilizado correctamente.
          </p>

          <div className="text-center">
            <a
              href="/"
              className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors"
            >
              Comenzar a Votar
            </a>
          </div>
        </div>
      </div>
    </div>
  );
}