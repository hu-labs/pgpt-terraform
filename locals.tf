data "aws_caller_identity" "current" {}

locals {
  lambda_name     = "${var.name_prefix}-lambda"
  api_name        = "${var.name_prefix}-api"
  usage_plan_name = "${var.name_prefix}-usage-plan"
  api_key_name    = "${var.name_prefix}-api-key"

  frontend_origin = "${var.name_prefix}-frontend-s3"
  backend_origin  = "${var.name_prefix}-backend-api"

  test_alias_name   = "Pgpt-lambda-test"
  stable_alias_name = "Pgpt-Lambda-stable"

  frontend_repo_full_name = "${var.github_org}/${var.frontend_repo}"
  backend_repo_full_name  = "${var.github_org}/${var.backend_repo}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
