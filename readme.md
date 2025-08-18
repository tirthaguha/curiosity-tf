```bash
terraform init
```
```bash
terraform plan
```
```bash
terraform apply
```

```bash
aws s3 mb s3://curiosity-terraform-state-bucket --region us-east-1
aws s3api put-bucket-versioning --bucket my-terraform-state-bucket --versioning-configuration Status=Enabled
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```