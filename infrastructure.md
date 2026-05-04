# Arquitectura AWS Serverless para TrueTally - Producción (Optimizada Financieramente)

## Visión General
Este documento describe una arquitectura AWS **100% Serverless** diseñada para producción con optimización de costos. TrueTally utiliza AWS Lambda como núcleo computacional, pagando solo por el tiempo de ejecución real (milésimas de segundo), logrando costos operativos drásticamente reducidos versus infraestructura tradicional 24/7. Ideal para startups y estrategias financieras conservadoras.

## Arquitectura Serverless Event-Driven con ALB Multi-Zona

### Diagrama Arquitectónico
```
[Usuarios] → [CloudFront (CDN Global Edge)]
                ↓
        [WAF (Managed Rules)]
                ↓
[Application Load Balancer (ALB)]  ← Balanceo entre zonas
    ↓               ↓
[API Gateway Zona A] [API Gateway Zona B]  ← Regional endpoints
    ↓               ↓
[AWS Lambda A]   [AWS Lambda B]  ← Un solo Lambda por zona
    ↓               ↓
[Amazon RDS Aurora Serverless v2] ← Multi-AZ cluster
    ↓               ↓
[Amazon ElastiCache] ← Cluster mode (opcional)
    ↓
[Amazon S3] ← Storage + Lambda@Edge
    ↓
[Amazon SQS/SNS] ← Colas asíncronas (cross-zone)
    ↓
[AWS Step Functions] ← Workflows complejos
    ↓
[AWS X-Ray] ← Trazabilidad distribuida
```

## 1. Capa de Compute (Cómputo Serverless)

### 1.1 AWS Lambda (Núcleo Principal)
- **Runtimes**: Node.js 20.x (recomendado) / Python 3.12 / Java 17
- **Memoria**: 256 MB - 3008 MB (ajustable por endpoint)
- **Timeout**: 3s-15min (API Gateway límite 29s, async 15min)
- **Concurrency**:
  - Reserved: 100 (garantizados para picos)
  - Burst: 1000 (escalado automático instantáneo)
- **Cold Start Mitigation**:
  - **Provisioned Concurrency**: 5-20 funciones críticas (pago por hora)
  - **SnapStart**: Java 11+ (reducción 90% cold starts)
  - **Lambda Layers**: Dependencias pre-cargadas
- **Pricing**: $0.20 por 1M requests + $0.0000166667 por GB-segundo

### 1.2 Application Load Balancer (ALB) - Balanceo Multi-Zona
- **Tipo**: Application Load Balancer
- **Scheme**: Internet-facing
- **Cross-Zone Load Balancing**: Habilitado
- **Precio**: ~$16.43/mes + $0.008/LCU-hora
- **Zonas**: 2 Availability Zones (us-east-1a, us-east-1b)
- **Target Groups**: Uno por zona conceptual (API Gateway endpoints)

**Configuración del ALB:**
```json
{
  "LoadBalancerName": "truetally-main-alb",
  "Type": "application",
  "Scheme": "internet-facing",
  "IpAddressType": "ipv4",
  "Subnets": [
    "subnet-public-a",
    "subnet-public-b"
  ],
  "SecurityGroups": [
    "sg-alb-public"
  ],
  "Listeners": [
    {
      "Protocol": "HTTPS",
      "Port": 443,
      "DefaultActions": [
        {
          "Type": "forward",
          "TargetGroupArn": "arn:aws:elasticloadbalancing:region:account:targetgroup/truetally-api-zone-a/123456789",
          "Order": 1,
          "ForwardConfig": {
            "TargetGroups": [
              {
                "TargetGroupArn": "arn:aws:elasticloadbalancing:region:account:targetgroup/truetally-api-zone-a/123456789",
                "Weight": 50
              },
              {
                "TargetGroupArn": "arn:aws:elasticloadbalancing:region:account:targetgroup/truetally-api-zone-b/123456789",
                "Weight": 50
              }
            ],
            "TargetGroupStickinessConfig": {
              "Enabled": false,
              "DurationSeconds": 3600
            }
          }
        }
      ]
    }
  ]
}
```

### 1.3 Amazon API Gateway - Regional por Zona Conceptual
- **Tipo**: HTTP API (uno por zona conceptual)
- **Precio**: $1.00 por millón requests (HTTP) vs $3.50 (REST)
- **Deployment**: Regional (no zonal, pero conceptualmente separado)
- **Features**:
  - Caching integrado (TTL configurable)
  - Rate limiting (requests/segundo por API key)
  - CORS, JWT authorizers, API keys
  - Custom domains + ACM certificates
- **Zona A Endpoints**:
  - `GET /users/{id}` → Lambda getUser (zona A)
  - `POST /transactions` → Lambda createTransaction (zona A)
- **Zona B Endpoints**:
  - `GET /users/{id}` → Lambda getUser (zona B)
  - `POST /transactions` → Lambda createTransaction (zona B)

**Nota Importante sobre ALB → API Gateway:**
API Gateway es un servicio regional público y no puede ser target directo de ALB. Para implementar el balanceo multi-zona solicitado, usaremos:

**Opción 1: ALB → Lambda Functions (Lambda as Targets)**
- ALB apunta directamente a Lambda functions
- Pierde algunas features de API Gateway (CORS, authorizers)
- Más simple y directo

**Opción 2: ALB → VPC Link → Private API Gateway**
- API Gateway configurado como privado
- VPC Link permite conectividad desde ALB
- Mantiene todas las features de API Gateway
- Más complejo pero más completo

**Implementaremos la Opción 2 para mantener API Gateway features.**

#### ¿Por qué ALB + API Gateway en Arquitectura Serverless?

**Ventajas de esta configuración:**
- **Balanceo inteligente**: ALB puede hacer routing basado en headers, path, source IP
- **Health checks avanzados**: Verificación de salud a nivel de aplicación
- **Sticky sessions**: Mantener sesión en misma zona si necesario
- **WAF integration**: Protección avanzada antes del balanceo
- **Cost-effective**: ALB es más barato que múltiples CloudFront distributions
- **Multi-zone awareness**: Conciencia de zona para latencia óptima

**Ventajas de 2 Lambdas separados:**
- **Despliegues más rápidos**: Actualizar un Lambda no afecta al otro
- **Mejor aislamiento**: Fallo en uno no impacta el otro servicio
- **Escalado independiente**: Cada Lambda escala según su carga específica
- **Debugging simplificado**: Problemas más fáciles de identificar y resolver
- **Mantenimiento sin downtime**: Updates graduales del sistema
- **Separación de responsabilidades**: Validación vs procesamiento blockchain

**Flujo de datos:**
```
Usuario → CloudFront → WAF → ALB (decide zona)
                              ↓
                    Routing Rules → Zona A o Zona B
                              ↓
                    VPC Link → API Gateway Private
                              ↓
                    Lambda Functions (procesamiento)
```

#### Configuración ALB → VPC Link → Private API Gateway

**1. API Gateway Private Configuration:**
```json
{
  "ApiId": "api-gateway-zone-a",
  "Name": "truetally-api-zone-a",
  "ProtocolType": "HTTP",
  "EndpointType": "PRIVATE",
  "VpcEndpointIds": ["vpce-api-gateway-zone-a"],
  "Policy": {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": "execute-api:Invoke",
        "Resource": "arn:aws:execute-api:region:account:api-gateway-zone-a/*",
        "Condition": {
          "StringEquals": {
            "aws:sourceVpce": "vpce-api-gateway-zone-a"
          }
        }
      }
    ]
  }
}
```

