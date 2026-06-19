/*
    It must remain empty because the config is fed in dynamically with
    terraform init -backend-config=envs/deploy_name.hcl
*/
terraform {
  backend "local" {}
}
