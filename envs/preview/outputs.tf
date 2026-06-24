output "acm_validation_records" {
  value = module.promptgpt.acm_validation_records
}

output "public_api_url" {
  value = module.promptgpt.public_api_url
}

output "api_gateway_test_url" {
  value = module.promptgpt.api_gateway_test_url
}

output "api_key_value" {
  value     = module.promptgpt.api_key_value
  sensitive = true
}

output "lambda_function_name" {
  value = module.promptgpt.lambda_function_name
}

output "lambda_test_alias" {
  value = module.promptgpt.lambda_test_alias
}

output "lambda_stable_alias" {
  value = module.promptgpt.lambda_stable_alias
}

output "frontend_bucket_name" {
  value = module.promptgpt.frontend_bucket_name
}

output "cloudfront_distribution_id" {
  value = module.promptgpt.cloudfront_distribution_id
}

output "frontend_github_role_arn" {
  value = module.promptgpt.frontend_github_role_arn
}

output "backend_github_role_arn" {
  value = module.promptgpt.backend_github_role_arn
}

output "api_gateway_id" {
  value = module.promptgpt.api_gateway_id
}

output "api_gateway_prod_url" {
  value = module.promptgpt.api_gateway_prod_url
}

output "cloudfront_domain_name" {
  value = module.promptgpt.cloudfront_domain_name
}

output "environment" {
  value = module.promptgpt.environment
}

output "name_prefix" {
  value = module.promptgpt.name_prefix
}

output "public_domain" {
  value = module.promptgpt.public_domain
}

output "vite_api_url" {
  value = module.promptgpt.vite_api_url
}
