locals {
  name_prefix = "${var.project_name}-${var.env}"
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

# Security Group for Observability stack
resource "aws_security_group" "observability" {
  name        = "${local.name_prefix}-observability-sg"
  description = "Security group for observability stack"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
    description = "Allow all traffic from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${local.name_prefix}-observability-sg"
  }
}

resource "aws_security_group_rule" "observability_from_blockchain" {
  count = var.blockchain_sg_id != "" ? 1 : 0

  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.observability.id
  source_security_group_id = var.blockchain_sg_id
  description              = "Allow traffic from blockchain SG"
}

# ECS Cluster for Observability
resource "aws_ecs_cluster" "observability" {
  name = "${local.name_prefix}-observability-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# IAM role for ECS tasks (observability)
resource "aws_iam_role" "ecs_task" {
  name = "${local.name_prefix}-observability-ecs-task-role"

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

resource "aws_iam_role_policy_attachment" "ecs_task_ssm" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM role for ECS task execution
resource "aws_iam_role" "ecs_execution" {
  name = "${local.name_prefix}-observability-ecs-execution-role"

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

resource "aws_iam_role_policy_attachment" "ecs_execution_role" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# CloudWatch Log Groups for observability services
resource "aws_cloudwatch_log_group" "loki" {
  name              = "/ecs/${local.name_prefix}-observability-loki"
  retention_in_days = 7
  kms_key_id        = var.kms_key_arn

  tags = {
    Environment = var.env
  }
}

resource "aws_cloudwatch_log_group" "promtail" {
  name              = "/ecs/${local.name_prefix}-observability-promtail"
  retention_in_days = 7
  kms_key_id        = var.kms_key_arn

  tags = {
    Environment = var.env
  }
}

resource "aws_cloudwatch_log_group" "prometheus" {
  name              = "/ecs/${local.name_prefix}-observability-prometheus"
  retention_in_days = 7
  kms_key_id        = var.kms_key_arn

  tags = {
    Environment = var.env
  }
}

resource "aws_cloudwatch_log_group" "grafana" {
  name              = "/ecs/${local.name_prefix}-observability-grafana"
  retention_in_days = 7
  kms_key_id        = var.kms_key_arn

  tags = {
    Environment = var.env
  }
}

# ECS Task Definition for Loki
resource "aws_ecs_task_definition" "loki" {
  family                   = "${local.name_prefix}-observability-loki"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name                   = "loki"
    image                  = "grafana/loki:2.9.3"
    essential              = true
    cpu                    = 256
    memory                 = 512
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.loki.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
    portMappings = [{
      containerPort = 3100
      hostPort      = 3100
      protocol      = "tcp"
    }]
    command = [
      "-config.file=/etc/loki/local-config.yaml"
    ]
  }])

  tags = {
    Name = "${local.name_prefix}-observability-loki"
  }
}

# ECS Task Definition for Promtail
resource "aws_ecs_task_definition" "promtail" {
  family                   = "${local.name_prefix}-observability-promtail"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "128"
  memory                   = "256"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name                   = "promtail"
    image                  = "grafana/promtail:2.9.3"
    essential              = true
    cpu                    = 128
    memory                 = 256
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.promtail.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
    entryPoint = ["/bin/sh", "-c"]
    command = [
      "echo 'server:\n  http_listen_port: 9080\n  grpc_listen_port: 0\npositions:\n  filename: /tmp/positions.yaml\nclients:\n  - url: http://localhost:3100/loki/api/v1/push\nscrape_configs:\n  - job_name: promtail\n    static_configs:\n      - targets:\n          - localhost\n        labels:\n          job: promtail\n          __path__: /var/log/promtail.log' > /etc/promtail/config.yml && /usr/bin/promtail -config.file=/etc/promtail/config.yml"
    ]
  }])

  tags = {
    Name = "${local.name_prefix}-observability-promtail"
  }
}

# ECS Task Definition for Prometheus
resource "aws_ecs_task_definition" "prometheus" {
  family                   = "${local.name_prefix}-observability-prometheus"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name                   = "prometheus"
    image                  = "prom/prometheus:v2.47.0"
    essential              = true
    cpu                    = 256
    memory                 = 512
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.prometheus.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
    portMappings = [{
      containerPort = 9090
      hostPort      = 9090
      protocol      = "tcp"
    }]
    entryPoint = ["/bin/sh", "-c"]
    command = [
      "echo 'global:\n  scrape_interval: 15s\nscrape_configs:\n  - job_name: prometheus\n    static_configs:\n      - targets: [localhost:9090]\n  - job_name: loki\n    static_configs:\n      - targets: [localhost:3100]\n  - job_name: promtail\n    static_configs:\n      - targets: [localhost:9080]' > /etc/prometheus/prometheus.yml && /bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/prometheus --storage.tsdb.retention.time=7d"
    ]
  }])

  tags = {
    Name = "${local.name_prefix}-observability-prometheus"
  }
}

# ECS Task Definition for Grafana
resource "aws_ecs_task_definition" "grafana" {
  family                   = "${local.name_prefix}-observability-grafana"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "128"
  memory                   = "256"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name                   = "grafana"
    image                  = "grafana/grafana:10.2.2"
    essential              = true
    cpu                    = 128
    memory                 = 256
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.grafana.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
      protocol      = "tcp"
    }]
    environment = [
      {
        name  = "GF_SECURITY_ADMIN_PASSWORD"
        value = "admin"
      },
      {
        name  = "GF_SERVER_ROOT_URL"
        value = "%(protocol)s://%(domain)s:%(http_port)s"
      },
      {
        name  = "GF_SERVER_SERVE_FROM_SUB_PATH"
        value = "false"
      }
    ]
  }])

  tags = {
    Name = "${local.name_prefix}-observability-grafana"
  }
}

# ECS Service for Loki
resource "aws_ecs_service" "loki" {
  name            = "${local.name_prefix}-observability-loki"
  cluster         = aws_ecs_cluster.observability.id
  task_definition = aws_ecs_task_definition.loki.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.observability.id]
    assign_public_ip = true
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
}

# ECS Service for Promtail
resource "aws_ecs_service" "promtail" {
  name            = "${local.name_prefix}-observability-promtail"
  cluster         = aws_ecs_cluster.observability.id
  task_definition = aws_ecs_task_definition.promtail.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.observability.id]
    assign_public_ip = true
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
}

# ECS Service for Prometheus
resource "aws_ecs_service" "prometheus" {
  name            = "${local.name_prefix}-observability-prometheus"
  cluster         = aws_ecs_cluster.observability.id
  task_definition = aws_ecs_task_definition.prometheus.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.observability.id]
    assign_public_ip = true
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
}

# ECS Service for Grafana
resource "aws_ecs_service" "grafana" {
  name            = "${local.name_prefix}-observability-grafana"
  cluster         = aws_ecs_cluster.observability.id
  task_definition = aws_ecs_task_definition.grafana.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.observability.id]
    assign_public_ip = true
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
}

output "observability_cluster_id" {
  value = aws_ecs_cluster.observability.id
}

output "observability_sg_id" {
  value = aws_security_group.observability.id
}

output "grafana_service_name" {
  value = aws_ecs_service.grafana.name
}
