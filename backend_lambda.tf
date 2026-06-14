data "archive_file" "lambda_placeholder_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-placeholder"
  output_path = "${path.module}/lambda-placeholder.zip"
}

resource "aws_lambda_function" "backend" {
  function_name = local.lambda_name
  role          = aws_iam_role.lambda_exec.arn
  handler       = "handler.handler"
  runtime       = "nodejs22.x"

  filename         = data.archive_file.lambda_placeholder_zip.output_path
  source_code_hash = data.archive_file.lambda_placeholder_zip.output_base64sha256

  publish = true

  memory_size = 1024
  timeout     = 20

  environment {
    variables = {
      OPENAI_SECRET_ID = var.openai_secret_name
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_logs,
    aws_iam_role_policy.openai_secret_read,
    aws_cloudwatch_log_group.lambda
  ]

  // Code is handled with CI/CD, so ignore.
  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
    ]
  }

  tags = local.common_tags
}

resource "aws_lambda_alias" "test" {
  name             = local.test_alias_name
  description      = "Latest test version"
  function_name    = aws_lambda_function.backend.function_name
  function_version = "$LATEST"
}

resource "aws_lambda_alias" "stable" {
  name             = local.stable_alias_name
  description      = "Stable version"
  function_name    = aws_lambda_function.backend.function_name
  function_version = aws_lambda_function.backend.version

  // Versions will be created outside TF, so ignore.
  lifecycle {
    ignore_changes = [
      function_version
    ]
  }
}
