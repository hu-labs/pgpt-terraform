resource "aws_api_gateway_resource" "threads" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "threads"
}

resource "aws_api_gateway_resource" "threads_proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.threads.id
  path_part   = "{proxy+}"
}

locals {
  thread_resource_ids = {
    root   = aws_api_gateway_resource.threads.id
    nested = aws_api_gateway_resource.threads_proxy.id
  }
}

resource "aws_api_gateway_method" "threads_any" {
  for_each = local.thread_resource_ids

  rest_api_id      = aws_api_gateway_rest_api.api.id
  resource_id      = each.value
  http_method      = "ANY"
  authorization    = "COGNITO_USER_POOLS"
  authorizer_id    = aws_api_gateway_authorizer.cognito.id
  api_key_required = true
}

resource "aws_api_gateway_integration" "threads_lambda" {
  for_each = local.thread_resource_ids

  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = each.value
  http_method             = aws_api_gateway_method.threads_any[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2021-11-15/functions/${aws_lambda_function.backend.arn}:$${stageVariables.lambdaAlias}/response-streaming-invocations"
  response_transfer_mode  = "STREAM"
  timeout_milliseconds    = 300000
}

resource "aws_api_gateway_method" "threads_options" {
  for_each = local.thread_resource_ids

  rest_api_id      = aws_api_gateway_rest_api.api.id
  resource_id      = each.value
  http_method      = "OPTIONS"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_method_response" "threads_options" {
  for_each = local.thread_resource_ids

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = each.value
  http_method = aws_api_gateway_method.threads_options[each.key].http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

resource "aws_api_gateway_integration" "threads_options" {
  for_each = local.thread_resource_ids

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = each.value
  http_method = aws_api_gateway_method.threads_options[each.key].http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_api_gateway_integration_response" "threads_options" {
  for_each = local.thread_resource_ids

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = each.value
  http_method = aws_api_gateway_method.threads_options[each.key].http_method
  status_code = aws_api_gateway_method_response.threads_options[each.key].status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "stageVariables.allowedOrigin"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PATCH,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Api-Key'"
  }
  depends_on = [aws_api_gateway_integration.threads_options]
}

resource "aws_lambda_permission" "threads_test" {
  statement_id  = "allow-test-api-gateway-threads"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend.function_name
  qualifier     = aws_lambda_alias.test.name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/test/*/threads*"
}

resource "aws_lambda_permission" "threads_prod" {
  statement_id  = "allow-prod-api-gateway-threads"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend.function_name
  qualifier     = aws_lambda_alias.stable.name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/prod/*/threads*"
}
