# HTTP API Gateway v2 - Front para las Lambdas
resource "aws_apigatewayv2_api" "main" {
  name          = "${local.name_prefix}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins  = ["*"]
    allow_methods  = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers  = ["Content-Type", "Authorization", "X-User-Email", "X-User-Role"]
    expose_headers = ["Content-Type"]
    max_age        = 3600
  }

  tags = {
    Name = "${local.name_prefix}-api"
  }
}

resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    detailed_metrics_enabled = true
    logging_level            = "INFO"
  }
}

# Integration: Lambda Acceso (AZ1 y AZ2 comparten integración por backend)
resource "aws_apigatewayv2_integration" "acceso" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.acceso_az1.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "despachador" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.despachador_az1.arn
  payload_format_version = "2.0"
}

# Route: cualquier path a Lambda Acceso
resource "aws_apigatewayv2_route" "acceso" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /{proxy+}"

  target = "integrations/${aws_apigatewayv2_integration.acceso.id}"
}

# Route: /vote a Lambda Despachador
resource "aws_apigatewayv2_route" "despachador" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /vote"

  target = "integrations/${aws_apigatewayv2_integration.despachador.id}"
}

# Permisos API Gateway → Lambda
resource "aws_lambda_permission" "acceso_az1" {
  statement_id  = "AllowAPIGatewayInvokeAccesoAZ1"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.acceso_az1.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "acceso_az2" {
  statement_id  = "AllowAPIGatewayInvokeAccesoAZ2"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.acceso_az2.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "despachador_az1" {
  statement_id  = "AllowAPIGatewayInvokeDespAZ1"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.despachador_az1.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "despachador_az2" {
  statement_id  = "AllowAPIGatewayInvokeDespAZ2"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.despachador_az2.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}