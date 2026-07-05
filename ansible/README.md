# Ansible - Configuration Management para TrueTally

## Estructura

```
ansible/
├── playbooks/
│   └── site.yml           # Playbook principal
├── roles/
│   ├── database/          # RDS PostgreSQL, ElastiCache
│   ├── ecs/               # ECS Fargate blockchain node
│   ├── api_gateway/       # API Gateway HTTP API
│   ├── lambda/            # Lambda functions (acceso, despachador, procesador)
│   ├── frontend/          # Next.js build y S3 sync
│   ├── waf/               # WAF con reglas OWASP
│   ├── sqs_dlq/           # SQS Dead Letter Queue
│   ├── route53/           # DNS y Hosted Zone
│   ├── vpc_endpoints/     # VPC Endpoints (S3, SQS, Secrets Manager)
│   ├── vpc_flow_logs/     # VPC Flow Logs
│   ├── ses/               # SES email configuration
│   └── blockchain-monitoring/
│       ├── tasks/
│       └── meta/
├── inventory/
│   └── hosts.ini          # Inventario de componentes
├── group_vars/
│   ├── all.yml           # Variables globales
│   ├── lambda.yml        # Variables específicas de Lambda
│   └── ecs_blockchain.yml # Variables específicas de ECS
└── build.sh              # Script de build local
```

## Uso

### Prerrequisitos
```bash
ansible-galaxy collection install amazon.aws
```

### Variables de entorno
```bash
export ENVIRONMENT=dev
export AWS_REGION=us-east-1
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_ACCOUNT_ID=123456789012
```

### Ejecutar deployment completo
```bash
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --extra-vars "environment=dev"
```

### Ejecutar roles específicos
```bash
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --tags database
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --tags ecs
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --tags waf
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --tags network
```

## Componentes gestionados por Ansible

1. **Database**: RDS PostgreSQL, ElastiCache Redis, credenciales
2. **ECS**: Despliegue nodo blockchain, task definitions
3. **API Gateway**: HTTP API con integraciones Lambda
4. **Lambdas**: Configuración de timeout, memoria, variables de entorno
5. **Frontend**: Build Next.js, S3 sync, CloudFront invalidation
6. **WAF**: Protección OWASP Core Rule Set y rate limiting
7. **SQS DLQ**: Cola de mensajes muertos con redrive policy
8. **Route53**: DNS alias hacia CloudFront
9. **VPC Endpoints**: Gateway/Interface para S3, SQS, Secrets Manager
10. **VPC Flow Logs**: Auditoría de tráfico de red
11. **SES**: Configuración de email
12. **Blockchain Monitoring**: CloudWatch alarms y log groups