locals {
  lambda_acceso_zip      = "${path.module}/../lambda/lambda-acceso.zip"
  lambda_despachador_zip = "${path.module}/../lambda/lambda-despachador.zip"
  lambda_procesador_zip  = "${path.module}/../lambda/lambda-procesador.zip"
}

locals {
  lambda_common_env = {
    DATABASE_URL = try(aws_db_proxy.main[0].endpoint, aws_db_instance.main.address)
    PORT         = "8080"
  }
}

# Log Groups
resource "aws_cloudwatch_log_group" "lambda_acceso" {
  for_each          = toset(["az1", "az2"])
  name              = "/aws/lambda/${local.name_prefix}-acceso-${each.key}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "lambda_despachador" {
  for_each          = toset(["az1", "az2"])
  name              = "/aws/lambda/${local.name_prefix}-despachador-${each.key}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "lambda_procesador" {
  for_each          = toset(["az1", "az2"])
  name              = "/aws/lambda/${local.name_prefix}-procesador-${each.key}"
  retention_in_days = 14
}

# Lambda Acceso - AZ1
resource "aws_lambda_function" "acceso_az1" {
  function_name    = "${local.name_prefix}-acceso-az1"
  role             = aws_iam_role.lambda.arn
  handler          = "bootstrap"
  runtime          = "provided.al2"
  timeout          = 30
  memory_size      = 512
  filename         = local.lambda_acceso_zip
  source_code_hash = filebase64sha256(local.lambda_acceso_zip)

  vpc_config {
    subnet_ids         = [aws_subnet.compute["us-east-1a"].id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = merge(
      local.lambda_common_env,
      { BLOCKCHAIN_NODE_URL = var.lambda_node_url_az1 }
    )
  }

  reserved_concurrent_executions = 5

  depends_on = [aws_cloudwatch_log_group.lambda_acceso]
}

# Lambda Acceso - AZ2
resource "aws_lambda_function" "acceso_az2" {
  function_name    = "${local.name_prefix}-acceso-az2"
  role             = aws_iam_role.lambda.arn
  handler          = "bootstrap"
  runtime          = "provided.al2"
  timeout          = 30
  memory_size      = 512
  filename         = local.lambda_acceso_zip
  source_code_hash = filebase64sha256(local.lambda_acceso_zip)

  vpc_config {
    subnet_ids         = [aws_subnet.compute["us-east-1b"].id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = merge(
      local.lambda_common_env,
      { BLOCKCHAIN_NODE_URL = var.lambda_node_url_az2 }
    )
  }

  reserved_concurrent_executions = 5

  depends_on = [aws_cloudwatch_log_group.lambda_acceso]
}

# Lambda Despachador - AZ1
resource "aws_lambda_function" "despachador_az1" {
  function_name    = "${local.name_prefix}-despachador-az1"
  role             = aws_iam_role.lambda.arn
  handler          = "bootstrap"
  runtime          = "provided.al2"
  timeout          = 30
  memory_size      = 256
  filename         = local.lambda_despachador_zip
  source_code_hash = filebase64sha256(local.lambda_despachador_zip)

  vpc_config {
    subnet_ids         = [aws_subnet.compute["us-east-1a"].id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      VOTE_QUEUE_URL = aws_sqs_queue.vote_queue.id
    }
  }

  reserved_concurrent_executions = 5

  depends_on = [aws_cloudwatch_log_group.lambda_despachador]
}

# Lambda Despachador - AZ2
resource "aws_lambda_function" "despachador_az2" {
  function_name    = "${local.name_prefix}-despachador-az2"
  role             = aws_iam_role.lambda.arn
  handler          = "bootstrap"
  runtime          = "provided.al2"
  timeout          = 30
  memory_size      = 256
  filename         = local.lambda_despachador_zip
  source_code_hash = filebase64sha256(local.lambda_despachador_zip)

  vpc_config {
    subnet_ids         = [aws_subnet.compute["us-east-1b"].id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      VOTE_QUEUE_URL = aws_sqs_queue.vote_queue.id
    }
  }

  reserved_concurrent_executions = 5

  depends_on = [aws_cloudwatch_log_group.lambda_despachador]
}

# Lambda Procesador - AZ1
resource "aws_lambda_function" "procesador_az1" {
  function_name    = "${local.name_prefix}-procesador-az1"
  role             = aws_iam_role.lambda.arn
  handler          = "bootstrap"
  runtime          = "provided.al2"
  timeout          = 300
  memory_size      = 1024
  filename         = local.lambda_procesador_zip
  source_code_hash = filebase64sha256(local.lambda_procesador_zip)

  vpc_config {
    subnet_ids         = [aws_subnet.compute["us-east-1a"].id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      BLOCKCHAIN_NODE_URL = var.lambda_node_url_az1
    }
  }

  reserved_concurrent_executions = 5

  depends_on = [aws_cloudwatch_log_group.lambda_procesador]
}

# Lambda Procesador - AZ2
resource "aws_lambda_function" "procesador_az2" {
  function_name    = "${local.name_prefix}-procesador-az2"
  role             = aws_iam_role.lambda.arn
  handler          = "bootstrap"
  runtime          = "provided.al2"
  timeout          = 300
  memory_size      = 1024
  filename         = local.lambda_procesador_zip
  source_code_hash = filebase64sha256(local.lambda_procesador_zip)

  vpc_config {
    subnet_ids         = [aws_subnet.compute["us-east-1b"].id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      BLOCKCHAIN_NODE_URL = var.lambda_node_url_az2
    }
  }

  reserved_concurrent_executions = 5

  depends_on = [aws_cloudwatch_log_group.lambda_procesador]
}

# SQS Event Source Mapping
resource "aws_lambda_event_source_mapping" "procesador_az1" {
  event_source_arn                   = aws_sqs_queue.vote_queue.arn
  function_name                      = aws_lambda_function.procesador_az1.arn
  batch_size                         = 10
  maximum_batching_window_in_seconds = 0
}

resource "aws_lambda_event_source_mapping" "procesador_az2" {
  event_source_arn                   = aws_sqs_queue.vote_queue.arn
  function_name                      = aws_lambda_function.procesador_az2.arn
  batch_size                         = 10
  maximum_batching_window_in_seconds = 0
}