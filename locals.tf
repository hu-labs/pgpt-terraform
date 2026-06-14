data "aws_caller_identity" "current" {}

locals {
  name_prefix = "${var.project}-${var.environment}"

  lambda_name      = "${local.name_prefix}-lambda"
  api_name         = "${local.name_prefix}-api"
  usage_plan_name  = "${local.name_prefix}-usage-plan"
  api_key_name     = "${local.name_prefix}-api-key"
  frontend_origin  = "${local.name_prefix}-frontend-s3"
  backend_origin   = "${local.name_prefix}-backend-api"

  test_alias_name   = "Pgpt-lambda-test"
  stable_alias_name = "Pgpt-Lambda-stable"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
