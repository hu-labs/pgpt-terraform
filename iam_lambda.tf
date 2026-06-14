resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.lambda_name}"
  retention_in_days = 14

  tags = local.common_tags
}

resource "aws_iam_role" "lambda_exec" {
  name = "${local.name_prefix}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "lambda_logs" {
  name = "${local.name_prefix}-lambda-logs"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "logs:CreateLogGroup"
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.lambda.arn}:*"
      }
    ]
  })
}

data "aws_secretsmanager_secret" "openai" {
  name = var.openai_secret_name
}

resource "aws_iam_role_policy" "openai_secret_read" {
  name = "${local.name_prefix}-openai-secret-read"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadOpenAISecret"
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = data.aws_secretsmanager_secret.openai.arn
      }
    ]
  })
}
