# Terraform for PromptGPT

## Overview

This repository contains Terraform configurations for infrastructure as code (IaC) deployment of PromptGPT.

## Structure

- `main.tf` - Main Terraform configuration
- `variables.tf` - Variable definitions
- `outputs.tf` - Output definitions

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

* Initialize (with backend config file)
   ```
   terraform init -reconfigure -backend-config=envs/deploy_name.backend.hcl
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
      terraform output \
         -state=envs/state/deploy_name.tfstate \
         acm_validation_records
      ```
   Ensure DNS is set and certificate is live.
* A full run:   
   ```
   terraform plan \
   -var-file=envs/deploy_name.tfvars \
   -out=full.tfplan

   terraform apply full.tfplan
   ```

## Documentation

For detailed information about the infrastructure configuration, see individual `.tf` files.

## Contributing

Placeholder for contribution guidelines.

## License

Placeholder for license information.