**2. VPC Endpoints (uno por zona conceptual):**
```json
{
  "VpcEndpointType": "Interface",
  "VpcId": "vpc-truetally",
  "ServiceName": "com.amazonaws.region.execute-api",
  "SubnetIds": ["subnet-private-zone-a"],
  "SecurityGroupIds": ["sg-vpc-endpoint"],
  "PrivateDnsEnabled": true
}
```

**3. VPC Link Configuration:**
```json
{
  "Name": "vpc-link-zone-a",
  "Description": "VPC Link for API Gateway Zone A",
  "TargetArns": [
    "arn:aws:elasticloadbalancing:region:account:vpce/vpce-api-gateway-zone-a"
  ]
}
```

**4. ALB Target Groups (Lambda as Targets - Fallback):**
```json
{
  "TargetGroupName": "truetally-lambda-zone-a",
  "Protocol": "HTTPS",
  "Port": 443,
  "VpcId": "vpc-truetally",
  "TargetType": "lambda",
  "Targets": [
    {
      "Id": "arn:aws:lambda:region:account:function:truetally-main-lambda-zone-a"
    }
  ],
  "HealthCheck": {
    "Enabled": true,
    "Protocol": "HTTPS",
    "Path": "/health",
    "Port": "443",
    "HealthyThresholdCount": 2,
    "UnhealthyThresholdCount": 2,
    "TimeoutSeconds": 5,
    "IntervalSeconds": 30
  }
}
```

**5. ALB Listener Rules (Distribución por Zona):**
```json
{
  "ListenerArn": "arn:aws:elasticloadbalancing:region:account:listener/app/truetally-main-alb/123456789/443",
  "Priority": 1,
  "Conditions": [
    {
      "Field": "path-pattern",
      "Values": ["/api/*"]
    },
    {
      "Field": "source-ip",
      "Values": ["0.0.0.0/0"]
    }
  ],
  "Actions": [
    {
      "Type": "forward",
      "TargetGroupArn": "arn:aws:elasticloadbalancing:region:account:targetgroup/truetally-api-zone-a/123456789",
      "Order": 1
    },
    {
      "Type": "forward",
      "TargetGroupArn": "arn:aws:elasticloadbalancing:region:account:targetgroup/truetally-api-zone-b/123456789",
      "Order": 2,
      "ForwardConfig": {
        "TargetGroups": [
          {
            "TargetGroupArn": "arn:aws:elasticloadbalancing:region:account:targetgroup/truetally-api-zone-a/123456789",
            "Weight": 50
          },
          {
            "TargetGroupArn": "arn:aws:elasticloadbalancing:region:account:targetgroup/truetally-api-zone-b/123456789",
            "Weight": 50
          }
        ]
      }
    }
  ]
}
```

### 1.3 Application Load Balancer (ALB) + Lambda (Alternativa)
**Sí es posible usar un ALB para disparar Lambdas**
- **Configuración**: Lambda functions como targets en Target Groups
- **Ventajas**:
  - Integración con WAF/Shield existente
  - Path-based routing avanzado
  - Sticky sessions si necesario
  - Health checks automáticos
  - Mejor para migraciones desde EC2/Containers
- **Limitaciones**:
  - Solo HTTP/HTTPS (no WebSocket como API Gateway)
  - Costo: ~$0.0225/hora + $0.008/LCU-hora (vs API Gateway más económico)
  - Menos features de API management (auth, throttling, etc.)
- **Caso de uso**: Cuando ya tienes ALB en arquitectura híbrida o necesitas routing complejo
- **Precio comparativo**: Más caro que API Gateway para APIs puras serverless

### 1.3 AWS Lambda@Edge (Opcional)
- **Uso**: Personalización en edge locations de CloudFront
- **Triggers**: Viewer request, origin request, origin response, viewer response
- **Timeout**: 5s (viewer) / 30s (origin)
- **Casos de uso**:
  - A/B testing
  - Geolocalización
  - Caché dinámico por headers
  - Bot mitigation básica

## 2. Capa de Datos (Serverless & Escalable)

### 2.1 Amazon Aurora Serverless v2 (Base de Datos Principal)
- **Modo**: PostgreSQL compatible
- **Auto-scaling**: 0.5 ACU (2GB RAM) → 128 ACUs (TB scale)
- **Escalado**: Instantáneo (segundos), sin downtime
- **Pricing**: Por segundo de uso ACU (vs instancia fija 24/7)
- **Multi-AZ**: Sí (automático, sin configuración)
- **Backups**: PITR (Point-in-Time Recovery) hasta 35 días
- **Conexión pooling**: **RDS Proxy** (obligatorio para Lambda)
  - Reduce conexiones abierta (Lambda abre/ cierra rápido)
  - Reutiliza conexiones DB
  - Mejora latencia 30-50%

### 2.2 Amazon DynamoDB (Alternativa/Complemento)
- **Tipo**: NoSQL key-value & document
- **Modo**: On-Demand (pago por request) o Provisioned
- **Precio**: $1.25 por millón requests Write, $0.25 Read
- **Características**:
  - Escala automática infinita
  - Latencia single-digit ms
  - TTL automático (expiración items)
  - Streams (triggers Lambda en cambios)
- **Uso recomendado**: Sesiones, caché, logs, eventos

### 2.3 Amazon ElastiCache Serverless (Opcional)
- **Redis compatible**, escala automático
- **Uso**: Caché distribuido, rate limiting, colas
- **Alternativa más barata**: DynamoDB DAX o CloudFront cache

## 3. Capa de Almacenamiento (Serverless)

### 3.1 Amazon S3 (Object Storage)
- **Buckets**:
  - `truetally-static`: Frontend SPA (React/Vue/Angular)
  - `truetally-uploads`: Archivos usuarios
  - `truetally-backups`: Dumps DB (S3 Glacier tiering)
- **Features**:
  - **Static Website Hosting**: + CloudFront (CDN gratis para assets)
  - **Lifecycle Rules**:
    - 30 días → S3 Standard-IA (-50% costo)
    - 90 días → S3 Glacier Instant Retrieval
    - 180 días → S3 Glacier Deep Archive (95% más barato)
  - **Event Notifications**: S3 → Lambda (procesamiento uploads)
  - **Encryption**: SSE-S3 automático o SSE-KMS

### 3.2 Amazon EFS (Opcional)
- **Serverless NFS**: Escala automático
- **Uso compartido**: Lambda acceso concurrente archivos
- **Pricing**: Por GB almacenado (no por uso)

## 4. Capa de Integración y Mensajería

### 4.1 Amazon SQS (Simple Queue Service)
- **Standard**: Alt throughput, best-effort ordering
- **FIFO**: Exactly-once processing, ordering garantizado
- **Precio**: $0.40 por millón requests
- **Uso**:
  - Decoupling Lambda (producer-consumer)
  - Dead-letter queues (DLQ) para retries
  - Delayed execution (hasta 15 minutos)

### 4.2 Amazon SNS (Simple Notification Service)
- **Pub/Sub**: Lambda → SNS → Múltiples suscriptores
- **Precio**: $0.50 por millón publishes
- **Uso**:
  - Event broadcasting
  - Email/SMS via AWS SES/SNS (notificaciones)
  - Lambda fan-out

### 4.3 Amazon EventBridge
- **Serverless Event Bus**: $1 por millón events
- **Rules**: Pattern matching → Lambda targets
- **Use cases**:
  - Scheduled Lambda (cron expressions)
  - SaaS event ingestion (Stripe, GitHub webhooks)
  - Cross-account event routing

### 4.4 AWS Step Functions
- **Serverless Workflows**: Coordinación Lambdas
- **Express Workflow**: Alt throughput, bajo costo ($1 por millón)
- **Standard**: Long-running (hasta 1 año), auditable
- **Uso**:
  - Multi-step transactions
  - Human approval steps
  - Error handling/retry logic

