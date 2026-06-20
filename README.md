# Terraform for PromptGPT

## Overview

This repository contains Terraform configurations for infrastructure as code (IaC) deployment of PromptGPT.

Frontend / backend code is shipped through CI/CD in their respective repository.

## Structure
```
acm.tf
backend_api_gateway.tf
backend_lambda.tf
backend.tf
cloudfront.tf
frontend_s3.tf
iam_github_actions.tf
iam_lambda.tf
locals.tf
outputs.tf
providers.tf
variables.tf
```
## Getting Started

### Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials

### Prepare project specific files
For each deployment, create ```env/deploy_name.tfvars``` and ```env/deploy_name.backend.hcl```.

```env/deploy_name.backend.hcl```:
```
path = "envs/state/preview.tfstate"
```
```env/deploy_name.tfvars```:
```
aws_region = "eu-west-2"

project      = "project_name"
environment  = "production"
name_prefix  = "tag-prefix"
public_domain = "production-name.domain.com"

frontend_bucket_name = "name-production-frontend"

github_org         = "gh-name"
frontend_repo      = "name-frontend"
backend_repo       = "name-backend-lambda"
github_environment = "production"

openai_secret_name = "openai/api-key"
```
### Usage

For the first deployment:

* Initialize (with backend config file)
   ```
   terraform init -backend-config=envs/deploy_name.backend.hcl
   ```
* Validate:
   ```
   terraform fmt
   terraform validate
   ```
* For a non-R53 DNS, run ACM certificate first:
   ```
   terraform plan \
   -var-file=envs/deploy_name.tfvars \
   -target=aws_acm_certificate.site \
   -out=cert.tfplan
   ```
   Review, then:
   ```
   terraform apply cert.tfplan
   ```
   * Output the validation record if it hasn't:
      ```
      terraform output acm_validation_records
      ```
   Ensure DNS is set and certificate is live.
* A full run:   
   ```
   terraform plan \
   -var-file=envs/deploy_name.tfvars \
   -out=full.tfplan

   terraform apply full.tfplan
   ```
* For other deployments beyond the 1st, use the appropriate backend config file with ```reconfigure``` flag:
   ```
   terraform init -reconfigure -backend-config=envs/deploy_name.hcl
   ```
* To destroy:
   ```
   terraform plan \
   -destroy \
   -var-file=envs/deploy_name.tfvars \
   -out=destroy-preview.tfplan

   terraform apply destroy-preview.tfplan
   ```

## Documentation

For detailed information about the infrastructure configuration, see individual `.tf` files.

## Product Lifecycle
Terraform manages the infra.

Frontend / backend code is shipped through CI/CD from their respective repos.
```
Frontend:
  Deploy Frontend
  Rollback Frontend by run_id

Backend:
  Deploy Backend
  Promote Backend (Save an immutable lambda version and point the production Alias to it)
  Rollback Backend by target version

Terraform:
  envs/deploy_name.tfvars
  envs/deploy_name.backend.hcl
  envs/state/deploy_name.tfstate
```
