resource "aws_acm_certificate" "preview" {
  provider = aws.us_east_1

  domain_name       = var.preview_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = local.common_tags
}
