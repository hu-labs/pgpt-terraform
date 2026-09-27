// users rulesets
resource "aws_cognito_user_pool" "users" {
  name           = local.cognito_user_pool_name
  user_pool_tier = "ESSENTIALS"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  username_configuration {
    case_sensitive = false
  }

  mfa_configuration = "OFF"

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  tags = local.common_tags
}

// browser app client rulesets
resource "aws_cognito_user_pool_client" "web" {
  name         = local.cognito_client_name
  user_pool_id = aws_cognito_user_pool.users.id

  // public client!
  generate_secret = false

  allowed_oauth_flows_user_pool_client = true
  // Authorization code (+ PKCE on the frontend)
  allowed_oauth_flows = ["code"]

  allowed_oauth_scopes = [
    "openid",
    "email",
    "profile",
  ]

  supported_identity_providers = [
    "COGNITO",
  ]

  callback_urls = local.cognito_callback_urls
  logout_urls   = local.cognito_logout_urls

  default_redirect_uri = "https://${var.public_domain}/"

  enable_token_revocation = true
}

resource "aws_cognito_user_pool_domain" "login" {
  domain       = local.cognito_domain_prefix
  user_pool_id = aws_cognito_user_pool.users.id
  // Newer managed login instead of old hosted UI.
  managed_login_version = 2
}

// With managed_login_version = 2, set your own 'themes'.
// For now, use AWS's default Managed Login theme.
resource "aws_cognito_managed_login_branding" "web" {
  user_pool_id = aws_cognito_user_pool.users.id
  client_id    = aws_cognito_user_pool_client.web.id

  use_cognito_provided_values = true

  depends_on = [
    aws_cognito_user_pool_domain.login
  ]
}
