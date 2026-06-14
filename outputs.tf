output "acm_validation_records" {
  description = "Create these DNS records to validate the CloudFront certificate."
  value = {
    for dvo in aws_acm_certificate.preview.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
}

output "preview_domain" {
  value = var.preview_domain
}
