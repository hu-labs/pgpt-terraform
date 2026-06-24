#!/usr/bin/env bash
terraform init -reconfigure -backend-config=envs/preview.backend.hcl

terraform plan \
  -var-file=envs/preview.tfvars \
  -out=checkup-preview.tfplan