## 5. Capa de Red y Seguridad

### 5.1 Amazon VPC (Requerido para RDS)
- **Lambda en VPC**: NAT Gateway requerido (costo ~$35/mes + data)
- **Alternativa recomendada**:
  - RDS Proxy fuera de VPC (Lambda públicos + TLS)
  - AWS PrivateLink para acceso privado
  - O: Aurora Serverless v2 acceso público + IAM auth
- **Security Groups**: Minimal rules (Lambda → RDS puerto 5432)

### 5.2 AWS WAF (Web Application Firewall)
- **Managed Rules**:
  - Core rule set (OWASP Top 10)
  - Known bad inputs
  - Rate-based rules (anti-DDoS)
- **Costo**: $5/mes + $1 por millón requests

### 5.3 AWS Shield
- **Standard**: Gratis (DDoS L3/L4)
- **Advanced**: $3000/mes (no recomendado inicialmente)

## 6. Observabilidad Serverless

### 6.1 Amazon CloudWatch
- **Logs**: Lambda invocations (retention configurable)
- **Metrics**: Invocations, errors, duration, throttles
- **Alarms**:
  - Errors > 1%
  - Duration > P95 baseline
  - Throttles > 0 (concurrency límite)
- **Pricing**: $0.50 por GB logs ingest

### 6.2 AWS X-Ray
- **Distributed Tracing**: Lambda → RDS → S3
- **Sampling**: 1% production (costos controlados)
- **Insights**: Análisis latencia, errores

### 6.3 AWS CloudTrail
- **API calls logging**: Todos los eventos AWS
- **Governance**: Cumplimiento, auditoría

## 7. CI/CD Serverless

### 7.1 AWS SAM / Serverless Framework
- **Infrastructure as Code**: Templates declarativos
- **Deploy**: `sam deploy` o `serverless deploy`
- **Stacks**: Entornos separados (dev/staging/prod)

### 7.2 AWS CodePipeline
- **Source**: GitHub → CodeBuild → CloudFormation
- **Build**: `npm run build` + Docker layer caching
- **Deploy**: Canary (10% → 100% tráfico gradual)

### 7.3 Testing
- **Unit tests**: Jest/Mocha en pipeline
- **Integration tests**: LocalStack o AWS testing
- **Load tests**: Artillery (verificar concurrencia Lambda)

## 8. Estrategia de Costos (Financiera)

### 8.1 Modelo Serverless vs Tradicional

| Servicio | Serverless (Este modelo) | Tradicional (24/7) | Ahorro |
|----------|--------------------------|---------------------|---------|
| Compute | Por request (ms) | EC2 24/7 (~$15/mes) | 90%+ |
| Database | Aurora Serverless v2 | RDS fijo (~$100/mes) | 60-80% |
| Storage | S3 (solo lo usado) | EBS fijo (~$10/mes) | 50%+ |
| **Total estimado** | **$50-150/mes** | **$200-400/mes** | **60-75%** |

### 8.2 Casos de Uso con Costos Reales

#### Escenario: 100,000 usuarios/mes
- **Lambda**: 2M requests, 500ms avg, 512MB
  - Cost: 2M × $0.20/M + (2M × 0.5s × 0.5GB × $0.00001667) = $40 + $8.33 = **$48.33**
- **API Gateway**: 2M requests
  - Cost: 2M × $1/M = **$2.00**
- **Aurora Serverless**: 100 ACU-hours/mes
  - Cost: 100 × $0.12 = **$12.00**
- **S3 (50GB + 1M requests)**
  - Cost: $1.15 + $0.40 = **$1.55**
- **CloudWatch Logs (10GB)**
  - Cost: 10 × $0.50 = **$5.00**
- **Data Transfer (100GB)**
  - Cost: 100 × $0.09 = **$9.00**
- **CloudFront (100GB)**
  - Cost: 100 × $0.085 = **$8.50**
- **Total: ~$86/mes** (versus $250+ en EC2 tradicional)

#### Escenario: 1M usuarios/mes (Scale-up)
- **Lambda**: 20M requests → **$483** (no crece linealmente por concurrencia)
- **Aurora**: 500 ACU-hours → **$60**
- **Total: ~$650/mes** (ahorrando vs $1500+ instancias grandes)

### 8.3 Optimización de Costos

- **Right-sizing Lambda**: Memory tuning (menos memoria = más barato, pero más lento)
- **Reserved Concurrency**: Evitar sorpresas (límite duro)
- **Cold Starts**: Provisioned Concurrency solo para APIs críticas
- **Caching**: CloudFront + API Gateway cache (reduce Lambda invocations)
- **Async Processing**: SQS para operaciones no críticas
- **Log Retention**: 7-14 días (no 30+ por defecto)
- **Garbage Collection**: Eliminar Lambdas no usados

## 9. Implementación Paso a Paso (Serverless)

### Fase 1: Fundamentos (Semana 1)
1. Crear AWS Account + IAM roles (principio mínimo privilegio)
2. Setup AWS SAM CLI localmente
3. Configurar CodePipeline/GitHub Actions
4. Crear S3 buckets (estáticos + uploads)
5. CloudFront distribution (CDN)

### Fase 2: API Core + 2 Lambdas (Semana 2)
1. Crear API Gateway (HTTP API) con VPC Link
2. Implementar **Lambda 1 - Vote Validator**:
   - Validación síncrona de votos
   - Autenticación de usuarios
   - Publicación a SNS
   - Almacenamiento inicial en DynamoDB
3. Implementar **Lambda 2 - Blockchain Processor**:
   - Procesamiento asíncrono desde SQS
   - Envío de votos a nodos blockchain
   - Actualización de estado en DB
   - Manejo de errores y reintentos
4. Configurar SNS Topic y SQS Queue
5. Configurar RDS Proxy para Lambda 1
6. Desplegar Aurora Serverless v2
7. Conectar Lambda 1 → RDS (TLS + IAM auth)
8. Conectar Lambda 2 → Blockchain Nodes

### Fase 3: Features Avanzadas + Integración Lambda (Semana 3)
1. Configurar SQS para Lambda 2 (ya implementado)
2. DynamoDB para almacenamiento de votos (ya implementado)
3. EventBridge para scheduled tasks (limpieza DB, reports)
4. Step Functions para workflows complejos (si necesario)
5. WAF + Shield básico
6. Testing integración Lambda 1 → SNS → SQS → Lambda 2

### Fase 4: Observabilidad (Semana 3-4)
1. CloudWatch dashboards
2. X-Ray tracing habilitado
3. SNS alerts (Slack/Email)
4. Custom metrics (negocio)

### Fase 5: Optimización (Semana 4)
1. Load testing (Artillery)
2. Memory tuning Lambda
3. Provisioned Concurrency análisis
4. Cost Explorer review
5. Security audit

## 10. Monitoreo Clave (Serverless)

### CloudWatch Metrics Críticos
- **Lambda**:
  - `Invocations`: Crecimiento tráfico
  - `Errors`: >1% es alerta
  - `Duration`: P95 vs baseline
  - `Throttles`: >0 (necesita más concurrency)
  - `ConcurrentExecutions`: Cerca del límite?
  
- **API Gateway**:
  - `4XXError`, `5XXError`
  - `Latency`: P50, P95, P99
  - `Count`: Requests/minuto

- **Aurora**:
  - `ServerlessDatabaseCapacity`: ACUs usados
  - `CPUUtilization`: >75% alerta
  - `DatabaseConnections`: Picos

