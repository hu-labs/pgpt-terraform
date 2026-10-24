/*
    CloudWatch Log Group for Lambda
*/
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.lambda_name}"
  retention_in_days = 14

  tags = local.common_tags
}

/*
    IAM Role for Lambda Execution
 */
resource "aws_iam_role" "lambda_exec" {
  name = "${var.name_prefix}-lambda-exec-role"

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

/*
    IAM Role Policy for Lambda Logs
*/
resource "aws_iam_role_policy" "lambda_logs" {
  name = "${var.name_prefix}-lambda-logs"
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

/*
    AWS Secrets Manager Secret for OpenAI
*/
data "aws_secretsmanager_secret" "openai" {
  name = var.openai_secret_name
}

/*
    IAM Role Policy for OpenAI Secret Read
*/
resource "aws_iam_role_policy" "openai_secret_read" {
  name = "${var.name_prefix}-openai-secret-read"
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

/*
    IAM Role Policy for DynamoDB Conversations Table
*/
resource "aws_iam_role_policy" "lambda_conversations" {
  name = "${var.name_prefix}-lambda-conversations"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = aws_dynamodb_table.conversations.arn
      }
    ]
  })
}
