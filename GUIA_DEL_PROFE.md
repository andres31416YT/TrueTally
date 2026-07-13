# Guía de Pipelines CI/CD con GitHub Actions
**Infraestructura como Código · AWS · Terraform · Ansible**

> Autor: Ms. Walter Ivan Leturia Rodriguez

---

## 1. ¿Qué es un Pipeline de CI/CD?

Cuando desarrollamos software o infraestructura, realizamos tareas repetitivas: verificar que el código no tiene errores, aplicar cambios en servidores, construir imágenes Docker, etc. Hacerlas a mano es lento y propenso a equivocaciones.

Un pipeline de CI/CD automatiza esas tareas. Cada vez que alguien hace un commit o abre un Pull Request, el pipeline corre automáticamente y ejecuta los pasos que tú definas.

### 1.1 Los dos conceptos clave

| Concepto | Definición |
|----------|------------|
| **CI** — Integración Continua | Automatizar la validación del código: pruebas, linting, análisis estático. El objetivo es detectar errores temprano, antes de que lleguen a producción. |
| **CD** — Entrega/Despliegue Continuo | Automatizar la entrega del software o la infraestructura al ambiente destino (staging, producción). Puede incluir aprobación manual antes de ejecutar cambios críticos. |

### 1.2 ¿Por qué GitHub Actions?

Para este proyecto usaremos GitHub Actions por tres razones principales:

- **El pipeline vive en el repositorio:** el archivo YAML de configuración está versionado junto con tu código Terraform y Ansible. Cualquier cambio al pipeline queda registrado en el historial de Git.
- **Sin servidores que administrar:** GitHub proporciona runners (máquinas virtuales) gratuitas que ejecutan tus workflows. No necesitas instalar ni mantener un servidor adicional.
- **Integración nativa con AWS:** existen acciones oficiales de AWS para autenticación, ECR y otros servicios que simplifican enormemente la configuración.

---

## 2. Anatomía de un Workflow

Un workflow es un archivo YAML dentro de tu repositorio, en la carpeta `.github/workflows/`. GitHub lo detecta automáticamente y lo ejecuta según las reglas que definas.

### 2.1 Estructura general

```yaml
# .github/workflows/mi-pipeline.yml
name: Nombre del Workflow   # Nombre visible en GitHub

on:                         # DISPARADORES (cuándo corre)
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:                       # TRABAJOS (agrupan pasos)
  nombre-del-job:
    runs-on: ubuntu-latest  # Sistema operativo del runner

    steps:                  # PASOS (acciones individuales)
      - name: Paso 1
        uses: actions/checkout@v4   # Acción predefinida

      - name: Paso 2
        run: echo "Hola desde el runner"   # Comando directo
```

### 2.2 Glosario de términos

| Concepto | Definición |
|----------|------------|
| **Workflow** | El archivo YAML completo. Define todo el proceso de CI/CD. |
| **Event (`on:`)** | El disparador: `push`, `pull_request`, `workflow_dispatch` (manual), `schedule` (cron), etc. |
| **Job** | Un conjunto de pasos que se ejecutan en la misma máquina virtual. Los jobs corren en paralelo por defecto; puedes encadenarlos con `needs`. |
| **Step** | Una instrucción dentro de un job. Puede usar una acción predefinida (`uses:`) o ejecutar comandos de shell (`run:`). |
| **Action** | Código reutilizable publicado en el Marketplace de GitHub. Ejemplo: `actions/checkout@v4`, `hashicorp/setup-terraform@v3`. |
| **Runner** | La máquina virtual donde corre el job. GitHub provee runners con Ubuntu, Windows y macOS. |
| **Secret** | Variable cifrada que se guarda en GitHub (Settings → Secrets). Nunca se muestra en los logs. |
| **Environment** | Entorno nombrado (ej: `production`) que puede requerir aprobación manual antes de correr el job. |

---

## 3. Autenticación con AWS sin Access Keys

Guardar las credenciales de AWS (Access Key ID y Secret Access Key) como secrets es funcional pero tiene un problema: si el secret se filtra, cualquiera puede acceder a tu cuenta AWS.

La forma recomendada es usar **OIDC (OpenID Connect)**, que permite a GitHub Actions asumir un IAM Role directamente, sin necesidad de credenciales de larga duración.

### 3.1 Cómo funciona OIDC