### SNS Alerts (Notificaciones)
- **Critical** (PageDuty/Slack):
  - Lambda errors >5%
  - RDS failover
  - Throttling masivo
- **Warning** (Email):
  - Costos > $200/mes
  - Duration aumento 50%
  - 5XX errors >0.5%

## 11. Best Practices Serverless

### 11.1 Diseño Lambda
- **Single Responsibility**: Un Lambda = una función
- **Stateless**: Nada en /tmp salvo necesario
- **Cold starts**: Mantener <1s (menos de 1000MB ayuda)
- **Environment variables**: Configuración, no secrets
- **Layers**: Dependencias compartidas (node_modules)

### 11.2 Seguridad
- **IAM Roles**: Por Lambda (no wildcard *)
- **Secrets Manager**: DB passwords, API keys
- **VPC**: Solo si necesario (añade NAT costs)
- **Encryption**: KMS para S3, DynamoDB, RDS
- **CORS**: Configurado en API Gateway

### 11.3 Performance
- **RDS Proxy**: Obligatorio con Lambda
- **Keep-alive**: HTTP connection reuse
- **Connection pooling**: Fuera del handler
- **Async invokes**: Para operaciones no críticas
- **Batching**: Kinesis/SQS para alto volumen

### 11.4 Testing
- **Local**: `sam local`, DynamoDB Local
- **Unit**: Mocks de AWS SDK
- **Integration**: Deploy a entorno test
- **Chaos**: Simular throttling, timeouts

## 12. Limitaciones y Consideraciones

### 12.1 Limitaciones Lambda
- **Timeout**: 15 minutos (máx)
- **Memoria**: 10 GB máx
- **Package size**: 250 MB (descomprimido)
- **Concurrency**: 1000 por defecto (se puede pedir aumento)
- **Cold starts**: 100ms-2s (depende runtime, tamaño)

### 12.2 Limitaciones Aurora Serverless v2
- **Minimum**: 0.5 ACU (no pausa como v1)
- **Scaling**: Instantáneo pero no mágico (segundos)
- **Costo**: Más caro que EC2 para carga constante altísima
- **Ideal**: Carga variable (picos nocturnos, fines de semana)

### 12.3 Infraestructura Blockchain - Optimización de Costos

**¿Pueden los nodos blockchain ser AWS Lambda?**
**No, no es viable para nodos blockchain completos** debido a limitaciones fundamentales:

#### Por qué NO Lambda para Nodos Blockchain
- **Timeout límite**: Máximo 15 minutos (nodos deben correr 24/7)
- **Estado efímero**: Lambda es stateless, blockchain requiere persistencia de chain
- **Conexiones P2P**: No mantiene conexiones persistentes con otros nodos
- **Almacenamiento**: EFS posible pero caro/lento para datos blockchain
- **Cold starts**: Inaceptables para operaciones críticas de votación

#### Qué SÍ puede hacer Lambda en Blockchain
- **Light nodes** para verificación rápida de transacciones
- **Procesamiento de eventos** blockchain (triggers desde SQS/SNS)
- **Validación de votos** en tiempo real
- **Notificaciones** cuando se confirman bloques
- **API endpoints** para consultar estado blockchain

**Solución Recomendada: Arquitectura Híbrida Blockchain**

#### Opción 1: Blockchain as a Service (Más Económico)
- **Alchemy Supernode** ($49/mes): Nodos dedicados con 300M requests gratis/mes
- **Infura** ($49/mes): Infraestructura blockchain managed con 100M requests/mes
- **Moralis** ($49/mes): Web3 backend con 25M requests/mes
- **QuickNode** ($49/mes): Nodos globales con 50M requests/mes
- **Ankr** (Gratis hasta 100M requests/mes): Red distribuida

**Costo típico**: $0-99/mes vs $500+ en EC2

#### Opción 2: ECS Fargate con Auto-Scaling (Para Nodos Propios)
- **Configuración**: Nodos blockchain en contenedores Fargate con EBS persistente
- **Auto-scaling**: Mantiene 1-2 nodos siempre activos, escala para picos
- **Spot Instances**: Ahorro 70-90% para workloads tolerantes a interrupciones
- **Lambda Integration**: Lambdas procesan eventos blockchain (validaciones, notificaciones)
- **Costo estimado**: $50-200/mes (vs $800+ EC2 on-demand)

#### Opción 3: Hybrid Approach (Recomendado para TrueTally)
- **Nodo Principal**: ECS Fargate con persistencia (costo fijo mínimo)
- **Validación Lambda**: Procesamiento serverless de votos en tiempo real
- **Blockchain as a Service**: Para queries de estado/resultado elecciones
- **Storage**: Blocks/archivo en S3 Glacier ($0.004/GB/mes)
- **Event Processing**: SQS → Lambda para confirmaciones de bloques

#### Opción 4: Light Nodes + Full Nodes Selectivos
- **Light Nodes**: En Lambda para verificación rápida (stateless)
- **Full Nodes**: ECS Fargate para mantenimiento de chain completa
- **Archive Nodes**: EC2 Spot para auditoría histórica (activados on-demand)

#### Arquitectura Recomendada para TrueTally - ALB Multi-Zona + 2 Lambdas
```
Usuario vota → CloudFront → WAF → ALB (balanceo entre zonas)
                    ↓
        ALB → VPC Link → API Gateway Zona A/B
                    ↓
            API Gateway → Lambda 1 (validación + envío a cola)
                    ↓
            Lambda 1 → SNS Topic (publicación asíncrona)
                    ↓
            SNS → SQS Queue (buffering + desacoplamiento)
                    ↓
            SQS Trigger → Lambda 2 (procesamiento blockchain)
                    ↓
            Lambda 2 → Nodo Blockchain (envío del voto)
                    ↓
            Confirmación → DynamoDB/S3 (resultados)
                    ↓
            Notificación usuario vía API Gateway
```

**Ventajas de 2 Lambdas:**
- **Despliegue más rápido**: Lambdas independientes se actualizan por separado
- **Mejor aislamiento**: Un Lambda falla no afecta al otro
- **Escalado independiente**: Cada Lambda escala según su carga
- **Mantenimiento**: Updates sin downtime completo del sistema
- **Debugging**: Problemas más fáciles de identificar

#### Configuración ALB + VPC Link + API Gateway + 2 Lambdas

**ALB Configuration (Mismo que antes):**
```json
{
  "LoadBalancerName": "truetally-main-alb",
  "Type": "application",
  "Scheme": "internet-facing",
  "Subnets": ["subnet-public-a", "subnet-public-b"],
  "SecurityGroups": ["sg-alb-public"],
  "Listeners": [{
    "Protocol": "HTTPS",
    "Port": 443,
    "DefaultActions": [{
      "Type": "forward",
      "ForwardConfig": {
        "TargetGroups": [
          {"TargetGroupArn": "arn:aws:elasticloadbalancing:...:truetally-api-zone-a", "Weight": 50},
          {"TargetGroupArn": "arn:aws:elasticloadbalancing:...:truetally-api-zone-b", "Weight": 50}
        ]
      }
    }]
  }]
}
```

**API Gateway Private Integration (Lambda 1 - Validator):**
```json
{
  "ApiId": "api-gateway-zone-a",
  "EndpointType": "PRIVATE",
  "VpcEndpointIds": ["vpce-api-gateway-zone-a"],
  "Integration": {
    "Type": "AWS_PROXY",
    "HttpMethod": "POST",
    "Uri": "arn:aws:apigateway:region:lambda:path/2015-03-31/functions/arn:aws:lambda:region:account:function:truetally-lambda-vote-validator/invocations",
    "ConnectionType": "VPC_LINK",
    "ConnectionId": "vpc-link-zone-a"
  }
}
```

