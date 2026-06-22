# Infrastructure Architecture — TrueTally

## Flow Diagram

```mermaid
flowchart TD
    subgraph Internet
        User[👤 Usuario]
    end

    subgraph AWS
        Route53[Route 53]
        CloudFront[CloudFront CDN]
        WAF[AWS WAF]
        S3[S3 Bucket<br/>Frontend Estático]
        ALB[Application Load Balancer<br/>Blockchain Node :9944]

        subgraph VPC
            direction TB

            subgraph AZ1["🟦 Availability Zone us-east-1a"]
                Subnet1Public[Subred Pública]
                Subnet1Compute[Subred Privada — Cómputo]
                Subnet1DB[Subred Privada — Database]
                Subnet1Block[Subred Privada — Blockchain]

                subgraph LambdasAZ1
                    L1Acceso[Lambda Acceso AZ1<br/>provided.al2]
                    L1Desp[Lambda Despachador AZ1<br/>provided.al2]
                    L1Proc[Lambda Procesador AZ1<br/>provided.al2]
                end

                subgraph DB_AZ1
                    RDS1[RDS PostgreSQL 15.7<br/>db.t3.micro | 20 GB]
                    Cache1[ElastiCache Redis 7.1<br/>cache.t3.micro]
                end

                subgraph Chain1
                    Fargate1[Fargate Task<br/>Blockchain Node]
                end

                Subnet1Block --- Fargate1
            end

            subgraph AZ2["🟩 Availability Zone us-east-1b"]
                Subnet2Public[Subred Pública]
                Subnet2Compute[Subred Privada — Cómputo]
                Subnet2DB[Subred Privada — Database]
                Subnet2Block[Subred Privada — Blockchain]

                subgraph LambdasAZ2
                    L2Acceso[Lambda Acceso AZ2<br/>provided.al2]
                    L2Desp[Lambda Despachador AZ2<br/>provided.al2]
                    L2Proc[Lambda Procesador AZ2<br/>provided.al2]
                end

                subgraph DB_AZ2
                    RDS2[RDS PostgreSQL 15.7<br/>Instancia Base de Datos]
                    Cache2[ElastiCache Redis 7.1<br/>cache.t3.micro]
                end

                subgraph Chain2
                    Fargate2[Fargate Task<br/>Blockchain Node]
                end

                Subnet2Block --- Fargate2
            end

            SQS[SQS Queue + DLQ<br/>3 reintentos]
            EFS[Elastic File System (EFS)<br/>Compartido multi-AZ]
            SecretsMgr[Secrets Manager]
            KMS[AWS KMS]
            CloudWatch[CloudWatch]
            ECR[ECR Repository]
        end
    end

    User -->|HTTPS / DNS| Route53
    Route53 -->|Alias| CloudFront
    CloudFront --> WAF
    CloudFront -.->|Contenido estático| S3
    CloudFront -->|Proxy API| ALB

    ALB -->|Tráfico| Fargate1
    ALB -->|Tráfico| Fargate2

    L1Acceso -->|Credenciales| SecretsMgr
    L2Acceso -->|Credenciales| SecretsMgr
    L1Acceso -->|Email| SES_VPC
    L2Acceso -->|Email| SES_VPC

    L1Desp -->|Emite voto| SQS
    L2Desp -->|Emite voto| SQS

    SQS -->|Recibe voto| L1Proc
    SQS -->|Recibe voto| L2Proc

    L1Proc -->|Envío voto| Fargate1
    L2Proc -->|Envío voto| Fargate2

    Fargate1 <==>|P2P Sync| Fargate2
    Fargate1 -->|Lectura/Escritura| RDS1
    Fargate2 -->|Lectura/Escritura| RDS2

    Fargate1 --- EFS
    Fargate2 --- EFS

    Cache1 -.->|Cache| RDS1
    Cache2 -.->|Cache| RDS2

    KMS -->|Encriptación| RDS1 & RDS2 & EFS & S3 & SQS
    SecretsMgr -->|Credenciales| L1Acceso & L2Acceso & L1Desp & L2Desp & L1Proc & L2Proc & Fargate1 & Fargate2
    CloudWatch -.->|Métricas/Logs| Lambdas & Fargate1 & Fargate2 & SQS & RDS & ECS
```

