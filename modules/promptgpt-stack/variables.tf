// Declaration of variables
variable "aws_region" {
  description = "Main AWS region for app resources."
  type        = string
  default     = "eu-west-2"
}

variable "project" {
  description = "Project name."
  type        = string
  default     = "promptgpt"
}

variable "environment" {
  description = "Deployment environment/copy name, such as preview or production."
  type        = string
}

variable "name_prefix" {
  description = "Resource name prefix for this deployment copy."
  type        = string
}

variable "public_domain" {
  description = "Public CloudFront hostname for this deployment copy."
  type        = string
}

variable "frontend_bucket_name" {
  description = "S3 bucket name for this deployment's frontend."
  type        = string
}

variable "openai_secret_name" {
  description = "Existing Secrets Manager secret name used by the Lambda."
  type        = string
  default     = "openai/api-key"
}

variable "github_org" {
  description = "GitHub organization that owns the app repos."
  type        = string
  default     = "hu-labs"
}

variable "frontend_repo" {
  description = "Frontend GitHub repository name."
  type        = string
  default     = "pgpt-frontend"
}

variable "backend_repo" {
  description = "Backend GitHub repository name."
  type        = string
  default     = "pgpt-backend-lambda"
}

variable "github_environment" {
  description = "GitHub Environment name allowed to assume this deployment's AWS roles."
  type        = string
}