**SNS Topic Configuration (Para desacoplamiento):**
```json
{
  "TopicName": "truetally-vote-events",
  "DisplayName": "TrueTally Vote Processing Events",
  "Attributes": {
    "DeliveryPolicy": "{\"healthyRetryPolicy\":{\"numRetries\":3}}"
  }
}
```

**SQS Queue Configuration (Buffering asíncrono):**
```json
{
  "QueueName": "truetally-vote-processing-queue",
  "Attributes": {
    "VisibilityTimeout": "300",
    "MessageRetentionPeriod": "345600",
    "ReceiveMessageWaitTimeSeconds": "20",
    "DelaySeconds": "0",
    "RedrivePolicy": "{\"deadLetterTargetArn\":\"arn:aws:sqs:region:account:truetally-vote-processing-dlq\",\"maxReceiveCount\":\"3\"}"
  }
}
```

**SQS Subscription to SNS:**
```json
{
  "TopicArn": "arn:aws:sns:region:account:truetally-vote-events",
  "Protocol": "sqs",
  "Endpoint": "arn:aws:sqs:region:account:truetally-vote-processing-queue"
}
```

**Lambda 1 Event Source Mapping (API Gateway - Directo):**
- **Trigger**: API Gateway (HTTP API)
- **Function**: `truetally-lambda-vote-validator`
- **Timeout**: 30 segundos
- **Memory**: 256 MB (suficiente para validación)

**Lambda 2 Event Source Mapping (SQS Trigger):**
```json
{
  "FunctionName": "truetally-lambda-blockchain-processor",
  "EventSourceArn": "arn:aws:sqs:region:account:truetally-vote-processing-queue",
  "Enabled": true,
  "BatchSize": 1,
  "MaximumBatchingWindowInSeconds": 0
}
```

**Dead Letter Queue (DLQ) Configuration:**
```json
{
  "QueueName": "truetally-vote-processing-dlq",
  "Attributes": {
    "MessageRetentionPeriod": "1209600" // 14 días
  }
}
```

**VPC Link Configuration:**
```json
{
  "Name": "vpc-link-zone-a",
  "TargetArns": ["arn:aws:elasticloadbalancing:...:vpce/api-gateway-zone-a"]
}
```

**API Gateway Private Integration:**
```json
{
  "ApiId": "api-gateway-zone-a",
  "EndpointType": "PRIVATE",
  "VpcEndpointIds": ["vpce-api-gateway-zone-a"],
  "Integration": {
    "Type": "AWS_PROXY",
    "HttpMethod": "POST",
    "Uri": "arn:aws:apigateway:region:lambda:path/2015-03-31/functions/arn:aws:lambda:region:account:function:truetally-main-lambda/invocations",
    "ConnectionType": "VPC_LINK",
    "ConnectionId": "vpc-link-zone-a"
  }
}
```

#### Configuración SNS + SQS para Auto-Invocación

**SNS Topic Configuration:**
```json
{
  "TopicName": "truetally-vote-processing",
  "DisplayName": "TrueTally Vote Processing Topic",
  "Attributes": {
    "DeliveryPolicy": "{\"healthyRetryPolicy\":{\"numRetries\":3}}"
  }
}
```

**SQS Queue Configuration (Standard Queue):**
```json
{
  "QueueName": "truetally-vote-queue",
  "Attributes": {
    "VisibilityTimeout": "300",
    "MessageRetentionPeriod": "345600",
    "ReceiveMessageWaitTimeSeconds": "20",
    "DelaySeconds": "0",
    "RedrivePolicy": "{\"deadLetterTargetArn\":\"arn:aws:sqs:region:account:truetally-vote-dlq\",\"maxReceiveCount\":\"3\"}"
  }
}
```

**SQS Subscription to SNS:**
```json
{
  "TopicArn": "arn:aws:sns:region:account:truetally-vote-processing",
  "Protocol": "sqs",
  "Endpoint": "arn:aws:sqs:region:account:truetally-vote-queue"
}
```

**Lambda Event Source Mapping (SQS Trigger):**
```json
{
  "FunctionName": "truetally-main-lambda",
  "EventSourceArn": "arn:aws:sqs:region:account:truetally-vote-queue",
  "Enabled": true,
  "BatchSize": 1,
  "MaximumBatchingWindowInSeconds": 0
}
```

#### Estrategia de Costos Optimizada para TrueTally
```
Blockchain Operations Cost Breakdown:
├── Blockchain as a Service → $0-99/mes (lectura/escritura principal)
├── ECS Fargate Node → $30-80/mes (1-2 instancias pequeñas)
├── ALB → $16-30/mes (Application Load Balancer 2 AZs)
├── VPC Link → $7/mes (VPC endpoint charges)
├── Lambda 1 (Validator) → $5-20/mes (validación síncrona, bajo uso)
├── Lambda 2 (Blockchain) → $5-20/mes (procesamiento asíncrono, alto uso)
├── SNS → $1-5/mes (mensajes entre lambdas)
├── SQS → $0.50/mes (cola de mensajes)
├── Storage (Blocks) → $5-20/mes (S3 Glacier)
└── Monitoring → $10-30/mes (CloudWatch)
Total: $55-269/mes (vs $1000+ en EC2 tradicional)
```

### 12.4 Cuando NO usar Serverless
- **Carga constante 24/7 altísima** (>50% uso EC2)
- **Procesos largos** (>15 min continuos)
- **Aplicaciones monolíticas** grandes (mejor microservicios)
- **Requerimientos hardware especial** (GPU, etc.)
- **Nodos blockchain full-time** (usar BaaS en lugar de EC2)

TrueTally es ideal para serverless: picos de uso (horarios laborales), operaciones rápidas (<5s), escalado bajo demanda.

## 13. Roadmap de Evolución

### Mes 1-3: Serverless Básico
- API Gateway + Lambda + Aurora Serverless v2
- S3 + CloudFront
- Monitoreo básico

### Mes 4-6: Optimización
- DynamoDB para sesiones/caché
- SQS para async
- Provisioned Concurrency análisis

### Mes 7-12: Madurez
- Multi-region DR (Route 53 failover)
- Step Functions workflows
- Machine Learning (SageMaker serverless)

## 14. Resumen Financiero

**Inversión inicial**: $0 (nivel gratuito cubre primeros 12 meses para tráfico bajo)

**Mes 1-6 (crecimiento)**: $80-185/mes (ALB + VPC Link + 2 Lambdas)
**Mes 7-12 (scale)**: $180-440/mes (alta disponibilidad multi-zona)
**Año 1 promedio**: ~$235/mes

**Vs. Arquitectura sin ALB**: +$20-30/mes por balanceo inteligente
**Vs. Un solo Lambda**: +$5-10/mes por separación de responsabilidades

### Implementación ALB Multi-Zona - Guía Paso a Paso

#### Fase 1: Preparación de Red
1. Crear VPC con subnets públicas en 2 AZs
2. Configurar Security Groups para ALB
3. Crear VPC Endpoints para API Gateway
4. Configurar ACM certificates para HTTPS

#### Fase 2: API Gateway Private
1. Crear API Gateway tipo PRIVATE
2. Configurar VPC Link por zona conceptual
3. Crear integrations con Lambda functions
4. Configurar authorizers y CORS

#### Fase 3: Application Load Balancer
1. Crear ALB internet-facing
2. Configurar listeners HTTPS
3. Crear Target Groups (uno por zona)
4. Configurar routing rules con pesos 50/50

#### Fase 4: Integración WAF
1. Crear WebACL con reglas managed
2. Asociar WAF con ALB
3. Configurar rate limiting
4. Testing de protección DDoS