---

## 1. Capa de Ingreso

| Componente | Descripción |
|-------------|-------------|
| **Route 53** | DNS administrado. Recibe la solicitud del usuario hacia el dominio del sistema. |
| **CloudFront CDN** | Distribución de contenido. Sirve assets estáticos desde S3 y redirige las peticiones de API hacia el ALB. |
| **S3 Bucket** | Almacena el frontend estático (Next.js export) servido a través de CloudFront. |
| **AWS WAF** | Firewall de aplicaciones web asociado a CloudFront. Protege contra SQL injection, XSS, bots y ataques comunes (OWASP Top 10). |
| **Application Load Balancer (ALB)** | Balanceador de carga regional. Expone el servicio blockchain (ECS Fargate) sobre el puerto 9944. |

---

## 2. Red (VPC)

Topología por zona de disponibilidad, cada una contiene tres subredes privadas y una pública:

| Subred | Contenido por AZ |
|---------|-------------------|
| **Pública** | Recursos con acceso a Internet (NAT Gateway, ALB). |
| **Cómputo** | Lambdas (Acceso, Despachador, Procesador) |
| **Database** | RDS PostgreSQL, ElastiCache (Redis) |
| **Blockchain** | ECS Cluster → ECS Service → Fargate Task (Blockchain Node) |

- Las subredes de cómputo, base de datos y blockchain son **privadas**.
- Conectividad a servicios AWS gestionados (S3, Secrets Manager, SQS) por **VPC Gateway / Interface Endpoints**.
- **VPC Flow Logs** en CloudWatch para auditoría de tráfico de red.

---

## 3. Servicio de Cómputo (Lambdas)

Por cada AZ existen **tres Lambdas** funcionales (Acceso, Despachador, Procesador). En el despliegue operativo se instancian por zona (`-az1`, `-az2`), totalizando **6 Lambdas** en ejecución.

| Lambda | Función | Acciones |
|---------|----------|---------|
| **Acceso** | Autenticación y gestión de cuentas | Registro, login, validación de identidad. Se conecta a **SES** a través de VPC Endpoint para envío de correos. |
| **Despachador** | Orquestación del voto | Recibe la solicitud de voto, la valida y la deposita en **SQS Queue**. |
| **Procesador** | Ejecutor del voto en blockchain | Recibe mensajes desde SQS y envía el voto al nodo blockchain por gRPC/REST. |

- Runtime: `provided.al2` (Rust compilado como binary).
- Cada Lambda tiene su propio **IAM Role con mínimo privilegio**.
- Usan **Secrets Manager** para obtener credenciales de base de datos y servicios.
- Política de reserva: `reserved_concurrency: 5` por función.
- Escalonan dentro de las subredes privadas de cómputo.

---

## 4. Capa de Mensajería

| Componente | Descripción |
|-------------|-------------|
| **SQS Queue** | Cola estándar entre Lambda Despachador y Lambda Procesador. Desacopla la emisión del voto de su procesamiento. |
| **DLQ** | Cola de mensajes muertos asociada. Máximo **3 reintentos** antes de enviar el mensaje fallido a la DLQ. |

---

## 5. Capa de Datos

| Componente | Descripción |
|-------------|-------------|
| **RDS PostgreSQL 15.7** | Motor de base de datos principal. Instancia `db.t3.micro`, 20 GB, almacenamiento SSD (gp2 por defecto). Cifrado en reposo mediante **KMS**. Base de datos: `truetally`. |
| **ElastiCache Redis 7.1** | Caché de lectura frente a PostgreSQL para reducir la latencia en consultas repetitivas. Nodo `cache.t3.micro`. |
| **Elastic File System (EFS)** | Sistema de archivos elástico compartido entre AZs. Cada Fargate Task monta el volumen EFS para persistir datos locales del nodo blockchain. |
| **Encriptación** | Todos los datos en reposo son encriptados mediante **AWS KMS**. |

