// Declaration of variables
variable "aws_region" {
  description = "Main AWS region for PromptGPT app resources."
  type        = string
  default     = "eu-west-2"
}

variable "environment" {
  description = "Environment name for this Terraform deployment."
  type        = string
  default     = "preview"
}

variable "project" {
  description = "Project name."
  type        = string
  default     = "promptgpt"
}

variable "preview_domain" {
  description = "Public preview domain for CloudFront."
  type        = string
  default     = "preview-promptgpt.umezawa.info"
}

variable "frontend_bucket_name" {
  description = "S3 bucket for the preview frontend."
  type        = string
  default     = "promptgpt-preview-frontend"
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
  description = "GitHub Environment name used by deployment workflows."
  type        = string
  default     = "preview"
}
