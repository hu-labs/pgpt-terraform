resource "random_password" "api_gateway_key" {
  length  = 40
  special = false
}

resource "aws_api_gateway_rest_api" "api" {
  name        = local.api_name
  description = "PromptGPT preview backend API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  api_key_source = "HEADER"

  tags = local.common_tags
}

// Cognito auth resource
resource "aws_api_gateway_authorizer" "cognito" {
  name = "${var.name_prefix}-cognito-authorizer"

  rest_api_id = aws_api_gateway_rest_api.api.id

  type          = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.users.arn]

  identity_source = "method.request.header.Authorization"
}

/*
    /CHAT endpoint
*/
resource "aws_api_gateway_resource" "chat" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "chat"
}

resource "aws_api_gateway_method" "post_chat" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.chat.id
  http_method = "POST"

  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  api_key_required = true
}

// Primary communication between API Gateway and Lambda for chat endpoint
resource "aws_api_gateway_integration" "post_chat_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.chat.id
  http_method             = aws_api_gateway_method.post_chat.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"

  // $${stageVariables.lambdaAlias} escaped (double $) to send the stage variable to Lambda
  uri = "arn:aws:apigateway:${var.aws_region}:lambda:path/2021-11-15/functions/${aws_lambda_function.backend.arn}:$${stageVariables.lambdaAlias}/response-streaming-invocations"
  //Buffered invoke: uri = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.backend.arn}:$${stageVariables.lambdaAlias}/invocations"

  response_transfer_mode = "STREAM"
  timeout_milliseconds   = 300000 // 5 minutes, matching Lambda timeout
}

/*
    OPTIONS/CORS
*/
resource "aws_api_gateway_method" "options_chat" {
  rest_api_id      = aws_api_gateway_rest_api.api.id
  resource_id      = aws_api_gateway_resource.chat.id
  http_method      = "OPTIONS"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.chat.id
  http_method = aws_api_gateway_method.options_chat.http_method
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

resource "aws_api_gateway_integration" "options_mock" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.chat.id
  http_method = aws_api_gateway_method.options_chat.http_method

  type = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }

  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_api_gateway_integration_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.chat.id
  http_method = aws_api_gateway_method.options_chat.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "stageVariables.allowedOrigin"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
  }

  depends_on = [
    aws_api_gateway_integration.options_mock
  ]
}

/*
    Lambda invoke permissions
*/
resource "aws_lambda_permission" "allow_test_api_gateway" {
  statement_id  = "allow-test-api-gateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend.function_name
  qualifier     = aws_lambda_alias.test.name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/test/POST/chat"
}

resource "aws_lambda_permission" "allow_prod_api_gateway" {
  statement_id  = "allow-prod-api-gateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend.function_name
  qualifier     = aws_lambda_alias.stable.name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/prod/POST/chat"
}

