# TrueTally
Sistema blockchain de votacion electrónica

Contenedor: blockchain-node (Core)
Es el motor principal. Si usan Substrate, este contenedor correrá el binario compilado de Rust. Si es propia, será su ejecutable.

Responsable: Integrante A (Engine) e Integrante B (Lógica/Pallets).

Función: Gestionar el P2P, el consenso y el almacenamiento de los bloques en disco.

Puerto: 30333 (P2P) y 9944 (WebSocket/RPC para consultas).

Contenedor: api-gateway (Backend)
Un servidor escrito en Rust (Axum/Actix) que actúa como intermediario. El frontend no debería hablar directamente con el nodo por seguridad y complejidad.

Responsable: Integrante C (Conector).

Función: Recibir los votos del usuario, validar el formato, y enviarlos al nodo. También consulta el estado de la votación para enviárselo al Front.

Puerto: 8080.

Contenedor: database-aux (PostgreSQL/Redis)
Aunque los votos están en la blockchain, necesitas una base de datos tradicional para la gestión de la aplicación web.

Responsable: Integrante C.

Función: Guardar sesiones de usuario, metadatos de candidatos (biografías, fotos) y logs de auditoría.

Puerto: 5432.

Contenedor: frontend-app (UI)
La aplicación en Next.js/React.

Responsable: Integrante D (Interface).

Función: Interfaz de usuario para votar y ver resultados.

Puerto: 3000.

Resumen de la Arquitectura en DockerContenedorImagen Base sugeridaRol del IntegranteBlockchaindebian:bookworm-slim (con binario Rust)Integrantes A y BAPI Gatewayrust:latest (o imagen optimizada)Integrante CDatabasepostgres:16-alpineIntegrante CFrontendnode:20-alpineIntegrante D