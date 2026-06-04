# Infrastructure Architecture — Voting System

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
        S3[S3 Bucket<br/>Sitio estático]
        ALB[Application Load Balancer]

        subgraph VPC
            direction TB

            %% ── AZ us-east-1a ──
            subgraph AZ1[""🟦 Availability Zone us-east-1a""]
                Subnet1Computo[Subred Privada — Cómputo]
                Subnet1DB[Subred Privada — Database]
                Subnet1Block[Subred Privada — Blockchain]

                subgraph LambdasAZ1
                    L1Acceso[Lambda Acceso AZ1<br/>max 5 · escala 80%]
                    L1Desp[Lambda Despachador AZ1<br/>max 5 · escala 80%]
                    L1Proc[Lambda Procesador AZ1<br/>max 5 · escala 80%]
                end

                subgraph DB_AZ1
                    RDSProxy1[RDS Proxy / Connection Pool]
                    Aurora1[Aurora Serverless v2<br/>Primaria]
                    Cache1[ElastiCache Redis]
                end

                subgraph Chain1
                    ECS1[ECS Cluster — Blockchain Cluster]
                    ECS_Svc1[ECS Service — Blockchain Service]
                    Fargate1[Fargate Task<br/>Blockchain Node]
                    EFS1["Elastic File System (EFS)"]
                end

                SQS1[SQS Queue + DLQ<br/>3 reintentos]

                Subnet1Block --- ECS1
            end

            %% ── AZ us-east-1b ──
            subgraph AZ2[""🟩 Availability Zone us-east-1b""]
                Subnet2Computo[Subred Privada — Cómputo]
                Subnet2DB[Subred Privada — Database]
                Subnet2Block[Subred Privada — Blockchain]

                subgraph LambdasAZ2
                    L2Acceso[Lambda Acceso AZ2<br/>max 5 · escala 80%]
                    L2Desp[Lambda Despachador AZ2<br/>max 5 · escala 80%]
                    L2Proc[Lambda Procesador AZ2<br/>max 5 · escala 80%]
                end

                subgraph DB_AZ2
                    RDSProxy2[RDS Proxy / Connection Pool]
                    Aurora2[Aurora Serverless v2<br/>Réplica síncrona AZ1]
                    Cache2[ElastiCache Redis]
                end

                subgraph Chain2
                    ECS2[ECS Cluster — Blockchain Cluster]
                    ECS_Svc2[ECS Service — Blockchain Service]
                    Fargate2[Fargate Task<br/>Blockchain Node]
                    EFS2["Elastic File System (EFS)
compartido entre AZ"]
                end

                SQS2[SQS Queue + DLQ<br/>3 reintentos]

                Subnet2Block --- ECS2
            end

            %% Servicios compartidos
            API_GW1[API Gateway AZ1]
            API_GW2[API Gateway AZ2]
            SES_VPC[VPC Endpoint — SES]
            SecretsMgr[Secrets Manager]
            KMS[AWS KMS<br/>Encriptación]

            subgraph Monitoring
                CloudWatch[CloudWatch]
                XRay[X-Ray]
            end

            IAM[IAM Roles Mínimo Privilegio]
        end
    end

    %% Conexiones externas
    User -->|HTTPS / DNS| Route53
    Route53 -->|Alias| CloudFront
    CloudFront --> WAF
    CloudFront -.->|Contenido estático| S3
    CloudFront -->|Proxy API| ALB

    %% Trafico balanceado
    ALB -->|Tráfico| API_GW1
    ALB -->|Tráfico| API_GW2

    %% Acceso Lambda flujo
    L1Acceso --> API_GW1
    L2Acceso --> API_GW2
    L1Acceso -->|Email (SES)| SES_VPC
    L2Acceso -->|Email (SES)| SES_VPC
    L1Acceso -->|Credenciales| SecretsMgr
    L2Acceso -->|Credenciales| SecretsMgr

    %% Despachador flujo
    L1Desp --> API_GW1 -->|Emite voto| SQS1
    L2Desp --> API_GW2 -->|Emite voto| SQS2

    %% Procesador flujo
    SQS1 -->|Recibe voto| L1Proc
    SQS2 -->|Recibe voto| L2Proc

    L1Proc -->|Envío voto| Fargate1
    L2Proc -->|Envío voto| Fargate2

    %% Blockchain Node ↔ DB
    Fargate1 -->|Lee escribe| EFS1
    Fargate2 -->|Lee escribe| EFS2
    Fargate1 -->|Leer/Escribir| RDSProxy1
    Fargate2 -->|Leer/Escribir| RDSProxy2

    %% Blockchain P2P entre AZ
    Fargate1 <==>|P2P Sync| Fargate2

    %% Replicación BD entre AZ
    Aurora1 <==>|Replicación Síncrona Intra-AZ| Aurora2

    %% Cache
    Cache1 <==>|Cache| Aurora1
    Cache2 <==>|Cache| Aurora2

    %% Seguridad / Apoyo transversal
    SecretsMgr -->|Credenciales sensibles| L1Acceso & L2Acceso & L1Desp, L2Desp & L1Proc & L2Proc & Fargate1 & Fargate2
    KMS -->|Encriptación en reposo| Aurora1 & Aurora2 & EFS1 & EFS2 & S3 & SQS1 & SQS2
    IAM -->|Roles| L1Acceso & L2Acceso & L1Desp, L2Desp & L1Proc & L2Proc & Fargate1 & Fargate2
    CloudWatch -.->|Métricas / Logs| L1Acceso & L2Acceso & L1Desp, L2Desp & L1Proc & L2Proc & Fargate1 & Fargate2 & ALB & SQS1 & SQS2 & Aurora1 & Aurora2
    XRay -.->|Trazabilidad| L1Acceso & L2Acceso & L1Desp, L2Desp & L1Proc & L2Proc & Fargate1 & Fargate2

    %% DLQ
    SQS1 -.->|Max 3 reintentos fallidos| DLQ1[Dead Letter Queue AZ1]
    SQS2 -.->|Max 3 reintentos fallidos| DLQ2[Dead Letter Queue AZ2]
```

---

## 1. Capa de Ingreso

| Componente | Descripción |
|-------------|-------------|
| **Route 53** | DNS administrado. Recibe la solicitud del usuario hacia el dominio del sistema. |
| **CloudFront CDN** | Distribución de contenido. Sirve assets estáticos desde S3 y redirige las peticiones de API hacia el ALB. |
| **S3 Bucket** | Almacena el sitio web estático (frontend) servido a través de CloudFront. |
| **AWS WAF** | Firewall de aplicaciones web asociado a CloudFront. Protege contra SQL injection, XSS, bots y ataques comunes (OWASP Top 10). |
| **Application Load Balancer (ALB)** | Balanceador de carga regional. Distribuye el tráfico entrante entre las dos AZs (us-east-1a, us-east-1b). |

---

## 2. Red (VPC)

Topología por zona de disponibilidad, cada una contiene tres subredes privadas:

| Subred | Contenido por AZ |
|---------|-------------------|
| **Cómputo** | API Gateway, Lambdas (Acceso, Despachador, Procesador) |
| **Database** | RDS Proxy, Aurora Serverless v2, ElastiCache (Redis) |
| **Blockchain** | ECS Cluster → ECS Service → Fargate Task (Blockchain Node) |

- Las subredes son **privadas**; no tienen acceso directo a Internet.
- La conectividad hacia servicios AWS gestionados (S3, SES, Secrets Manager, SQS, etc.) se realiza por **VPC Gateway Endpoints** o **VPC Interface Endpoints**, sin NAT Gateway.

---

## 3. Servicio de Cómputo (Lambdas)

Por cada AZ existen **tres Lambdas**. Máximo **5 instancias por Lambda**. Política de auto-scaling: se escala cuando la utilización alcanza el **80%**.

| Lambda | Función | Acciones |
|---------|----------|---------|
| **Acceso** | Autenticación y gestión de cuentas | Registro, login, validación de identidad. Se conecta a SES a través de un **VPC Endpoint** para envío de correos. |
| **Despachador** | Orquestación del voto | Recibe la solicitud de voto, la valida y la deposita en **SQS Queue**. |
| **Procesador** | Ejecutor del voto en blockchain | Recibe mensajes desde SQS y envía el voto a la blockchain node por gRPC/REST. |

- Cada Lambda tiene su propio **IAM Role con mínimo privilegio**.
- Usan **Secrets Manager** para obtener credenciales de base de datos y servicios.
- Toda la comunicación entre Lambdas se realiza por API Gateway o SQS. No hay invocación directa cross-Lambda.

---

## 4. Capa de Mensajería

| Componente | Descripción |
|-------------|-------------|
| **SQS Queue (x2)** | Cola estándar entre Lambda Despachador y Lambda Procesador. Una cola por AZ. Desacopla la emisión del voto de su procesamiento. |
| **DLQ (x2)** | Cola de mensajes muertos asociada a cada SQS Queue. Máximo **3 reintentos** antes de enviar el mensaje fallido a la DLQ. |

---

## 5. Capa de Datos

| Componente | Descripción |
|-------------|-------------|
| **Aurora Serverless v2** | Motor de base de datos. Instancia primaria en us-east-1a, réplica síncrona en us-east-1b para alta disponibilidad inmediata. |
| **RDS Proxy** | Pool de conexiones frente a Aurora. Reduce la cantidad de conexiones abiertas y mejora la escalabilidad de Lambdas. |
| **ElastiCache (Redis)** | Caché de lectura frente a Aurora para reducir la latencia en consultas repetitivas. |
| **** | Sistema de archivos elástico compartido. Utilizado por los nodos blockchain para persistir datos estructurados. |
| **Replicación BD** | Replicación **síncrona** (intra-región) entre instancias de Aurora en us-east-1a y us-east-1b. Replicación **asíncrona** hacia región de respaldo fuera de us-east-1 para protección contra pérdida de datos. |
| **Encriptación** | Todos los datos en reposo son encriptados mediante **AWS KMS**. |

---

## 6. Capa Blockchain (ECS Fargate)

| Componente | Descripción |
|-------------|-------------|
| **ECS Cluster** | Cluster denominado *Blockchain Cluster* por AZ. Administra la capacidad de cómputo blockchain. |
| **ECS Service** | Servicio *Blockchain Service*. Mantiene la tarea deseada en ejecución continua. |
| **Fargate Task** | Tarea *Blockchain Node*. Ejecuta la imagen Docker del nodo blockchain (peer). Sin gestión de servidores. |
| **EFS** | Cada task Fargate monta un volumen EFS para persistir datos locales del nodo. |
| **Comunicación** | Los nodos blockchain de us-east-1a y us-east-1b se sincronizan mediante protocolo **P2P síncrono**. Si un nodo cae, el otro mantiene la continuidad y capacidad de consenso. |

---

## 7. Seguridad

| Capa | Mecanismo |
|-------|-----------|
| **Red** | Subredes privadas, VPC Endpoints (SES, S3, SQS, Secrets Manager, etc.), sin NAT Gateway. |
| **Identidad** | IAM Roles con mínimo privilegio por componente. No se usan accesos estáticos. |
| **Encriptación** | KMS para encriptación en tránsito y en reposo (Aurora, EFS, S3, SQS). |
| **Credenciales** | AWS Secrets Manager almacena contraseñas, claves API y conexiones a base de datos. Rotación automática recomendada. |
| **WAF** | Reglas managed para protección OWASP Top 10 y rate limiting contra abuso. |
| **Auditoría** | X-Ray para trazabilidad de peticiones entre Lambdas, ALB y blockchain node. CloudWatch Logs con retención configurada. |

---

## 8. Escalabilidad y Disponibilidad

- **2 Availability Zones** en **us-east-1**. Todo el tráfico de usuarios se balancea entre ambas AZs.
- **Lambdas**: Cada una soporta hasta **5 instancias**. Escala al 80% de utilización.
- **Aurora Serverless v2**: Escala capacidad de cómputo y memoria automáticamente según la demanda.
- **ECS Fargate**: Escalado automático por service. La task se replica según métricas de CPU y memoria.
- **P2P Blockchain**: Sincronización síncrona entre nodos de ambas AZs — alta disponibilidad y consenso resiliente.

---

## 9. Monitoreo y Observabilidad

| Servicio | Uso |
|----------|-----|
| **Amazon CloudWatch** | Métricas, alarmas y logs de Lambdas, ALB, RDS, ECS, SQS. Dashboards por componente. |
| **AWS X-Ray** | Trazabilidad distribuida de extremo a extremo: desde la petición del usuario hasta el registro en blockchain. |

---

## 10. Región

- **Región principal**: `us-east-1`
- **Zonas de disponibilidad**: `us-east-1a`, `us-east-1b`