/*
    Deployment
*/
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id


  /*
resource "aws_api_gateway_method" "post_chat" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.chat.id

*/

  triggers = {
    // What triggers a redeployment?
    // Hash configured inputs rather than provider-computed defaults, which can
    // change on the first refresh and cause a redundant deployment.
    redeployment = sha1(jsonencode({
      resources = [
        aws_api_gateway_resource.chat.id,
        aws_api_gateway_resource.threads.id,
        aws_api_gateway_resource.threads_proxy.id,
      ]
      authorizer = {
        type            = aws_api_gateway_authorizer.cognito.type
        provider_arns   = aws_api_gateway_authorizer.cognito.provider_arns
        identity_source = aws_api_gateway_authorizer.cognito.identity_source
      }
      methods = [for method in concat(
        [aws_api_gateway_method.post_chat, aws_api_gateway_method.options_chat],
        values(aws_api_gateway_method.threads_any),
        values(aws_api_gateway_method.threads_options),
        ) : {
        resource_id      = method.resource_id
        http_method      = method.http_method
        authorization    = method.authorization
        authorizer_id    = method.authorizer_id
        api_key_required = method.api_key_required
      }]
      streaming = [for integration in concat(
        [aws_api_gateway_integration.post_chat_lambda],
        values(aws_api_gateway_integration.threads_lambda),
        ) : {
        resource_id             = integration.resource_id
        http_method             = integration.http_method
        integration_http_method = integration.integration_http_method
        type                    = integration.type
        uri                     = integration.uri
        response_transfer_mode  = integration.response_transfer_mode
        timeout_milliseconds    = integration.timeout_milliseconds
      }]
      preflight = [for integration in concat(
        [aws_api_gateway_integration.options_mock],
        values(aws_api_gateway_integration.threads_options),
        ) : {
        resource_id          = integration.resource_id
        http_method          = integration.http_method
        type                 = integration.type
        request_templates    = integration.request_templates
        passthrough_behavior = integration.passthrough_behavior
      }]
      preflight_methods = [for response in concat(
        [aws_api_gateway_method_response.options_200],
        values(aws_api_gateway_method_response.threads_options),
        ) : {
        resource_id         = response.resource_id
        http_method         = response.http_method
        status_code         = response.status_code
        response_parameters = response.response_parameters
        response_models     = response.response_models
      }]
      preflight_responses = [for response in concat(
        [aws_api_gateway_integration_response.options_200],
        values(aws_api_gateway_integration_response.threads_options),
        ) : {
        resource_id         = response.resource_id
        http_method         = response.http_method
        status_code         = response.status_code
        response_parameters = response.response_parameters
      }]
    }))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.threads_lambda,
    aws_api_gateway_integration_response.threads_options,
    aws_lambda_permission.threads_test,
    aws_lambda_permission.threads_prod,
    aws_api_gateway_integration.post_chat_lambda,
    aws_api_gateway_integration_response.options_200,
    aws_lambda_permission.allow_test_api_gateway,
    aws_lambda_permission.allow_prod_api_gateway,
  ]
}
/*
    Stages
*/
resource "aws_api_gateway_stage" "test" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
  stage_name    = "test"

  variables = {
    lambdaAlias   = aws_lambda_alias.test.name
    allowedOrigin = "http://localhost:5173"
  }

  tags = local.common_tags
}

resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
  stage_name    = "prod"

  variables = {
    lambdaAlias   = aws_lambda_alias.stable.name
    allowedOrigin = "https://${var.public_domain}"
  }

  tags = local.common_tags
}
/*
    Method settings
*/
resource "aws_api_gateway_method_settings" "test_all_methods" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.test.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = true
    logging_level          = "ERROR"
    data_trace_enabled     = true
    throttling_burst_limit = 5000
    throttling_rate_limit  = 10000
  }
}

resource "aws_api_gateway_method_settings" "prod_all_methods" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = true
    logging_level          = "ERROR"
    data_trace_enabled     = false
    throttling_burst_limit = 5000
    throttling_rate_limit  = 10000
  }
}
/*
    Usage plan and API key
*/
resource "aws_api_gateway_usage_plan" "usage_plan" {
  name = local.usage_plan_name

  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = aws_api_gateway_stage.test.stage_name
  }

  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = aws_api_gateway_stage.prod.stage_name
  }

  throttle_settings {
    burst_limit = 200
    rate_limit  = 100
  }

  quota_settings {
    limit  = 10000
    period = "MONTH"
  }

  tags = local.common_tags
}

resource "aws_api_gateway_api_key" "api_key" {
  name        = local.api_key_name
  description = "API key injected by CloudFront for PromptGPT preview"
  enabled     = true
  value       = random_password.api_gateway_key.result

  tags = local.common_tags
}

// "aws_api_gateway_usage_plan_key" = Usage plan LINKED to API key
resource "aws_api_gateway_usage_plan_key" "usage_plan_key" {
  key_id        = aws_api_gateway_api_key.api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan.id
}