> **OIDC en pocas palabras**
>
> GitHub genera un token firmado que dice: *"Este workflow corre en el repo tuOrg/tuRepo, en el branch main"*.
> AWS verifica ese token contra el Identity Provider de GitHub y, si coincide con las condiciones del IAM Role, otorga credenciales temporales.
> Las credenciales expiran al terminar el job. No hay nada que rotar ni proteger manualmente.

### 3.2 Paso a paso: Configurar OIDC en AWS

Ejecuta los siguientes comandos en tu terminal (con AWS CLI configurado). Solo se hace **una vez por cuenta AWS**.

#### Paso 1 — Crear el Identity Provider

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

#### Paso 2 — Crear el IAM Role

Crea un archivo `trust-policy.json` con el siguiente contenido. Reemplaza `TU_ORG` y `TU_REPO`:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
      },
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:TU_ORG/TU_REPO:*"
      }
    }
  }]
}
```

```bash
aws iam create-role \
  --role-name GitHubActionsRole \
  --assume-role-policy-document file://trust-policy.json

# Adjunta las políticas necesarias (ajusta según tus recursos)
aws iam attach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

> ⚠️ **Nota de seguridad:** `AdministratorAccess` se usa aquí por simplicidad académica. En proyectos reales debes aplicar el **principio de menor privilegio**: solo otorgar los permisos que el pipeline realmente necesita (ECR, S3 para estado de Terraform, EC2 para Ansible, etc.).

#### Paso 3 — Agregar el ARN del role como secret en GitHub

Ve a tu repositorio en GitHub → **Settings → Secrets and variables → Actions → New repository secret**.

| Nombre del Secret | Valor |
|-------------------|-------|
| `AWS_ROLE_ARN` | `arn:aws:iam::123456789012:role/GitHubActionsRole` |
| `AWS_REGION` | `us-east-1` (o la región que uses) |

---

## 4. Pipeline de Terraform: Plan + Apply con Aprobación

Este pipeline corre automáticamente en cada push o PR a `main`. Ejecuta `terraform plan` siempre. El `terraform apply` solo corre cuando alguien lo aprueba manualmente en GitHub.

### 4.1 Configurar el Environment de producción

Ve a tu repositorio → **Settings → Environments → New environment**. Nómbralo `production`. Activa la opción **Required reviewers** y agrégate a ti mismo (o al equipo que deba aprobar).

> 💡 **¿Por qué usar Environments?**
>
> Los Environments de GitHub permiten proteger jobs sensibles con aprobaciones manuales.
> Cuando el job de apply llega, GitHub pausa el workflow y envía una notificación a los revisores.
> Nadie puede ejecutar el apply sin que un revisor haga clic en **"Approve and deploy"**.

### 4.2 Archivo del workflow

Crea el archivo `.github/workflows/terraform.yml` en tu repositorio:

```yaml
name: Terraform CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  id-token: write        # Necesario para OIDC
  contents: read
  pull-requests: write   # Para escribir comentarios en PRs

jobs:
  # ── JOB 1: PLAN (siempre corre) ─────────────────────────────────
  plan:
    name: Terraform Plan
    runs-on: ubuntu-latest

    steps:
      - name: Checkout del código
        uses: actions/checkout@v4

      - name: Autenticación con AWS via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Instalar Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: '1.8.0'

      - name: terraform init
        run: terraform init
        working-directory: ./terraform

      - name: terraform fmt (verifica formato)
        run: terraform fmt -check
        working-directory: ./terraform

      - name: terraform validate
        run: terraform validate
        working-directory: ./terraform

      - name: terraform plan
        id: plan
        run: terraform plan -out=tfplan -no-color 2>&1 | tee plan_output.txt
        working-directory: ./terraform

      - name: Comentar plan en el PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const plan = fs.readFileSync('terraform/plan_output.txt', 'utf8');
            const truncated = plan.length > 60000 ? plan.substring(0,60000) + '...(truncado)' : plan;
            github.rest.issues.createComment({
              ...context.repo,
              issue_number: context.issue.number,
              body: '### Terraform Plan\n```\n' + truncated + '\n```'
            });

      - name: Guardar plan como artefacto
        uses: actions/upload-artifact@v4
        with:
          name: tfplan
          path: terraform/tfplan

  # ── JOB 2: APPLY (requiere aprobación manual) ────────────────────
  apply:
    name: Terraform Apply
    runs-on: ubuntu-latest
    needs: plan                  # Espera que 'plan' termine OK
    environment: production      # Activa la aprobación manual
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'

    steps:
      - name: Checkout del código
        uses: actions/checkout@v4

      - name: Autenticación con AWS via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Instalar Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: '1.8.0'

      - name: terraform init
        run: terraform init
        working-directory: ./terraform

      - name: Descargar plan aprobado
        uses: actions/download-artifact@v4
        with:
          name: tfplan
          path: terraform/

      - name: terraform apply
        run: terraform apply -auto-approve tfplan
        working-directory: ./terraform
```

