# Terraform for PromptGPT

## Overview

This repository contains Terraform configurations for infrastructure as code (IaC) deployment of PromptGPT.

Frontend / backend code is shipped through CI/CD in their respective repository.

## Structure
```
pgpt-terraform/
  modules/
    promptgpt-stack/
      versions.tf
      providers.tf
      variables.tf
      locals.tf
      outputs.tf
      acm.tf
      frontend_s3.tf
      backend_api_gateway.tf
      backend_lambda.tf
      iam_lambda.tf
      iam_github_actions.tf
      cloudfront.tf

  envs/
    deploy_name/
      main.tf
      outputs.tf
      terraform.tfvars
      backend.hcl
      .terraform.lock.hcl
      terraform.tfstate             # secure
      .terraform/                   # secure
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
* Initialize Terraform from the new preview root
   ```
   cd envs/deploy_name

   terraform init -backend-config=backend.hcl
   ```
   Or if the infra has been changed:
   ```
   terraform init -reconfigure -backend-config=backend.hcl
   ```
* Validate:
   ```
   terraform fmt
   terraform validate
   ```
* For a non-R53 DNS, run ACM certificate first:
   ```
   terraform plan \
      -target=module.promptgpt.aws_acm_certificate.site \
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
   terraform plan -out=full.tfplan
   terraform apply full.tfplan
   ```
* To destroy:
   ```
   terraform plan -destroy -out=destroy.tfplan
   terraform apply destroy.tfplan
   ```

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
