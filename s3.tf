resource "aws_s3_bucket" "site_bucket" {
  bucket = "${var.subdomain}-${var.domain_name}"
   tags = {
    Name = "CuriositySite"
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket                  = aws_s3_bucket.site_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
