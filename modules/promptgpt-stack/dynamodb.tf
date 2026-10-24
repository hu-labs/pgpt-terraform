resource "aws_dynamodb_table" "conversations" {
  name                        = "${var.name_prefix}-conversations"
  billing_mode                = "PROVISIONED"
  read_capacity               = 5
  write_capacity              = 10
  hash_key                    = "PK"
  range_key                   = "SK"
  table_class                 = "STANDARD"
  deletion_protection_enabled = var.environment == "production"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  point_in_time_recovery {
    enabled = false
  }

  tags = local.common_tags
}
