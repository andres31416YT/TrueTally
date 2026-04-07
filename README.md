# TrueTally - Sistema de Votación Blockchain

Sistema de votación electrónica basado en blockchain con interfaz web moderna.

## Requisitos Previos

- Docker y Docker Compose instalados
- al menos 4GB de RAM disponibles
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

Para eliminar también los datos de la base de datos:

```bash
docker compose down -v
```

## Servicios

| Servicio | Puerto | Descripción |
|----------|--------|-------------|
| frontend-app | 3000 | Interfaz de usuario (Next.js) |
| api-gateway | 8080 | Backend API (Rust/Axum) |
| blockchain-node | 9944 | Nodo blockchain (RPC) |
| database-aux | 5432 | PostgreSQL |

## Variables de Entorno

### Frontend (`frontend/.env`)

```env
NEXT_PUBLIC_API_URL=http://api-gateway:8080
```

### API Gateway

Las variables se configuran automáticamente en Docker Compose:

- `DATABASE_URL`: Conexión a PostgreSQL
- `NODE_RPC_URL`: URL del nodo blockchain

## Desarrollo

Para desarrollo con reinicio automático:

```bash
docker compose -f docker-compose.dev.yml up --build
```

## Solución de Problemas

### Los contenedores no inician

Verificar que los puertos no estén en uso:

```bash
docker compose down
docker compose up --build
```

### Ver logs de un servicio específico

```bash
docker compose logs api-gateway
docker compose logs blockchain-node
docker compose logs frontend-app
```

### Reiniciar un servicio sin perder datos

```bash
docker compose restart api-gateway
```

## Credenciales

| Servicio | Usuario | Contraseña |
|----------|---------|------------|
| PostgreSQL | user | pass |

## Arquitectura

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Frontend   │────▶│ API Gateway │────▶│ Blockchain  │
│ (Next.js)   │     │   (Rust)    │     │   Node      │
└─────────────┘     └─────────────┘     └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │ PostgreSQL  │
                    └─────────────┘
```
