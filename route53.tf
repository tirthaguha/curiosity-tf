data "aws_route53_zone" "main" {
  name         = "${var.domain_name}."
  private_zone = false
}

resource "aws_route53_record" "alias_record" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site_cdn.domain_name
    zone_id                = aws_cloudfront_distribution.site_cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