---

## 5. Pipeline de Build y Push a Amazon ECR

ECR (Elastic Container Registry) es el registro privado de imágenes Docker de AWS. Este pipeline construye tu imagen y la sube a ECR automáticamente en cada push a `main`.

### 5.1 Prerrequisitos en AWS

Crea el repositorio ECR antes de correr el pipeline:

```bash
# Crear el repositorio ECR
aws ecr create-repository \
  --repository-name mi-aplicacion \
  --region us-east-1

# Guarda el URI que devuelve el comando, lo necesitarás como secret:
# 123456789012.dkr.ecr.us-east-1.amazonaws.com/mi-aplicacion
```

### 5.2 Agregar secrets adicionales en GitHub

| Secret | Valor de ejemplo |
|--------|-----------------|
| `ECR_REGISTRY` | `123456789012.dkr.ecr.us-east-1.amazonaws.com` |
| `ECR_REPOSITORY` | `mi-aplicacion` |
| `AWS_ROLE_ARN` | `arn:aws:iam::123456789012:role/GitHubActionsRole` |
| `AWS_REGION` | `us-east-1` |

### 5.3 Archivo del workflow

```yaml
name: Build y Push a ECR

on:
  push:
    branches: [main]
    paths:
      - 'app/**'      # Solo corre si cambia algo en la carpeta app/
      - 'Dockerfile'

permissions:
  id-token: write
  contents: read

jobs:
  build-and-push:
    name: Build y Push imagen Docker
    runs-on: ubuntu-latest

    steps:
      - name: Checkout del código
        uses: actions/checkout@v4

      - name: Autenticación con AWS via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Login a Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Definir tags de la imagen
        id: meta
        run: |
          echo "IMAGE_TAG=${{ github.sha }}" >> $GITHUB_OUTPUT
          echo "IMAGE_LATEST=${{ secrets.ECR_REGISTRY }}/${{ secrets.ECR_REPOSITORY }}:latest" >> $GITHUB_OUTPUT
          echo "IMAGE_SHA=${{ secrets.ECR_REGISTRY }}/${{ secrets.ECR_REPOSITORY }}:${{ github.sha }}" >> $GITHUB_OUTPUT

      - name: Build de la imagen Docker
        run: |
          docker build \
            -t ${{ steps.meta.outputs.IMAGE_SHA }} \
            -t ${{ steps.meta.outputs.IMAGE_LATEST }} \
            .

      - name: Push de la imagen a ECR
        run: |
          docker push ${{ steps.meta.outputs.IMAGE_SHA }}
          docker push ${{ steps.meta.outputs.IMAGE_LATEST }}

      - name: Resumen del job
        run: |
          echo '## Imagen publicada' >> $GITHUB_STEP_SUMMARY
          echo '```' >> $GITHUB_STEP_SUMMARY
          echo '${{ steps.meta.outputs.IMAGE_SHA }}' >> $GITHUB_STEP_SUMMARY
          echo '```' >> $GITHUB_STEP_SUMMARY
