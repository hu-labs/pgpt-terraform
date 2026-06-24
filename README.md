# Terraform for PromptGPT

## Overview

This repository contains Terraform configurations for infrastructure as code (IaC) deployment of PromptGPT.

Frontend / backend code is shipped through CI/CD in their respective repository.

## Structure
```
pgpt-terraform/
  modules/
    promptgpt-stack/
      cloudfront/
      lambda-placeholder/
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