> **Nota:** No se utiliza RDS Proxy ni Aurora Serverless v2 en la versión actual del código Terraform. La base de datos se accede directamente desde las Lambdas y ECS mediante credenciales obtenidas de Secrets Manager.

---

## 6. Capa Blockchain (ECS Fargate)

| Componente | Descripción |
|-------------|-------------|
| **ECS Cluster** | Cluster denominado `truetally-dev-blockchain-cluster` / `truetally-prod-blockchain-cluster`. Administra la capacidad de cómputo blockchain. |
| **ECS Service** | Servicio `truetally-dev-blockchain-service` / `truetally-prod-blockchain-service`. Mantiene la tarea deseada en ejecución continua. |
| **Fargate Task** | Tarea `Blockchain Node`. Ejecuta la imagen Docker del nodo blockchain (peer) desde **ECR**. Sin gestión de servidores. CPU 512 / Memoria 1024. |
| **EFS** | Cada task Fargate monta el volumen EFS (`/data`) para persistir datos locales del nodo. |
| **Comunicación** | Los nodos blockchain de us-east-1a y us-east-1b se sincronizan mediante protocolo **P2P síncrono**. Si un nodo cae, el otro mantiene la continuidad y capacidad de consenso. |

---

## 7. Seguridad

| Capa | Mecanismo |
|-------|-----------|
| **Red** | Subredes privadas, VPC Endpoints (S3, SQS, Secrets Manager), sin NAT Gateway para tráfico gestionado. |
| **Identidad** | IAM Roles con mínimo privilegio por componente. No se usan accesos estáticos. |
| **Encriptación** | KMS para encriptación en tránsito y en reposo (RDS, EFS, S3, SQS). |
| **Credenciales** | AWS Secrets Manager almacena contraseñas, claves API y conexiones a base de datos. |
| **WAF** | Reglas managed para protección OWASP Top 10 y rate limiting contra abuso. |
| **Auditoría** | CloudWatch Logs con retención configurada. VPC Flow Logs habilitados. |

---

## 8. Escalabilidad y Disponibilidad

- **2 Availability Zones** en **us-east-1**. Todo el tráfico de usuarios se balancea entre ambas AZs.
- **Lambdas**: Hasta **5 instancias reservadas** por función. Escalonamiento automático según demanda.
- **ECS Fargate**: Escalado automático por service según métricas de CPU y memoria.
- **P2P Blockchain**: Sincronización síncrona entre nodos de ambas AZs — alta disponibilidad y consenso resiliente.

---

## 9. Monitoreo y Observabilidad

| Servicio | Uso |
|----------|-----|
| **Amazon CloudWatch** | Métricas, alarmas y logs de Lambdas, ECS, RDS, SQS, VPC. Dashboards por componente. |
| **AWS X-Ray** | Trazabilidad distribuida de extremo a extremo (configurado en la arquitectura). |
| **SonarQube (Cloud)** | Análisis estático de código en pipeline. |
| **Checkov** | Escaneo de seguridad en infraestructura Terraform en pipeline. |

---

## 10. Región

- **Región principal**: `us-east-1`
- **Zonas de disponibilidad**: `us-east-1a`, `us-east-1b`

---

## 11. Pipeline CI/CD

- **Infraestructura**: Terraform 1.9.0 con back-end remoto en S3 (`truetally-terraform-state`). Plan en PRs a `main` y `develop`; Apply automático en push a ramas correspondientes.
- **Contenedores**: ECR con escaneo automático en push.
- **Lambdas**: Compilación cruzada Rust ARM64 (`aarch64-unknown-linux-musl`). ZIPs generados en pipeline y publicados como artefactos.
- **Frontend**: Build Next.js en pipeline. Deploy a S3 + invalidación CloudFront post-deploy.
- **Orquestación**: Ansible (inventario dinámico `aws_ec2`) para despliegue operativo de ECS, Lambdas, Database y Frontend.
