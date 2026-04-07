# TrueTally - Sistema de Votación Blockchain

Sistema de votación electrónica basado en blockchain con interfaz web moderna. Construido con Next.js, Rust y tecnología blockchain personalizada.

## Características

- **Blockchain propio**: Nodo blockchain personalizado en Rust con persistencia en disco
- **Criptografía segura**: Claves públicas/privadas usando TweetNaCl (NaCl)
- **Inmutabilidad**: Todos los votos se almacenan en bloques firmados criptográficamente
- **Interfaz moderna**: Frontend Next.js 14 con TypeScript y Tailwind CSS
- **Backend Rust**: API Gateway de alto rendimiento en Axum
- **Base de datos PostgreSQL**: Almacenamiento auxiliar para voters y candidatos

## Arquitectura

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Frontend   │────▶│ API Gateway │────▶│ Blockchain  │
│ (Next.js)   │     │   (Rust)    │     │   Node      │
│   :3000     │     │   :8080     │     │   :9944     │
└─────────────┘     └─────────────┘     └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │ PostgreSQL  │
                    │   :5432     │
                    └─────────────┘
```

## Requisitos Previos

- Docker y Docker Compose instalados
- Al menos 4GB de RAM disponibles
- Puertos libres: 3000, 8080, 9944, 30333, 5432

## Inicio Rápido

### 1. Construir y ejecutar todos los servicios

```bash
docker compose up --build
```

### 2. Acceder a la aplicación

- **Frontend**: http://localhost:3000
- **API Gateway**: http://localhost:8080
- **RPC Blockchain**: http://localhost:9944
- **Base de datos**: localhost:5432

### 3. Detener los servicios

```bash
docker compose down
```

Para eliminar también los datos de la base de datos y blockchain:

```bash
docker compose down -v
```

## Servicios

| Servicio | Puerto | Descripción |
|----------|--------|-------------|
| frontend-app | 3000 | Interfaz de usuario (Next.js 14) |
| api-gateway | 8080 | Backend API (Rust/Axum) |
| blockchain-node | 9944 | Nodo blockchain (RPC) |
| blockchain-node | 30333 | Puerto P2P (reservado) |
| database-aux | 5432 | PostgreSQL 16 |

## API Endpoints

### API Gateway (Puerto 8080)

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `/health` | GET | Verificar estado del servicio |
| `/candidates` | GET | Listar candidatos |
| `/candidates` | POST | Agregar candidato |
| `/register` | POST | Registrar votante |
| `/voter` | POST | Obtener info de votante |
| `/vote` | POST | Enviar voto |
| `/results` | GET | Obtener resultados |
| `/blocks` | GET | Obtener bloques |
| `/seed` | POST | Inicializar candidatos por defecto |

### Blockchain Node (Puerto 9944)

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `/health` | GET | Verificar estado |
| `/vote` | POST | Agregar voto |
| `/blocks` | GET | Listar bloques |
| `/blocks/{index}` | GET | Obtener bloque específico |
| `/results` | GET | Obtener resultados |
| `/validate` | GET | Validar cadena |

## Uso del Sistema

### 1. Votar

1. Ve a http://localhost:3000
2. Haz clic en "Generar Par de Claves"
3. Guarda tu clave privada de forma segura
4. Ingresa tu nombre y email
5. Haz clic en "Registrarse y Continuar"
6. Selecciona tu candidato
7. Firma y envía tu voto

### 2. Ver Resultados

1. Ve a http://localhost:3000/results
2. Observa los gráficos en tiempo real
3. Los datos se actualizan cada 5 segundos

### 3. Explorar Bloques

1. Ve a http://localhost:3000/blocks
2. Explora la cadena de bloques
3. Verifica la integridad de cada bloque

## Desarrollo

### Desarrollo con reinicio automático

```bash
docker compose -f docker-compose.dev.yml up --build
```

### Ver logs de un servicio

```bash
docker compose logs api-gateway
docker compose logs blockchain-node
docker compose logs frontend-app
```

### Reiniciar sin perder datos

```bash
docker compose restart blockchain-node
```

## Variables de Entorno

### Frontend

```env
NEXT_PUBLIC_API_URL=http://api-gateway:8080
```

### API Gateway

Las variables se configuran automáticamente en Docker Compose:

- `DATABASE_URL`: postgres://user:pass@database-aux:5432/voting_db
- `NODE_RPC_URL`: http://blockchain-node:9944

## Credenciales

| Servicio | Usuario | Contraseña |
|----------|---------|------------|
| PostgreSQL | user | pass |

## Estructura del Proyecto

```
TrueTally/
├── api-rust/               # API Gateway en Rust
│   ├── src/
│   │   ├── handlers.rs    # Endpoints HTTP
│   │   ├── models.rs     # Modelos de datos
│   │   ├── db.rs         # Operaciones de base de datos
│   │   └── main.rs       # Punto de entrada
│   └── Dockerfile
├── blockchain-core/       # Nodo blockchain en Rust
│   ├── src/
│   │   ├── blockchain.rs # Implementación de blockchain
│   │   ├── block.rs      # Estructura de bloques
│   │   ├── consensus.rs  # Lógica de consenso
│   │   ├── network.rs    # Networking P2P
│   │   └── main.rs       # Punto de entrada
│   └── Dockerfile
├── frontend/             # Aplicación Next.js
│   ├── src/
│   │   ├── app/          # Páginas de Next.js
│   │   ├── components/  # Componentes React
│   │   ├── hooks/        # Custom hooks
│   │   └── lib/          # Utilidades (API, crypto)
│   └── Dockerfile
├── docker-compose.yml    # Configuración de producción
├── docker-compose.dev.yml # Configuración de desarrollo
└── README.md
```

## Solución de Problemas

### Los contenedores no inician

```bash
docker compose down
docker compose up --build
```

### Verificar estado de contenedores

```bash
docker compose ps
```

### Ver logs completos

```bash
docker compose logs --tail=100
```

### Reiniciar todos los servicios

```bash
docker compose restart
```

## Tecnologías

- **Frontend**: Next.js 14, TypeScript, Tailwind CSS, Recharts
- **Backend**: Rust, Axum, SQLx, PostgreSQL
- **Blockchain**: Implementación personalizada en Rust
- **Criptografía**: TweetNaCl (NaCl)
- **Infraestructura**: Docker, Docker Compose

## Licencia

MIT
