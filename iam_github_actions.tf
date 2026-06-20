data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

/*
locals {
  frontend_repo_full_name = "${var.github_org}/${var.frontend_repo}"
  backend_repo_full_name  = "${var.github_org}/${var.backend_repo}"
}*/

/*
    IAM roles for GitHub Actions
*/
resource "aws_iam_role" "frontend_deploy" {
  name = "${var.name_prefix}-frontend-github-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${local.frontend_repo_full_name}:environment:${var.github_environment}"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "frontend_deploy" {
  name = "${var.name_prefix}-frontend-deploy-policy"
  role = aws_iam_role.frontend_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListFrontendBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.frontend.arn
      },
      {
        Sid    = "WriteFrontendObjects"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.frontend.arn}/*"
      },
      {
        Sid    = "InvalidateSiteCloudFront"
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation"
        ]
        Resource = aws_cloudfront_distribution.site.arn
      }
    ]
  })
}

resource "aws_iam_role" "backend_deploy" {
  name = "${var.name_prefix}-backend-github-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${local.backend_repo_full_name}:environment:${var.github_environment}"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "backend_deploy" {
  name = "${var.name_prefix}-backend-deploy-policy"
  role = aws_iam_role.backend_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DeployLambdaCode"
        Effect = "Allow"
        Action = [
          "lambda:UpdateFunctionCode",
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration",
          "lambda:PublishVersion",
          "lambda:ListVersionsByFunction"
        ]
        Resource = aws_lambda_function.backend.arn
      },
      {
        Sid    = "ReadLambdaVersions"
        Effect = "Allow"
        Action = [
          "lambda:GetFunction"
        ]
        Resource = "${aws_lambda_function.backend.arn}:*"
      },
      {
        Sid    = "ManageLambdaAliases"
        Effect = "Allow"
        Action = [
          "lambda:GetAlias",
          "lambda:UpdateAlias"
        ]
        /* Apparently, AWS evaluates UpdateAlias against the function ARN, not the alias ARN
        Resource = [
          "${aws_lambda_function.backend.arn}:${aws_lambda_alias.test.name}",
          "${aws_lambda_function.backend.arn}:${aws_lambda_alias.stable.name}"
        ]*/
        
        Resource = aws_lambda_function.backend.arn
      }
    ]
  })
}
