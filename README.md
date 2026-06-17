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

### Usage

* Initialize & validate:
   ```
   terraform init
   terraform fmt
   terraform validate
   ```
* For a non-R53 DNS, run ACM certificate first:
   ```
   terraform plan \
   -state=envs/state/production.tfstate \
   -var-file=envs/production.tfvars \
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
         -state=envs/state/preview.tfstate \
         acm_validation_records
      ```
   Ensure DNS is set and certificate is live.
* A full run:   
   ```
   terraform plan \
   -state=envs/state/production.tfstate \
   -var-file=envs/production.tfvars \
   -out=full.tfplan

   terraform apply full.tfplan
   ```


## Documentation

For detailed information about the infrastructure configuration, see individual `.tf` files.

## Contributing

Placeholder for contribution guidelines.

## License

Placeholder for license information.
