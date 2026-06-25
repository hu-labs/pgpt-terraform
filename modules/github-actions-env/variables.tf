variable "github_environment" {
  type = string
}

variable "frontend_repo" {
  type = string
}

variable "backend_repo" {
  type = string
}

variable "frontend_variables" {
  type = map(string)
}

variable "backend_variables" {
  type = map(string)
}