```

---

## 6. Pipeline de Configuración con Ansible via AWS SSM

Ansible necesita conectarse a los servidores para configurarlos. En lugar de abrir puertos SSH y manejar claves privadas, usaremos **AWS Systems Manager (SSM)**, que no requiere ningún puerto abierto.

### 6.1 ¿Cómo funciona SSM sin SSH?

> **El flujo de conexión con SSM**
>
> 1. El agente SSM corre dentro de la instancia EC2 (viene instalado en Amazon Linux 2/2023 y Ubuntu recientes).
> 2. El agente establece una conexión saliente HTTPS hacia el servicio SSM de AWS. No necesita puertos entrantes.
> 3. Ansible usa el plugin `aws_ssm` como connection type. En vez de abrir un socket SSH, pasa los comandos a través de SSM.
> 4. El IAM Role del runner de GitHub necesita permisos `ssm:StartSession` y `ssm:SendCommand` sobre las instancias target.

### 6.2 Prerrequisitos en las instancias EC2

Las instancias deben tener:

- El agente SSM instalado y corriendo (viene de fábrica en Amazon Linux 2023 y Ubuntu 22.04+).
- Un IAM Instance Profile con la política `AmazonSSMManagedInstanceCore` adjunta.
- Conectividad de salida hacia `ssm.REGION.amazonaws.com` (puerto 443).

```bash
# Verificar que el agente SSM está activo en la instancia
sudo systemctl status amazon-ssm-agent

# Verificar que la instancia aparece en SSM Fleet Manager
aws ssm describe-instance-information --region us-east-1
```

### 6.3 Instalar el plugin de SSM para Ansible

El runner de GitHub Actions necesita el plugin de sesión de SSM y Ansible instalados:

```bash
# Instalar Ansible
pip install ansible boto3 botocore

# Instalar el plugin de sesión SSM para AWS CLI
curl 'https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb' \
  -o session-manager-plugin.deb
sudo dpkg -i session-manager-plugin.deb
```

### 6.4 Inventario dinámico de AWS

En vez de hardcodear IPs, usaremos el inventario dinámico de AWS que descubre las instancias automáticamente por tags:

```yaml
# inventory/aws_ec2.yml
plugin: amazon.aws.aws_ec2
regions:
  - us-east-1
filters:
  instance-state-name: running
  tag:Environment: production   # Solo instancias con este tag
keyed_groups:
  - key: tags.Role
    prefix: role
compose:
  ansible_host: instance_id     # Usar Instance ID para SSM (no IP)
```

### 6.5 Archivo del workflow

```yaml
name: Ansible Deploy via SSM

on:
  workflow_run:
    workflows: ['Terraform CI/CD']   # Corre después del apply de Terraform
    types: [completed]
    branches: [main]
  workflow_dispatch:                  # También permite ejecución manual

permissions:
  id-token: write
  contents: read

jobs:
  configure:
    name: Configurar servidores con Ansible
    runs-on: ubuntu-latest
    if: ${{ github.event.workflow_run.conclusion == 'success' || github.event_name == 'workflow_dispatch' }}

    steps:
      - name: Checkout del código
        uses: actions/checkout@v4

      - name: Autenticación con AWS via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Instalar Ansible y dependencias
        run: |
          python -m pip install --upgrade pip
          pip install ansible boto3 botocore
          ansible-galaxy collection install amazon.aws

      - name: Instalar plugin SSM
        run: |
          curl -s 'https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb' \
            -o ssm-plugin.deb
          sudo dpkg -i ssm-plugin.deb

      - name: Verificar conectividad SSM
        run: |
          aws ssm describe-instance-information \
            --query 'InstanceInformationList[*].[InstanceId,PingStatus]' \
            --output table

      - name: Ejecutar playbook de Ansible
        run: |
          ansible-playbook \
            -i inventory/aws_ec2.yml \
            --connection=aws_ssm \
            playbooks/configure.yml \
            -v
        env:
          ANSIBLE_HOST_KEY_CHECKING: 'false'
          AWS_DEFAULT_REGION: ${{ secrets.AWS_REGION }}
