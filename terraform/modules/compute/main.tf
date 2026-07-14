locals {
  name_prefix = "${var.project_name}-${var.env}"

  # Mapear nombres de zonas de disponibilidad a IDs de subredes para objetivos de montaje EFS
  blockchain_mount_targets = {
    for i, az in var.azs :
    az => var.blockchain_subnet_ids[i]
  }
}

# Rol IAM para funciones Lambda
resource "aws_iam_role" "lambda" {
  name = "${local.name_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Política IAM de Lambda para acceso a SSM, Secrets Manager y SQS
resource "aws_iam_role_policy" "lambda_ssm" {
  name = "${local.name_prefix}-lambda-ssm"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Permitir gestión de sesiones SSM
      {
        Effect = "Allow"
        Action = [
          "ssm:StartSession"
        ]
        Resource = "arn:aws:ssm:*:*:managed-instance/*"
      },
      # Permitir envío de comandos SSM
      {
        Effect = "Allow"
        Action = [
          "ssm:SendCommand"
        ]
        Resource = "arn:aws:ssm:*:*:document/*"
      },
      # Permitir leer credenciales de BD desde Secrets Manager
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          var.db_credentials_secret_arn,
          var.redis_auth_token_secret_arn
        ]
      },
      # Permitir recibir mensajes de la cola de votos
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.vote_queue_arn
      },
      # Permitir enviar mensajes a la DLQ
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = var.dlq_arn
      }
    ]
  })
}

# Funciones Lambda
# El despliegue se gestiona con Ansible después de la creación inicial
resource "aws_lambda_function" "acceso" {
  function_name                  = "${local.name_prefix}-acceso"
  filename                       = "${var.lambda_zip_path}/lambda-acceso.zip"
  role                           = aws_iam_role.lambda.arn
  handler                        = "bootstrap"
  runtime                        = "provided.al2"
  kms_key_arn                    = var.kms_key_arn
  reserved_concurrent_executions = var.lambda_reserved_concurrent_executions

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  dead_letter_config {
    target_arn = var.dlq_arn
  }

  environment {
    variables = {
      DB_CREDENTIALS_ARN  = var.db_credentials_secret_arn
      BLOCKCHAIN_NODE_URL = local.blockchain_service_dns != "" ? "http://${local.blockchain_service_dns}:9944" : "http://localhost:9944"
    }
  }
}

# Lambda despachador: recibe votos del frontend y los envía a la cola SQS
resource "aws_lambda_function" "despachador" {
  function_name                  = "${local.name_prefix}-despachador"
  filename                       = "${var.lambda_zip_path}/lambda-despachador.zip"
  role                           = aws_iam_role.lambda.arn
  handler                        = "bootstrap"
  runtime                        = "provided.al2"
  kms_key_arn                    = var.kms_key_arn
  reserved_concurrent_executions = var.lambda_reserved_concurrent_executions

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  dead_letter_config {
    target_arn = var.dlq_arn
  }

  environment {
    variables = {
      VOTE_QUEUE_URL = var.vote_queue_url
    }
  }
}

# Lambda procesador: procesa votos desde SQS y actualiza la blockchain
resource "aws_lambda_function" "procesador" {
  function_name                  = "${local.name_prefix}-procesador"
  filename                       = "${var.lambda_zip_path}/lambda-procesador.zip"
  role                           = aws_iam_role.lambda.arn
  handler                        = "bootstrap"
  runtime                        = "provided.al2"
  kms_key_arn                    = var.kms_key_arn
  reserved_concurrent_executions = var.lambda_reserved_concurrent_executions

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  dead_letter_config {
    target_arn = var.dlq_arn
  }

  environment {
    variables = {
      BLOCKCHAIN_NODE_URL = local.blockchain_service_dns != "" ? "http://${local.blockchain_service_dns}:9944" : "http://localhost:9944"
    }
  }
}