#### Fase 5: Testing y Monitoreo
1. Validar balanceo entre zonas
2. Testing de failover (deshabilitar zona)
3. Configurar CloudWatch monitoring
4. Setup alerts para latencia y errores

El modelo serverless paga solo el éxito (tráfico real), sin costos fijos de infraestructura ociosa. Ideal para startups y estrategias de capital eficiente.

## 15. Herramientas Recomendadas

### Infrastructure as Code
- **AWS SAM**: Serverless Application Model
- **Serverless Framework**: Framework específico serverless
- **Terraform**: Multi-cloud support

### CI/CD
- **GitHub Actions**: Pipeline gratuito
- **AWS CodePipeline**: Integración nativa
- **AWS Amplify**: Full-stack deployments

### Monitoring
- **CloudWatch**: Nativo AWS
- **New Relic**: APM avanzado
- **Datadog**: Enterprise monitoring

### Testing
- **Artillery**: Load testing serverless
- **LocalStack**: Local AWS testing
- **AWS Testing Tools**: SAM CLI testing

## 17. Consideraciones de Costos (Producción)

### Estimación Mensual (Producción)
| Servicio | Uso Estimado | Costo USD |
|----------|--------------|-----------|
| ALB | 2 AZs | $22 |
| ECS Fargate | 730 hrs x 4 tasks | $120 |
| Aurora PostgreSQL | Multi-AZ + replicas | $200 |
| ElastiCache Redis | Multi-AZ cluster | $150 |
| CloudFront | 100GB transfer | $50 |
| S3 Storage | 1TB Standard | $25 |
| Data Transfer | 500GB | $45 |
| WAF + Shield | Advanced protection | $100 |
| CloudWatch | Logs + Metrics | $80 |
| **Total** | | **~$770/mes** |

*Nota: Optimizable con Reserved Instances y Savings Plans*

## 16. Infraestructura de Nodos Blockchain

### 16.1 Arquitectura de Nodos Recomendada

#### Diagrama de Nodos Blockchain con P2P Sync + 2 Lambdas
```
[Usuarios] → [API Gateway] → [Lambda 1: Validación]
                ↓
    [Lambda 1] → SNS Topic → SQS Queue → [Lambda 2: Blockchain]
                ↓                           ↓
    [DynamoDB/S3] ← Results storage     [Nodo Blockchain]
                ↓                           ↓
[ECS Fargate Cluster] ← Persistent nodes
    ↓               ↓
[Blockchain Node A] ⇄ [Blockchain Node B] ← P2P Sync Multi-Zona
    ↓               ↓          ↗️        ↖️
[EBS Volumes]     [EBS Volumes]    Blocks sync
    ↓               ↓
[S3 Glacier] ← Archive storage for old blocks

Lambda 1: Validación síncrona + envío asíncrono
Lambda 2: Procesamiento blockchain + confirmación

P2P Communication Flow:
- TCP 30333: Libp2p/Kademlia protocol
- TCP 30334: WebSocket P2P
- Auto-discovery via Cloud Map DNS
- Cross-zone sync via VPC peering
```

### 16.2 Configuración de Instancias ECS Fargate

#### Cluster Configuration
- **Cluster Name**: `truetally-blockchain-cluster`
- **Capacity Provider**: FARGATE + FARGATE_SPOT
- **Networking**: VPC privada con NAT Gateway

#### Task Definition para Blockchain Node
```json
{
  "family": "truetally-blockchain-node",
  "taskRoleArn": "arn:aws:iam::ACCOUNT:role/BlockchainNodeTaskRole",
  "executionRoleArn": "arn:aws:iam::ACCOUNT:role/BlockchainNodeExecutionRole",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "1024",
  "memory": "2048",
  "containerDefinitions": [
    {
      "name": "blockchain-node",
      "image": "truetally/blockchain-node:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 9944,
          "hostPort": 9944,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "NODE_TYPE",
          "value": "validator"
        },
        {
          "name": "P2P_PORT",
          "value": "30333"
        },
        {
          "name": "RPC_PORT",
          "value": "9944"
        },
        {
          "name": "BOOTNODES",
          "value": "/dns4/blockchain-node-zone-a.truetally.local/tcp/30333/p2p/PEER_ID_ZONE_A,/dns4/blockchain-node-zone-b.truetally.local/tcp/30333/p2p/PEER_ID_ZONE_B"
        },
        {
          "name": "LISTEN_ADDR",
          "value": "/ip4/0.0.0.0/tcp/30333"
        },
        {
          "name": "PUBLIC_ADDR",
          "value": "/dns4/$(hostname).truetally.local/tcp/30333"
        },
        {
          "name": "TELEMETRY_URL",
          "value": "wss://telemetry-backend.truetally.com/submit 0"
        }
      ],
      "mountPoints": [
        {
          "sourceVolume": "blockchain-data",
          "containerPath": "/data",
          "readOnly": false
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/truetally/blockchain/nodes",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:9944/health || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3
      }
    }
  ],
  "volumes": [
    {
      "name": "blockchain-data",
      "efsVolumeConfiguration": {
        "fileSystemId": "fs-blockchain-data",
        "rootDirectory": "/",
        "transitEncryption": "ENABLED",
        "authorizationConfig": {
          "accessPointId": "fsap-blockchain",
          "iam": "ENABLED"
        }
      }
    }
  ]
}
```

#### Service Configuration
```json
{
  "cluster": "truetally-blockchain-cluster",
  "serviceName": "truetally-blockchain-service",
  "taskDefinition": "truetally-blockchain-node:1",
  "desiredCount": 2,
  "launchType": "FARGATE",
  "platformVersion": "LATEST",
  "networkConfiguration": {
    "awsvpcConfiguration": {
      "subnets": [
        "subnet-private-1",
        "subnet-private-2"
      ],
      "securityGroups": [
        "sg-blockchain-nodes"
      ],
      "assignPublicIp": "DISABLED"
    }
  },
  "loadBalancers": [
    {
      "targetGroupArn": "arn:aws:elasticloadbalancing:region:account:targetgroup/blockchain-nodes/123456789",
      "containerName": "blockchain-node",
      "containerPort": 9944
    }
  ],
  "serviceRegistries": [
    {
      "registryArn": "arn:aws:servicediscovery:region:account:service/srv-blockchain-node-a",
      "containerName": "blockchain-node",
      "containerPort": 30333
    },
    {
      "registryArn": "arn:aws:servicediscovery:region:account:service/srv-blockchain-node-b",
      "containerName": "blockchain-node",
      "containerPort": 30333
    }
  ],
  "enableECSManagedTags": true,
  "propagateTags": "SERVICE"
}
```

### 16.3 Almacenamiento para Blockchain

#### EFS para Datos Activos
- **File System**: `fs-blockchain-data`
- **Performance Mode**: General Purpose
- **Throughput Mode**: Bursting → Elastic (para escalabilidad)
- **Lifecycle Management**: Intelligent-Tiering activado
- **Encryption**: Habilitado en reposo y tránsito
- **Backup**: AWS Backup diario

#### EBS para Performance (Opcional)
- **Volume Type**: gp3 (balance costo-performance)
- **Size**: 100-500GB inicial (autoscaling habilitado)
- **IOPS**: 3000 (configurable)
- **Throughput**: 125 MB/s
- **Snapshots**: Automatizados cada 6 horas

#### S3 para Archivo Histórico
- **Bucket**: `truetally-blockchain-archive`
- **Storage Class**: Glacier Deep Archive ($0.00099/GB/mes)
- **Lifecycle Rules**:
  - Transición a Glacier después de 30 días
  - Transición a Deep Archive después de 90 días
