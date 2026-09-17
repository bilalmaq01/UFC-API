# --- Container registry ----------------------------------------------------
# Holds the Lambda image. Must exist and contain a pushed image BEFORE the
# Lambda below can be created (see the ordered apply steps in the README).

resource "aws_ecr_repository" "api" {
  name = "${var.project}-api"

  image_scanning_configuration {
    scan_on_push = true # free vulnerability scan each push
  }

  force_delete = true # lets `terraform destroy` remove the repo even if images remain
}

# --- Lambda execution role -------------------------------------------------
# The identity the function runs as. It only needs permission to write logs.

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "${var.project}-api-lambda-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# --- The function ----------------------------------------------------------

resource "aws_lambda_function" "api" {
  function_name = "${var.project}-api"
  role          = aws_iam_role.lambda_exec.arn

  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.api.repository_url}:${var.image_tag}"
  architectures = ["arm64"] # MUST match the Dockerfile's --platform=linux/arm64

  timeout     = 30  # seconds; generous headroom for a cold start + first DB query
  memory_size = 512 # MB; also scales CPU. Bump if the fuzzy-search cache build feels slow.

  environment {
    variables = {
      DATABASE_URL = var.database_url
      # pydantic-settings parses a list from a JSON string, so encode it as one.
      CORS_ORIGINS = jsonencode(var.cors_origins)
    }
  }
}

# --- HTTP API Gateway (the public front door) ------------------------------

resource "aws_apigatewayv2_api" "http" {
  name          = "${var.project}-api"
  protocol_type = "HTTP"
}

# AWS_PROXY = pass the raw request straight through to Lambda; FastAPI/Mangum
# do all the routing. payload v2.0 is what Mangum expects from an HTTP API.
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  payload_format_version = "2.0"
}

# Two routes so BOTH "/" and "/anything/else" reach the Lambda.
resource "aws_apigatewayv2_route" "proxy" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "root" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# $default auto-deploys changes, and its invoke URL has no stage-name suffix.
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true
}

# Without this, API Gateway is not allowed to call the function.
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}
