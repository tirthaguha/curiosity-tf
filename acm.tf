data "aws_acm_certificate" "wildcard_cert" {
  domain      = "*.${var.domain_name}"
  statuses    = ["ISSUED"]
  most_recent = true
}
