# Terraform for PromptGPT

## Overview

This repository contains Terraform configurations for infrastructure as code (IaC) deployment of PromptGPT on aws.

Production code (frontend & backend) is managed and shipped separately.

## Modules

- [modules/promptgpt-stack](modules/promptgpt-stack/README.md) — main infrastructure module that creates the PromptGPT AWS stack.
- [modules/github-actions-env](modules/github-actions-env/README.md) — helper module for injecting GitHub environment variables into frontend/backend repositories.

## Key AWS resources managed by this repository

This Terraform repository owns and manages the core AWS resources for a PromptGPT deployment, including:

- S3 frontend bucket for the static site
- CloudFront distribution with custom domain and certificate integration
- Origin access control and caching behaviors for frontend and API traffic
- API Gateway REST API with `/chat` route, CORS handling, usage plan, and API key
- Lambda function for the backend application, plus `test` and `stable` aliases
- IAM roles and policies for Lambda execution, GitHub Actions deployment, and related access
- ACM certificate validation records for the public CloudFront domain
- CloudWatch log groups for Lambda logging

## Structure
```
pgpt-terraform/
  modules/
    promptgpt-stack/
      cloudfront/rewrite-api-v1-to-prod.js
      lambda-placeholder/handler.js                => dummy function
      acm.tf
      backend_api_gateway.tf
      backend_lambda.tf
      cloudfront.tf
      frontend_s3.tf
      iam_github_actions.tf
      iam_lambda.tf
      locals.tf
      outputs.tf
      variables.tf
      versions.tf
   github-actions-env/
      main.tf
      README.md
      variables.tf
      versions.tf

    github-actions-env/
      main.tf
      variables.tf
      versions.tf

  envs/
    deploy_name/
      main.tf                 => customize
      outputs.tf              => customize
      backend.hcl             => constant
```
## Getting Started

### Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials

### Prepare project specific files
* ```backend.hcl```:
   ```
   path = "terraform.tfstate"
   ```
* Customize ```main.tf``` and ```outputs.tf```.

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
* CloudFront: for a non-R53 DNS, run ACM block first:
   ```
   terraform plan \
      -target=module.promptgpt.aws_acm_certificate.site \
      -out=cert.tfplan
   ```
   Review, then:
   ```
   terraform apply cert.tfplan
   ```
   * Output the validation record if not shown:
      ```
      terraform output acm_validation_records
      ```
      Set DNS CName and check certificate is issued:
      ```
      aws acm list-certificates --region us-east-1 --query "CertificateSummaryList[*].[DomainName,Status]"
      ```
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

## Product Lifecycle (PGPT)
Terraform manages the infra.

Frontend / backend code is shipped through CI/CD from their respective repositories.
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