```

---

## 7. Estructura Recomendada del Repositorio

Para que los tres pipelines convivan ordenadamente, organiza tu repositorio así:

```
mi-proyecto/
│
├── .github/
│   └── workflows/
│       ├── terraform.yml        # Pipeline plan + apply
│       ├── ecr-build.yml        # Pipeline build & push
│       └── ansible-deploy.yml   # Pipeline configuración
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── backend.tf               # Backend S3 para el estado
│
├── ansible/
│   ├── inventory/
│   │   └── aws_ec2.yml          # Inventario dinámico
│   ├── playbooks/
│   │   └── configure.yml
│   └── roles/
│       └── webserver/
│
├── app/                         # Tu aplicación
│   └── src/
│
├── Dockerfile
└── README.md
```

---

## 8. Tips y Errores Frecuentes

### 8.1 Tips para el día a día

> 💡 **Buenas prácticas**
>
> - Usa `paths:` en los triggers para que cada pipeline solo corra cuando cambia su código relevante. Ahorra minutos de runner.
> - El campo `id:` en un step permite referenciar sus outputs en pasos siguientes con `${{ steps.ID.outputs.VARIABLE }}`.
> - Revisa siempre la pestaña **Actions** en GitHub después de un push para ver el estado en tiempo real.
> - El botón **"Re-run failed jobs"** te permite volver a correr solo los jobs que fallaron, sin repetir los exitosos.

### 8.2 Errores frecuentes

| Error | Causa y solución |
|-------|-----------------|
| `Error: 'credentials' not configured` | Falta el step de `configure-aws-credentials`, o el IAM Role no tiene el Trust Policy de OIDC correctamente configurado. Verifica que el ARN en el secret `AWS_ROLE_ARN` sea correcto. |
| `terraform plan` falla con `'Backend not initialized'` | Asegúrate de tener `terraform init` antes de `terraform plan`. Si usas backend S3, el bucket debe existir previamente. |
| No se puede hacer push a ECR: `'no basic auth credentials'` | El step de `amazon-ecr-login` debe ir **DESPUÉS** del step de `configure-aws-credentials`. El orden importa. |
| Ansible no encuentra los hosts | Verifica que las instancias EC2 tengan el tag `Environment: production` (o el que uses en el filtro del inventario dinámico). Corre `aws ssm describe-instance-information` para confirmar que son visibles. |
| El apply no espera aprobación | El campo `environment: production` en el job de apply es obligatorio. Si no aparece el botón de aprobación, verifica que el environment existe en **Settings → Environments**. |
| Error de permisos en OIDC: `'Not authorized to perform sts:AssumeRoleWithWebIdentity'` | La condición `StringLike` en el Trust Policy debe coincidir con el repo y branch exactos. Usa `repo:ORG/REPO:*` para permitir cualquier rama. |

---

## 9. Flujo Completo del Proyecto

Cuando todo está configurado, el flujo de trabajo completo es el siguiente:

**1 — git push a main**
Detonas los pipelines. GitHub Actions detecta el push y evalúa qué workflows deben correr según los `paths` y `branches` configurados.

**2 — Terraform Plan (automático)**
El runner se autentica con AWS via OIDC, corre `terraform plan` y publica el resultado como comentario en el PR o como artefacto.

**3 — Revisión y aprobación manual**
Un revisor lee el plan en GitHub, verifica que los cambios son correctos y hace clic en **"Approve and deploy"** en la pestaña Environments.

**4 — Terraform Apply (post-aprobación)**
Se descarga el plan aprobado y se ejecuta `terraform apply`. La infraestructura en AWS refleja el nuevo estado.

**5 — Build y Push a ECR (paralelo)**
Si cambió el Dockerfile o la carpeta `app/`, se construye la imagen y se sube a ECR con el SHA del commit como tag.

**6 — Ansible via SSM (post-terraform)**
Ansible descubre las instancias por tags, se conecta via SSM y aplica el playbook de configuración. Sin puertos abiertos, sin claves SSH.

---

## 10. Monitoreo y Observabilidad del Proyecto

TrueTally en AWS usa el siguiente stack de observabilidad (aprovisionado con Terraform y configurado con Ansible después del `apply`):

- **CloudWatch**: logs y métricas de Lambdas, ECS, RDS y SQS (consumidos en Grafana vía data source CloudWatch).
- **Prometheus**: recolección de métricas en ECS Fargate (scrape cada 15 s, retención 7 días).
- **Loki** + **Promtail**: agregación y envío de logs (ECS Fargate, puertos 3100 y 9080).
- **Grafana**: dashboards detrás de un ALB (puerto 3000) con data sources CloudWatch, Loki y Prometheus.

> AWS X-Ray fue removido del proyecto porque no estaba completamente instrumentado (solo tenía el flag de Active tracing en las Lambdas y el permiso IAM, sin daemon ni SDK).

---

> 🔁 **Recuerda**
>
> Los pipelines son código. Versiónalos, pruébalos y mejóralos igual que el resto de tu proyecto.
> Si algo falla, los logs en la pestaña **Actions** te dicen exactamente qué pasó y en qué step.
> Empieza simple: un workflow con pocos steps y ve agregando complejidad a medida que entiendas el flujo.