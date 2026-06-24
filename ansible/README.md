# Ansible - Configuration Management para TrueTally

## Estructura

```
ansible/
├── playbooks/
│   └── site.yml           # Playbook principal
├── roles/
│   └── blockchain-monitoring/
│       ├── tasks/
│       ├── vars/
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
# Instalar colecciones de AWS
ansible-galaxy collection install amazon.aws
```

### Variables de entorno
```bash
export ENVIRONMENT=dev          # o prod
export AWS_REGION=us-east-1
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_ACCOUNT_ID=123456789012
```

### Ejecutar deployment completo
```bash
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --extra-vars "environment=dev"
```

### Ejecutar tags específicos
```bash
# Solo Lambdas
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --tags lambdas

# Solo ECS
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --tags ecs

# Solo frontend
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --tags frontend

# Solo validación
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --tags validate
```

## Componentes gestionados por Ansible

1. **Lambdas**: Build, empaquetado y deploy de código Rust
2. **ECS Fargate**: Actualización de task definitions y servicios
3. **Frontend**: Build de Next.js y sync a S3 + invalidación CloudFront
4. **Database**: Migraciones y seeding (si aplica)
5. **Monitoring**: Configuración de Prometheus exporter en ECS