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
    Deployment
*/
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    // What triggers a redeployment?
    // Hash configured inputs rather than provider-computed defaults, which can
    // change on the first refresh and cause a redundant deployment.
    redeployment = sha1(jsonencode({
      resources = [
        aws_api_gateway_resource.chat.id,
        aws_api_gateway_resource.threads.id,
        aws_api_gateway_resource.threads_proxy.id,
        aws_api_gateway_resource.presets.id,
        aws_api_gateway_resource.presets_proxy.id,
      ]
      authorizer = {
        type            = aws_api_gateway_authorizer.cognito.type
        provider_arns   = aws_api_gateway_authorizer.cognito.provider_arns
        identity_source = aws_api_gateway_authorizer.cognito.identity_source
      }
      methods = [for method in concat(
        [aws_api_gateway_method.chat_post, aws_api_gateway_method.chat_options],
        values(aws_api_gateway_method.threads_any),
        values(aws_api_gateway_method.threads_options),
        values(aws_api_gateway_method.presets_any),
        values(aws_api_gateway_method.presets_options),
        ) : {
        resource_id      = method.resource_id
        http_method      = method.http_method
        authorization    = method.authorization
        authorizer_id    = method.authorizer_id
        api_key_required = method.api_key_required
      }]
      streaming = [for integration in concat(
        [aws_api_gateway_integration.chat_lambda],
        values(aws_api_gateway_integration.threads_lambda),
        values(aws_api_gateway_integration.presets_lambda),
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
        [aws_api_gateway_integration.chat_options],
        values(aws_api_gateway_integration.threads_options),
        values(aws_api_gateway_integration.presets_options),
        ) : {
        resource_id          = integration.resource_id
        http_method          = integration.http_method
        type                 = integration.type
        request_templates    = integration.request_templates
        passthrough_behavior = integration.passthrough_behavior
      }]
      preflight_methods = [for response in concat(
        [aws_api_gateway_method_response.chat_options],
        values(aws_api_gateway_method_response.threads_options),
        values(aws_api_gateway_method_response.presets_options),
        ) : {
        resource_id         = response.resource_id
        http_method         = response.http_method
        status_code         = response.status_code
        response_parameters = response.response_parameters
        response_models     = response.response_models
      }]
      preflight_responses = [for response in concat(
        [aws_api_gateway_integration_response.chat_options],
        values(aws_api_gateway_integration_response.threads_options),
        values(aws_api_gateway_integration_response.presets_options),
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
    aws_api_gateway_integration.presets_lambda,
    aws_api_gateway_integration_response.presets_options,
    aws_lambda_permission.presets_test,
    aws_lambda_permission.presets_prod,
    aws_api_gateway_integration.chat_lambda,
    aws_api_gateway_integration_response.chat_options,
    aws_lambda_permission.chat_test,
    aws_lambda_permission.chat_prod,
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