- **Encryption**: SSE-KMS
- **Versioning**: Habilitado

### 16.4 Configuración de Red y Seguridad

#### Security Groups - P2P Sincronización Multi-Zona
```json
{
  "GroupName": "blockchain-nodes-sg",
  "Description": "Security group for blockchain nodes with P2P sync",
  "VpcId": "vpc-truetally",
  "SecurityGroupIngress": [
    {
      "IpProtocol": "tcp",
      "FromPort": 9944,
      "ToPort": 9944,
      "UserIdGroupPairs": [
        {
          "GroupId": "sg-api-gateway",
          "Description": "Allow API Gateway access to RPC"
        },
        {
          "GroupId": "sg-lambda-functions",
          "Description": "Allow Lambda functions access"
        }
      ]
    },
    {
      "IpProtocol": "tcp",
      "FromPort": 30333,
      "ToPort": 30333,
      "UserIdGroupPairs": [
        {
          "GroupId": "sg-blockchain-nodes",
          "Description": "Allow P2P communication between ALL nodes (cross-zone)"
        }
      ]
    },
    {
      "IpProtocol": "tcp",
      "FromPort": 30334,
      "ToPort": 30334,
      "UserIdGroupPairs": [
        {
          "GroupId": "sg-blockchain-nodes",
          "Description": "Allow WebSocket P2P communication"
        }
      ]
    }
  ],
  "SecurityGroupEgress": [
    {
      "IpProtocol": "-1",
      "FromPort": 0,
      "ToPort": 0,
      "Cidrs": ["0.0.0.0/0"],
      "Description": "Allow all outbound traffic for P2P discovery"
    }
  ]
}
```

#### Network Load Balancer (NLB)
- **Type**: Network Load Balancer
- **Scheme**: Internal
- **Listeners**:
  - TCP:9944 → Target Group (blockchain RPC)
  - TCP:30333 → Target Group (P2P communication)
- **Target Groups**:
  - Health checks: `/health` endpoint
  - Deregistration delay: 30 segundos

### 16.5 Service Discovery para P2P Sync

#### AWS Cloud Map Configuration
**Namespace (DNS privado):**
```json
{
  "Name": "truetally.local",
  "Description": "Private DNS namespace for blockchain P2P discovery",
  "Vpc": "vpc-truetally"
}
```

**Service para Nodo Zona A:**
```json
{
  "Name": "blockchain-node-zone-a",
  "NamespaceId": "ns-truetally-local",
  "Description": "Blockchain node service discovery for Zone A",
  "DnsConfig": {
    "NamespaceId": "ns-truetally-local",
    "DnsRecords": [
      {
        "Type": "A",
        "TTL": 60
      },
      {
        "Type": "SRV",
        "TTL": 60
      }
    ]
  },
  "HealthCheckCustomConfig": {
    "FailureThreshold": 1
  }
}
```

**Service para Nodo Zona B:**
```json
{
  "Name": "blockchain-node-zone-b",
  "NamespaceId": "ns-truetally-local",
  "Description": "Blockchain node service discovery for Zone B",
  "DnsConfig": {
    "NamespaceId": "ns-truetally-local",
    "DnsRecords": [
      {
        "Type": "A",
        "TTL": 60
      },
      {
        "Type": "SRV",
        "TTL": 60
      }
    ]
  },
  "HealthCheckCustomConfig": {
    "FailureThreshold": 1
  }
}
```

**DNS Resolution:**
```
blockchain-node-zone-a.truetally.local → 10.0.1.100 (IP del nodo A)
blockchain-node-zone-b.truetally.local → 10.0.2.200 (IP del nodo B)
```

### 16.6 Auto-Scaling y High Availability

#### ECS Service Auto Scaling
```json
{
  "AutoScalingGroupName": "truetally-blockchain-asg",
  "MinSize": 2,
  "MaxSize": 6,
  "DesiredCapacity": 2,
  "DefaultCooldown": 300,
  "AvailabilityZones": ["us-east-1a", "us-east-1b"],
  "HealthCheckType": "EC2",
  "HealthCheckGracePeriod": 300,
  "TerminationPolicies": ["OldestInstance"]
}
```

#### Scaling Policies
- **Target Tracking**: CPU > 70% → Scale out
- **Step Scaling**: Memory > 80% → Scale out
- **Scheduled Scaling**: Scale down nights/weekends

### 16.6 Monitoreo y Alerting

#### CloudWatch Metrics - P2P Sync Monitoring
- **ECS Metrics**: CPUUtilization, MemoryUtilization
- **Custom Metrics**:
  - Block height synchronization (diff between zones)
  - Transaction pool size
  - Peer connections count (debe ser >0 para sync)
  - RPC request latency
  - P2P message throughput
  - Cross-zone sync latency
- **Blockchain-specific Metrics**:
  - Finalized block height
  - Network sync status
  - Peer discovery success rate
  - Gossip protocol message count

#### CloudWatch Alarms
- **Critical**: Node down (auto-recovery)
- **Warning**: High CPU/memory usage
- **Info**: Block production rate

### 16.7 Backup y Disaster Recovery

#### Backup Strategy
- **EFS Backup**: AWS Backup diario
- **Database Backup**: Blockchain state snapshots
- **Cross-Region Replication**: S3 CRR para archive
- **RTO**: 15 minutos
- **RPO**: 1 hora

### 16.8 Costos Estimados para Nodos Blockchain

#### Configuración Mínima (Desarrollo)
| Servicio | Configuración | Costo Mensual |
|----------|---------------|---------------|
| ALB | 2 AZs | $16 |
| ECS Fargate | 1 task (1 vCPU, 2GB RAM) | $25 |
| EFS Storage | 50GB | $3 |
| NLB | 2 AZs | $15 |
| CloudWatch | Logs + Metrics | $5 |
| **Total** | | **$48/mes** |

#### Configuración de Producción
| Servicio | Configuración | Costo Mensual |
|----------|---------------|---------------|
| ALB | 2 AZs | $22 |
| ECS Fargate | 2 tasks (1 vCPU, 2GB RAM) | $50 |
| EFS Storage | 200GB | $12 |
| NLB | 2 AZs | $15 |
| S3 Archive | 1TB Glacier Deep Archive | $1 |
| CloudWatch | Enhanced monitoring | $15 |
| **Total** | | **$93/mes** |

#### Configuración Enterprise
| Servicio | Configuración | Costo Mensual |
|----------|---------------|---------------|
| ALB | 2 AZs | $22 |
| ECS Fargate | 3 tasks (2 vCPU, 4GB RAM) | $150 |
| EFS Storage | 1TB | $60 |
| NLB | 3 AZs | $25 |
| S3 Archive | 10TB Glacier | $10 |
| CloudWatch | Full observability | $30 |
| **Total** | | **$275/mes** |

*Notas: Costos incluyen NAT Gateway (~$35/mes), estimaciones para us-east-1, pueden variar por región y uso real*

### 16.9 Implementación Paso a Paso

#### Fase 1: Preparación
1. Crear VPC con subnets privadas
2. Configurar NAT Gateway
3. Crear EFS file system
4. Configurar IAM roles

#### Fase 2: ECS Cluster
1. Crear cluster ECS
2. Registrar task definition
3. Crear service con auto-scaling
4. Configurar load balancer

#### Fase 3: Storage
1. Configurar EFS access points
2. Setup S3 lifecycle rules
3. Configurar AWS Backup

#### Fase 4: Monitoreo
1. Configurar CloudWatch dashboards
2. Setup alerting rules
3. Implementar health checks

