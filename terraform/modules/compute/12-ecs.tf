# ECR Repository para blockchain-core
resource "aws_ecr_repository" "blockchain" {
  name = "${local.name_prefix}-blockchain"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.main.arn
  }

  tags = {
    Name = "${local.name_prefix}-blockchain"
  }
}

# ECR Lifecycle Policy - Limpiar imágenes antiguas
resource "aws_ecr_lifecycle_policy" "blockchain" {
  repository = aws_ecr_repository.blockchain.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECS Cluster
resource "aws_ecs_cluster" "blockchain" {
  name = "${local.name_prefix}-blockchain-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${local.name_prefix}-blockchain-cluster"
  }
}

# EFS File System para persistencia
resource "aws_efs_file_system" "blockchain" {
  creation_token = "${local.name_prefix}-blockchain-data"

  encrypted  = true
  kms_key_id = aws_kms_key.main.arn

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "${local.name_prefix}-blockchain-efs"
  }
}

# EFS Access Point
resource "aws_efs_access_point" "blockchain" {
  file_system_id = aws_efs_file_system.blockchain.id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/blockchain"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "0755"
    }
  }
}

# EFS Mount Targets (uno por AZ)
resource "aws_efs_mount_target" "blockchain" {
  for_each        = toset(var.azs)
  file_system_id  = aws_efs_file_system.blockchain.id
  subnet_id       = aws_subnet.blockchain[each.key].id
  security_groups = [aws_security_group.efs.id]
}

# CloudWatch Log Group para Blockchain
resource "aws_cloudwatch_log_group" "blockchain" {
  name              = "/ecs/${local.name_prefix}-blockchain"
  retention_in_days = 14
}

# ECS Task Definition
resource "aws_ecs_task_definition" "blockchain" {
  family                   = "${local.name_prefix}-blockchain"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  volume {
    name = "blockchain-data"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.blockchain.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.blockchain.id
      }
    }
  }

  container_definitions = jsonencode([
    {
      name      = "blockchain-node"
      image     = "${aws_ecr_repository.blockchain.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 9944
          hostPort      = 9944
          protocol      = "tcp"
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "blockchain-data"
          containerPath = "/data/db"
        }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:9944/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.blockchain.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "blockchain"
        }
      }
      environment = [
        { name = "PORT", value = "9944" },
        { name = "RUST_LOG", value = "blockchain_core=info" }
      ]
    }
  ])

  tags = {
    Name = "${local.name_prefix}-blockchain-task"
  }
}

# ECS Service
resource "aws_ecs_service" "blockchain" {
  name            = "${local.name_prefix}-blockchain-service"
  cluster         = aws_ecs_cluster.blockchain.id
  task_definition = aws_ecs_task_definition.blockchain.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [for s in aws_subnet.blockchain : s.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blockchain.arn
    container_name   = "blockchain-node"
    container_port   = 9944
  }

  depends_on = [aws_lb_listener.blockchain]

  tags = {
    Name = "${local.name_prefix}-blockchain-service"
  }
}

output "blockchain_alb_endpoint" {
  value = aws_lb.blockchain.dns_name
}