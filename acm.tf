/*
  For non-Route 53 DNS validation

  Before a full apply, run the 1st pass as:
    terraform apply -target=aws_acm_certificate.preview
    terraform output acm_validation_records
  
  Then add CNAME/Value pairs to the DNS record before the full terraform apply.
*/
resource "aws_acm_certificate" "preview" {
  provider = aws.us_east_1

  domain_name       = var.preview_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = local.common_tags
}

resource "aws_acm_certificate_validation" "preview" {
  provider = aws.us_east_1

  certificate_arn = aws_acm_certificate.preview.arn

  validation_record_fqdns = [
    for dvo in aws_acm_certificate.preview.domain_validation_options : dvo.resource_record_name
  ]
}

