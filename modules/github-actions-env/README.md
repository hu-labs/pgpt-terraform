# GitHub Actions Module

A helper module for GH **Environment Variables** injection for convenience, with the preset variable names for the existing GitHub Actions workflows for both the frontend and backend.

## Usage
In a root module, include GH provider in ```terraform``` block:
```
terraform {

    ... etc
    
    github = {
        source  = "integrations/github"
        version = "~> 6.12"
    }
    
    ... etc
}
```
And assign the GH repo account:
```
provider "github" {
  owner = "hu-labs"
}
```
Use ```locals``` to tie variables from promptgpt module to GHA environment variables:
```
locals {
  frontend_github_variables = {
    AWS_REGION                 = "eu-west-2"
    AWS_ROLE_ARN               = module.promptgpt.frontend_github_role_arn
    S3_BUCKET                  = module.promptgpt.frontend_bucket_name
    CLOUDFRONT_DISTRIBUTION_ID = module.promptgpt.cloudfront_distribution_id
    VITE_API_URL               = module.promptgpt.vite_api_url
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
```
Import module:
```
module "github_actions_env" {
  source = "../../modules/github-actions-env"

  github_environment = "production" // GH environment name

  frontend_repo = "pgpt-frontend"
  backend_repo  = "pgpt-backend-lambda"

  frontend_variables = local.frontend_github_variables
  backend_variables  = local.backend_github_variables
}
```
Set ```GITHUB_TOKEN``` which is used by TF GitHub provider for authentication:
```
export GITHUB_TOKEN="$(gh auth token)"
```
\* Note ```TEST_API_KEY``` is a secret that needs to be added manually:
```
gh secret set TEST_API_KEY \
  --repo GH_ORG/BACKEND_REPO \
  --env production \
  --body "$(terraform output -raw api_key_value)"
```
