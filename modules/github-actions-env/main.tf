resource "github_repository_environment" "frontend" {
  repository  = var.frontend_repo
  environment = var.github_environment
}

resource "github_repository_environment" "backend" {
  repository  = var.backend_repo
  environment = var.github_environment
}

resource "github_actions_environment_variable" "frontend" {
  for_each = var.frontend_variables

  repository    = var.frontend_repo
  environment   = github_repository_environment.frontend.environment
  variable_name = each.key
  value         = each.value
}

resource "github_actions_environment_variable" "backend" {
  for_each = var.backend_variables

  repository    = var.backend_repo
  environment   = github_repository_environment.backend.environment
  variable_name = each.key
  value         = each.value
}
