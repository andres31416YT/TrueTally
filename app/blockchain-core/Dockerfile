# Multi-stage build: Rust binary in distroless image
FROM rust:1.85-alpine AS builder

RUN apk add --no-cache musl-dev openssl-dev pkgconfig

WORKDIR /app

COPY Cargo.toml ./
COPY shared ./shared
COPY lambda-acceso/Cargo.toml ./lambda-acceso/Cargo.toml
COPY lambda-despachador/Cargo.toml ./lambda-despachador/Cargo.toml
COPY lambda-procesador/Cargo.toml ./lambda-procesador/Cargo.toml
COPY blockchain-core/Cargo.toml ./blockchain-core/Cargo.toml
COPY lambda-acceso/src ./lambda-acceso/src
COPY lambda-despachador/src ./lambda-despachador/src
COPY lambda-procesador/src ./lambda-procesador/src
COPY blockchain-core/src ./blockchain-core/src

RUN cargo build --release -p blockchain-core --bin blockchain-node

# Runtime stage
FROM gcr.io/distroless/cc-debian12

COPY --from=builder /app/target/release/blockchain-node /blockchain-node

# CloudWatch agent config
ENV PORT=9944
ENV RUST_LOG=blockchain_core=info,tokio=info,axum=info,tower_http=info

EXPOSE ${PORT}

ENTRYPOINT ["/blockchain-node"]
