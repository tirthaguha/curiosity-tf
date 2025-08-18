terraform {
  backend "s3" {
    bucket         = "curiosity-terraform-state-bucket"     # Must already exist
    key            = "curiosity-site/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"               # Must already exist
    encrypt        = true
  }
}