#### Fase 5: Testing y P2P Sync Validation
1. **Service Discovery Testing**:
   - Verificar DNS resolution entre zonas
   - Validar conectividad P2P ports (30333, 30334)
   - Confirmar peer discovery automático

2. **P2P Sync Testing**:
   - Validar sincronización de bloques entre zonas
   - Probar transacciones cross-zone
   - Verificar latencia de sync (<5 segundos)
   - Confirmar consensus entre nodos

3. **Failover Scenarios**:
   - Simular pérdida de conectividad zona A
   - Verificar reconexión automática
   - Validar que zona B continúa operando
   - Probar recovery cuando zona A regresa

4. **Load Testing**:
   - Stress test de transacciones
   - Validar P2P throughput
   - Monitoreo de latencia cross-zone

#### Troubleshooting P2P Sync Issues

**Problema: Nodos no se conectan**
- Verificar Security Groups permiten TCP 30333/30334
- Confirmar DNS resolution funciona
- Validar VPC peering entre zonas
- Revisar logs de peer discovery

**Problema: Sync lenta entre zonas**
- Verificar latencia de red cross-zone
- Optimizar gossip protocol settings
- Aumentar connection pool size
- Considerar dedicated sync channels

**Problema: Consensus dividido**
- Verificar NTP synchronization entre nodos
- Validar block validation rules
- Revisar fork resolution logic
- Monitor peer majority consensus

### 16.10 Integración con Arquitectura Serverless - 2 Lambdas

#### Lambda 1: Validación y Envío a Cola (API Gateway Trigger)

**Responsabilidades:**
```
1. Validación síncrona del voto
2. Autenticación del usuario
3. Almacenamiento inicial en DB
4. Publicación a SNS (no bloqueante)
5. Respuesta inmediata al usuario
```

**Implementación Lambda 1:**

```javascript
// lambda/lambda-vote-validator/index.js
const AWS = require('aws-sdk');
const sns = new AWS.SNS();
const dynamo = new AWS.DynamoDB.DocumentClient();

// Handler principal - API Gateway trigger
exports.handler = async (event) => {
  const { body, requestContext } = event;

  try {
    const voteData = JSON.parse(body);

    // 1. Validación síncrona
    const validationResult = await validateVote(voteData);
    if (!validationResult.valid) {
      return { statusCode: 400, body: JSON.stringify({ error: validationResult.error }) };
    }

    // 2. Autenticación usuario
    const userAuth = await authenticateUser(voteData.userId, voteData.token);
    if (!userAuth.valid) {
      return { statusCode: 401, body: JSON.stringify({ error: 'Authentication failed' }) };
    }

    // 3. Almacenar estado inicial en DynamoDB
    await dynamo.put({
      TableName: 'truetally-votes',
      Item: {
        voteId: voteData.id,
        userId: voteData.userId,
        status: 'pending',
        timestamp: Date.now(),
        data: voteData
      }
    }).promise();

    // 4. Publicación asíncrona a SNS (no bloqueante)
    await sns.publish({
      TopicArn: process.env.SNS_TOPIC_ARN,
      Message: JSON.stringify({
        type: 'VOTE_READY',
        voteId: voteData.id,
        userId: voteData.userId,
        voteData,
        timestamp: Date.now()
      })
    }).promise();

    // 5. Respuesta inmediata al usuario
    return {
      statusCode: 202,
      body: JSON.stringify({
        message: 'Vote accepted for processing',
        voteId: voteData.id,
        status: 'processing'
      })
    };

  } catch (error) {
    console.error('Validation error:', error);
    return { statusCode: 500, body: JSON.stringify({ error: 'Internal server error' }) };
  }
};

async function validateVote(voteData) {
  // Lógica de validación (formato, campos requeridos, etc.)
  return { valid: true };
}

async function authenticateUser(userId, token) {
  // Lógica de autenticación
  return { valid: true };
}
```

#### Lambda 2: Procesamiento Blockchain (SQS Trigger)

**Responsabilidades:**
```
1. Recibir mensaje de SQS
2. Enviar voto a nodo blockchain
3. Actualizar estado en DB
4. Manejar errores y reintentos
5. Notificar confirmación
```

**Implementación Lambda 2:**

```javascript
// lambda/lambda-blockchain-processor/index.js
const AWS = require('aws-sdk');
const dynamo = new AWS.DynamoDB.DocumentClient();

// Handler SQS - Procesamiento blockchain
exports.handler = async (event) => {
  for (const record of event.Records) {
    const { body } = record;
    const message = JSON.parse(body);
    const { type, voteId, userId, voteData } = JSON.parse(message);

    if (type === 'VOTE_READY') {
      try {
        console.log(`Processing vote ${voteId} for user ${userId}`);

        // 1. Obtener URL del nodo blockchain activo
        const nodeUrl = await getActiveBlockchainNode();

        // 2. Enviar voto al nodo blockchain
        const response = await fetch(`${nodeUrl}/vote`, {
          method: 'POST',
          body: JSON.stringify(voteData),
          headers: { 'Content-Type': 'application/json' },
          timeout: 30000 // 30 segundos timeout
        });

        if (!response.ok) {
          throw new Error(`Blockchain node error: ${response.status}`);
        }

        const result = await response.json();

        // 3. Actualizar estado en DynamoDB
        await dynamo.update({
          TableName: 'truetally-votes',
          Key: { voteId },
          UpdateExpression: 'SET #status = :status, blockHash = :blockHash, confirmedAt = :confirmedAt',
          ExpressionAttributeNames: { '#status': 'status' },
          ExpressionAttributeValues: {
            ':status': 'confirmed',
            ':blockHash': result.blockHash,
            ':confirmedAt': Date.now()
          }
        }).promise();

        // 4. Notificar confirmación (opcional)
        await notifyUserConfirmation(userId, voteId, result.blockHash);

        console.log(`Vote ${voteId} confirmed in block ${result.blockHash}`);

      } catch (error) {
        console.error(`Error processing vote ${voteId}:`, error);

        // Actualizar estado a error
        await dynamo.update({
          TableName: 'truetally-votes',
          Key: { voteId },
          UpdateExpression: 'SET #status = :status, error = :error',
          ExpressionAttributeNames: { '#status': 'status' },
          ExpressionAttributeValues: {
            ':status': 'error',
            ':error': error.message
          }
        }).promise();

        // Re-lanzar error para que SQS maneje reintento/DLQ
        throw error;
      }
    }
  }
};

async function getActiveBlockchainNode() {
  // Service Discovery: obtener nodo activo de Cloud Map
  // O configuración estática con health checks
  return process.env.BLOCKCHAIN_NODE_URL || 'http://blockchain-node-zone-a.truetally.local:9944';
}

async function notifyUserConfirmation(userId, voteId, blockHash) {
  // Notificación vía WebSocket, SNS, etc.
  // Implementar según necesidades de UI
}
```

#### Event-Driven Architecture - Un Solo Lambda
```
Usuario vota → API Gateway → Lambda (validación síncrona)
                    ↓
            Lambda → SNS Topic (publicación asíncrona)
                    ↓
            SNS → SQS Queue (buffering + reintentos)
                    ↓
            SQS Trigger → Mismo Lambda (procesamiento blockchain)
                    ↓
            Lambda → Nodo Blockchain (envío del voto)
                    ↓
            Confirmación → DynamoDB/S3 (almacenamiento)
                    ↓
            Notificación usuario (opcional)
```

Esta configuración proporciona nodos blockchain persistentes y altamente disponibles mientras mantiene la eficiencia de costos y se integra perfectamente con la arquitectura serverless principal.

---

*Documento actualizado: 2026-04-29*  
*Versión: 3.1 - Arquitectura Serverless + Blockchain Nodes*