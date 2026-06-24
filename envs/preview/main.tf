// Dynamically configured with backend.hcl by init
terraform {
  backend "local" {}
}

// Version
terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
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

// Root module
module "promptgpt" {
  source = "../../modules/promptgpt-stack"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  aws_region           = "eu-west-2"
  project              = "promptgpt"
  environment          = "preview"
  name_prefix          = "promptgpt-preview"
  public_domain        = "promptgpt-preview.umezawa.info"
  frontend_bucket_name = "promptgpt-preview-frontend"
  openai_secret_name   = "openai/api-key"

  github_org         = "hu-labs"
  frontend_repo      = "pgpt-frontend"
  backend_repo       = "pgpt-backend-lambda"
  github_environment = "preview"
}
