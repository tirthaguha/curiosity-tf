######################
# S3 bucket
######################
resource "aws_s3_bucket" "site_bucket" {
  # bucket = "my-curiosity-site-bucket"
  bucket = "${var.subdomain}-site-bucket"
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