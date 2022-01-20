# AWS IAM S3 Write Policy Generator

Creates an AWS IAM Policy that allows for a role to write to a specific S3 Bucket.

Grants `s3:PutObject`, `s3:GetBucketLocation`, and `s3:ListBucket` permissions on the bucket.

## Example

```terraform
module "iam_s3_write_policy" {
  source         = "./infrastructure/aws/utils/iam/policy-generators/s3/write"
  s3_bucket_name = "sample-bucket-name"
}
```

## Inputs

| Name | Type | Required | Description |
| ---- | ---- | -------- | ----------- |
|`s3_bucket_name`| string | Yes | Name of the S3 Bucket |

## Outputs

* `policy` - JSON encoded generated IAM policy.