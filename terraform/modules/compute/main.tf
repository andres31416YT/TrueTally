locals {
  name_prefix = "${var.project_name}-${var.env}"

  # Mapa de AZs a IDs de subredes blockchain para EFS mount targets
  blockchain_mount_targets = {
    for i, az in var.azs :
    az => var.blockchain_subnet_ids[i]
  }
}

# IAM Role for Lambda
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

resource "aws_iam_role_policy_attachment" "lambda_xray" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role_policy" "lambda_ssm" {
  name = "${local.name_prefix}-lambda-ssm"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:StartSession"
        ]
        Resource = "arn:aws:ssm:*:*:managed-instance/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:SendCommand"
        ]
        Resource = "arn:aws:ssm:*:*:document/*"
      },
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
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.vote_queue_arn
      },
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

# Lambda functions
resource "aws_lambda_function" "acceso" {
  function_name                  = "${local.name_prefix}-acceso"
  filename                       = "${var.lambda_zip_path}/lambda-acceso.zip"
  role                           = aws_iam_role.lambda.arn
  handler                        = "bootstrap" #Manejamos RUST
  runtime                        = "provided.al2" #Ejecutar lenguaje RUST compilado de forma nativa
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
      DB_CREDENTIALS_ARN = var.db_credentials_secret_arn
    }
  }

  tracing_config {
    mode = "Active"
  }
}

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

  tracing_config {
    mode = "Active"
  }
}

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
      NODE_URL_AZ1 = var.lambda_node_url_az1
      NODE_URL_AZ2 = var.lambda_node_url_az2
    }
  }

  tracing_config {
    mode = "Active"
  }
}

# ECS Cluster for Blockchain
resource "aws_ecs_cluster" "blockchain" {
  name = "${local.name_prefix}-blockchain-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

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

# EFS for Blockchain Node persistence
resource "aws_efs_file_system" "blockchain" {
  creation_token = "${local.name_prefix}-blockchain-efs"
  encrypted      = true
  kms_key_id     = var.kms_key_arn

  tags = {
    Name = "${local.name_prefix}-blockchain-efs"
  }
}

# Crear un punto de acceso Mount Target para que se puedan conectar al disco EFS
resource "aws_efs_mount_target" "blockchain" {
  for_each = local.blockchain_mount_targets # Repite este bloque de código para cada una de las subredes

  file_system_id  = aws_efs_file_system.blockchain.id   # Le dice al punto de acceso a que disco duro en red (EFS) específico debe conectarse
  subnet_id       = each.value # Asigna este punto de acceso a la subred actual del bucle (bucle 1, bucle 2, etc.).
  security_groups = [var.blockchain_security_group_id] # Permitir que solo los nodos blockchain puedan entrar al disco EFS
}

# Crear el punto de acceso EFS para que el contenedor ECS pueda montar el disco EFS
resource "aws_efs_access_point" "blockchain" {
  file_system_id = aws_efs_file_system.blockchain.id #Conexion al disco de red especifico
  posix_user {
    gid = 1000 # Es el número de grupo estándar para aplicaciones
    uid = 1000 # ID= 1000 para saber quién está escribiendo los archivos.
  }
  root_directory {
    path = "/blockchain"
    creation_info {
      owner_gid   = 1000 # El grupo dueño de la nueva carpeta
      owner_uid   = 1000 # El usuario dueño de la nueva carpeta
      permissions = "755" # Permisos de seguridad: El dueño puede hacer todo
    }
  }
}

# ECS Task Definition with EFS volume
resource "aws_ecs_task_definition" "blockchain" {
  family                   = "${local.name_prefix}-blockchain"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name                   = "blockchain-node"
    image                  = "${var.ecr_repository_url}:latest"
    essential              = true
    privileged             = false
    readonlyRootFilesystem = true
    portMappings = [{
      containerPort = 9944
      hostPort      = 9944
    }]
    mountPoints = [{
      sourceVolume  = "blockchain-efs"
      containerPath = "/data"
      readOnly      = false
    }]
  }])

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

resource "aws_ecs_service" "blockchain" {
  name            = "${local.name_prefix}-blockchain-service"
  cluster         = aws_ecs_cluster.blockchain.id
  task_definition = aws_ecs_task_definition.blockchain.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.blockchain_subnet_ids
    security_groups  = [var.blockchain_security_group_id]
    assign_public_ip = true
  }

  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
}