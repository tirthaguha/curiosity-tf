terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # CloudFront certs must be in us-east-1
}

######################
# S3 bucket
######################
resource "aws_s3_bucket" "site_bucket" {
  bucket = "my-curiosity-site-bucket"

  tags = {
    Name = "CuriositySite"
  }
}

resource "aws_s3_bucket_public_access_block" "site_bucket_block" {
  bucket                  = aws_s3_bucket.site_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront OAI & S3 bucket policy
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for Curiosity site"
}

data "aws_iam_policy_document" "s3_cf_access" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site_policy" {
  bucket = aws_s3_bucket.site_bucket.id
  policy = data.aws_iam_policy_document.s3_cf_access.json
}

######################
# CloudFront
######################

data "aws_acm_certificate" "wildcard_cert" {
  domain      = "*.tirthaguha.net"
  statuses    = ["ISSUED"]
  most_recent = true
}

resource "aws_cloudfront_distribution" "site_cdn" {
  enabled             = true
  default_root_object = "index.html" # changed

  origin {
    domain_name = aws_s3_bucket.site_bucket.bucket_regional_domain_name
    origin_id   = "s3-origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }

    origin_path = "/curiosity/out" # changed
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-origin"

    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    # Caching: 1 hour
    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 3600
  }

  # Custom error response: now points to /index.html in origin path
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html" # changed
    error_caching_min_ttl = 0
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # viewer_certificate {
  #   cloudfront_default_certificate = true
  # }

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.wildcard_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  aliases = ["curiosity.tirthaguha.net"] # <-- Alternate domain name
}

######################
# Route 53 DNS record
######################
data "aws_route53_zone" "main" {
  name         = "tirthaguha.net."
  private_zone = false
}

resource "aws_route53_record" "curiosity_alias" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "curiosity.tirthaguha.net"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site_cdn.domain_name
    zone_id                = aws_cloudfront_distribution.site_cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

######################
# Output
######################
output "cloudfront_domain" {
  value = aws_cloudfront_distribution.site_cdn.domain_name
}