# Mapeo de fuente de eventos: cola de votos SQS -> lambda-procesador
# Consume los votos encolados por lambda-despachador y los escribe en la blockchain.
resource "aws_lambda_event_source_mapping" "procesador_vote" {
  event_source_arn        = var.vote_queue_arn
  function_name           = aws_lambda_function.procesador.arn
  batch_size              = 5
  function_response_types = ["ReportBatchItemFailures"]
}

# ---------------------------------------------------------------------------
# Reenvío de CloudWatch Logs -> Loki
# ---------------------------------------------------------------------------
# Las Lambdas (/aws/lambda/...) y el nodo blockchain (/ecs/...-blockchain-node)
# escriben en CloudWatch. Este forwarder recibe los eventos de suscripcion de
# CloudWatch Logs y los reenvia a Loki etiquetandolos con job=lambda o
# job=blockchain para que sean consultables en Grafana.
# ---------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

data "archive_file" "loki_forwarder" {
  type        = "zip"
  source_file = "${path.module}/loki_forwarder.py"
  output_path = "${path.module}/build/loki_forwarder.zip"
}

resource "aws_iam_role" "loki_forwarder" {
  name = "${local.name_prefix}-loki-forwarder-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "loki_forwarder" {
  name = "${local.name_prefix}-loki-forwarder-policy"
  role = aws_iam_role.loki_forwarder.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "loki_forwarder" {
  function_name                  = "${local.name_prefix}-loki-forwarder"
  filename                       = data.archive_file.loki_forwarder.output_path
  source_code_hash               = data.archive_file.loki_forwarder.output_base64sha256
  role                           = aws_iam_role.loki_forwarder.arn
  handler                        = "loki_forwarder.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 30
  memory_size                    = 128
  kms_key_arn                    = var.kms_key_arn
  reserved_concurrent_executions = var.lambda_reserved_concurrent_executions

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = {
      LOKI_URL = "http://loki.${var.env}.truetally.internal:3100/loki/api/v1/push"
    }
  }
}

# Suscripcion de CloudWatch Logs para las Lambdas de aplicacion y el nodo
# blockchain. Todas se reenvian a Loki etiquetadas con el job correspondiente.
locals {
  loki_forwarder_targets = {
    acceso = {
      log_group = "/aws/lambda/${local.name_prefix}-acceso"
      job       = "lambda"
    }
    despachador = {
      log_group = "/aws/lambda/${local.name_prefix}-despachador"
      job       = "lambda"
    }
    procesador = {
      log_group = "/aws/lambda/${local.name_prefix}-procesador"
      job       = "lambda"
    }
    blockchain = {
      log_group = aws_cloudwatch_log_group.blockchain_node.name
      job       = "blockchain"
    }
  }
}

resource "aws_lambda_permission" "loki_forwarder_invoke" {
  for_each = local.loki_forwarder_targets

  statement_id  = "AllowCloudWatchLogs${replace(replace(each.key, "-", ""), "_", "")}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.loki_forwarder.function_name
  principal     = "logs.${var.aws_region}.amazonaws.com"
  source_arn    = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:${each.value.log_group}:*"
}

resource "aws_cloudwatch_log_subscription_filter" "loki_forwarder" {
  for_each = local.loki_forwarder_targets

  name            = "${each.key}-to-loki"
  log_group_name  = each.value.log_group
  filter_pattern  = ""
  destination_arn = aws_lambda_function.loki_forwarder.arn

  depends_on = [aws_lambda_permission.loki_forwarder_invoke]
}

# Clúster ECS para el nodo Blockchain
resource "aws_ecs_cluster" "blockchain" {
  name = "${local.name_prefix}-blockchain-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Rol IAM para tareas ECS (contenedor blockchain)
resource "aws_iam_role" "ecs_task" {
  name = "${local.name_prefix}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Rol IAM para ejecución de tareas ECS (obtención de imágenes, escritura de logs)
resource "aws_iam_role" "ecs_execution" {
  name = "${local.name_prefix}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_ecr" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ecs_execution_task" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_task_service_discovery" {
  name = "${local.name_prefix}-ecs-task-sd"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "servicediscovery:DiscoverInstances",
          "servicediscovery:GetInstances",
          "servicediscovery:RegisterInstance",
          "servicediscovery:DeregisterInstance"
        ]
        Resource = aws_service_discovery_service.blockchain.arn
      }
    ]
  })
}

