# AWS IAM S3 Read for Policy Generator

Creates an AWS IAM Policy that allows for a role to read for a specific S3 Bucket.

Grants `s3:GetObject` and `s3:ListBucket` permissions on the bucket.

## Example

```terraform
module "eks_odic_provider" {
  source         = "./infrastructure/aws/utils/iam/policy-generators/s3/read"
  s3_bucket_name = "sample-bucket-name"
}
```

## Outputs

* `policy` - JSON encoded generated IAM policy.