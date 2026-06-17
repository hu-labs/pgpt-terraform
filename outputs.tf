output "acm_validation_records" {
  description = "Create these DNS records in external DNS to validate the CloudFront certificate."
  value = {
    for dvo in aws_acm_certificate.site.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
}

output "environment" {
  value = var.environment
}

output "name_prefix" {
  value = var.name_prefix
}

output "public_domain" {
  value = var.public_domain
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.site.domain_name
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.site.id
}

output "frontend_bucket_name" {
  value = aws_s3_bucket.frontend.bucket
}

output "lambda_function_name" {
  value = aws_lambda_function.backend.function_name
}

output "lambda_test_alias" {
  value = aws_lambda_alias.test.name
}

output "lambda_stable_alias" {
  value = aws_lambda_alias.stable.name
}

output "api_gateway_id" {
  value = aws_api_gateway_rest_api.api.id
}

output "api_gateway_test_url" {
  value = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.aws_region}.amazonaws.com/test/chat"
}

output "api_gateway_prod_url" {
  value = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.aws_region}.amazonaws.com/prod/chat"
}

output "public_api_url" {
  value = "https://${var.public_domain}/api/v1/chat"
}

output "vite_api_url" {
  value = "/api/v1/chat"
}

output "api_key_value" {
  value     = random_password.api_gateway_key.result
  sensitive = true
}

output "frontend_github_role_arn" {
  value = aws_iam_role.frontend_deploy.arn
}

output "backend_github_role_arn" {
  value = aws_iam_role.backend_deploy.arn
}