# Política que permite a tareas ECS montar el sistema de archivos EFS
resource "aws_iam_role_policy" "ecs_task_efs" {
  name = "${local.name_prefix}-ecs-efs"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess"
        ]
        Resource = aws_efs_file_system.blockchain.arn
      }
    ]
  })
}

# Sistema de archivos EFS para la persistencia de estado del nodo blockchain
resource "aws_efs_file_system" "blockchain" {
  creation_token = "${local.name_prefix}-blockchain-efs"
  encrypted      = true
  kms_key_id     = var.kms_key_arn

  tags = {
    Name = "${local.name_prefix}-blockchain-efs"
  }
}

# Objetivos de montaje para EFS en cada zona de disponibilidad
resource "aws_efs_mount_target" "blockchain" {
  for_each = local.blockchain_mount_targets

  file_system_id  = aws_efs_file_system.blockchain.id
  subnet_id       = each.value
  security_groups = [var.blockchain_security_group_id]
}

# Punto de acceso EFS para montaje de contenedores ECS
resource "aws_efs_access_point" "blockchain" {
  file_system_id = aws_efs_file_system.blockchain.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/blockchain"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }
}

# Definición de tarea ECS para el nodo blockchain con montaje de volumen EFS y enrutamiento de logs FireLens a Loki
# Grupo de logs de CloudWatch para el nodo blockchain. Suscrito al forwarder de Loki
# (job=blockchain) para llevar los logs de la aplicacion a Loki de forma
# fiable (awslogs es mas robusto que FireLens en esta configuracion).
resource "aws_cloudwatch_log_group" "blockchain_node" {
  name              = "/ecs/${local.name_prefix}-blockchain-node"
  retention_in_days = 365
  kms_key_id        = var.kms_key_arn

  tags = {
    Environment = var.env
  }
}

resource "aws_ecs_task_definition" "blockchain" {
  family                   = "${local.name_prefix}-blockchain"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name                   = "blockchain-node"
      image                  = "${var.ecr_repository_url}:latest"
      essential              = true
      privileged             = false
      readonlyRootFilesystem = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"             = aws_cloudwatch_log_group.blockchain_node.name
          "awslogs-region"            = var.aws_region
          "awslogs-stream-prefix"     = "ecs"
          "awslogs-multiline-pattern" = "^\\S"
        }
      }
      portMappings = [{
        containerPort = 9944
        hostPort      = 9944
      }]
      mountPoints = [{
        sourceVolume  = "blockchain-efs"
        containerPath = "/data"
        readOnly      = false
      }]
    }
  ])

  volume {
    name = "blockchain-efs"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.blockchain.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.blockchain.id
        iam             = "ENABLED"
      }
    }
  }
}

# Servicio ECS ejecutando el nodo blockchain
resource "aws_ecs_service" "blockchain" {
  name            = "${local.name_prefix}-blockchain-service"
  cluster         = aws_ecs_cluster.blockchain.id
  task_definition = aws_ecs_task_definition.blockchain.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  force_new_deployment = true

  network_configuration {
    subnets          = var.blockchain_subnet_ids
    security_groups  = [var.blockchain_security_group_id]
    assign_public_ip = false
  }

  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.blockchain.arn
  }
}

# Descubrimiento de servicios para el nodo blockchain (endpoint DNS estable)
resource "aws_service_discovery_service" "blockchain" {
  name = "blockchain"

  dns_config {
    namespace_id = var.service_discovery_namespace_id
    dns_records {
      type = "A"
      ttl  = 60
    }
  }

  tags = {
    Name = "${local.name_prefix}-blockchain-sd"
  }
}

locals {
  blockchain_service_dns = "blockchain.${var.service_discovery_namespace_name}"
}

output "blockchain_service_dns" {
  value = local.blockchain_service_dns
}