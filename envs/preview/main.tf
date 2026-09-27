terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  backend "local" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    github = { // For GHA helper module
      source  = "integrations/github"
      version = "~> 6.12"
    }
  }
}

// Providers
provider "aws" {
  region = "eu-west-2"
}
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
provider "github" { // For GHA helper module
  owner = "hu-labs"
}

// Root module
module "promptgpt" {
  source = "../../modules/promptgpt-stack"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  aws_region         = "eu-west-2"
  project            = "promptgpt"
  openai_secret_name = "openai/api-key"

  environment          = "preview"
  name_prefix          = "promptgpt-preview"
  public_domain        = "promptgpt-preview.umezawa.info"
  frontend_bucket_name = "promptgpt-preview-frontend"

  github_environment = "preview"
  github_org         = "hu-labs"
  frontend_repo      = "pgpt-frontend"
  backend_repo       = "pgpt-backend-lambda"

  // Cognito calls from localhost for local development
  cognito_extra_callback_urls = [
    "http://localhost:5173/",
  ]
  cognito_extra_logout_urls = [
    "http://localhost:5173/",
  ]
}

// temporary variables to pass to the GHA helper module
locals {
  frontend_github_variables = {
    AWS_REGION                 = "eu-west-2"
    AWS_ROLE_ARN               = module.promptgpt.frontend_github_role_arn
    S3_BUCKET                  = module.promptgpt.frontend_bucket_name
    CLOUDFRONT_DISTRIBUTION_ID = module.promptgpt.cloudfront_distribution_id
    RELATIVE_API_URL           = module.promptgpt.relative_api_url
  }

  backend_github_variables = {
    AWS_REGION               = "eu-west-2"
    AWS_BACKEND_ROLE_ARN     = module.promptgpt.backend_github_role_arn
    AWS_LAMBDA_FUNCTION_NAME = module.promptgpt.lambda_function_name
    TEST_API_URL             = module.promptgpt.api_gateway_test_url
    PUBLIC_API_URL           = module.promptgpt.public_api_url
    TEST_ALIAS               = module.promptgpt.lambda_test_alias
    PROD_ALIAS               = module.promptgpt.lambda_stable_alias
  }
}

// GHA helper module to set environment variables
module "github_actions_env" {
  source = "../../modules/github-actions-env"

  github_environment = "preview" // GH environment name

  // GitHub repo names
  frontend_repo = "pgpt-frontend"
  backend_repo  = "pgpt-backend-lambda"

  // Assign the earlier defined local variables to the module inputs
  frontend_variables = local.frontend_github_variables
  backend_variables  = local.backend_github_variables
}
