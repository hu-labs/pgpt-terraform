moved {
  from = aws_api_gateway_method.post_chat
  to   = aws_api_gateway_method.chat_post
}

moved {
  from = aws_api_gateway_integration.post_chat_lambda
  to   = aws_api_gateway_integration.chat_lambda
}

moved {
  from = aws_api_gateway_method.options_chat
  to   = aws_api_gateway_method.chat_options
}

moved {
  from = aws_api_gateway_method_response.options_200
  to   = aws_api_gateway_method_response.chat_options
}

moved {
  from = aws_api_gateway_integration.options_mock
  to   = aws_api_gateway_integration.chat_options
}

moved {
  from = aws_api_gateway_integration_response.options_200
  to   = aws_api_gateway_integration_response.chat_options
}

moved {
  from = aws_lambda_permission.allow_test_api_gateway
  to   = aws_lambda_permission.chat_test
}

moved {
  from = aws_lambda_permission.allow_prod_api_gateway
  to   = aws_lambda_permission.chat_prod
}

resource "aws_api_gateway_resource" "chat" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "chat"
}

resource "aws_api_gateway_method" "chat_post" {
  rest_api_id      = aws_api_gateway_rest_api.api.id
  resource_id      = aws_api_gateway_resource.chat.id
  http_method      = "POST"
  authorization    = "COGNITO_USER_POOLS"
  authorizer_id    = aws_api_gateway_authorizer.cognito.id
  api_key_required = true
}

resource "aws_api_gateway_integration" "chat_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.chat.id
  http_method             = aws_api_gateway_method.chat_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2021-11-15/functions/${aws_lambda_function.backend.arn}:$${stageVariables.lambdaAlias}/response-streaming-invocations"
  response_transfer_mode  = "STREAM"
  timeout_milliseconds    = 300000
}

resource "aws_api_gateway_method" "chat_options" {
  rest_api_id      = aws_api_gateway_rest_api.api.id
  resource_id      = aws_api_gateway_resource.chat.id
  http_method      = "OPTIONS"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_method_response" "chat_options" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.chat.id
  http_method = aws_api_gateway_method.chat_options.http_method
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

resource "aws_api_gateway_integration" "chat_options" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.chat.id
  http_method = aws_api_gateway_method.chat_options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_api_gateway_integration_response" "chat_options" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.chat.id
  http_method = aws_api_gateway_method.chat_options.http_method
  status_code = aws_api_gateway_method_response.chat_options.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "stageVariables.allowedOrigin"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
  }
  depends_on = [aws_api_gateway_integration.chat_options]
}

resource "aws_lambda_permission" "chat_test" {
  statement_id  = "allow-test-api-gateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend.function_name
  qualifier     = aws_lambda_alias.test.name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/test/POST/chat"
}

resource "aws_lambda_permission" "chat_prod" {
  statement_id  = "allow-prod-api-gateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend.function_name
  qualifier     = aws_lambda_alias.stable.name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/prod/POST/chat"
}
