# AWS IAM S3 Read Policy Generator

Creates an AWS IAM Policy that allows for a role to read a specific S3 Bucket.

Grants `s3:GetObject` and `s3:ListBucket` permissions on the bucket.

## Example

```terraform
module "iam_s3_read_policy" {
  source         = "./infrastructure/aws/utils/iam/policy-generators/s3/read"
  s3_bucket_name = "sample-bucket-name"
}
```

## Inputs

| Name | Type | Required | Description |
| ---- | ---- | -------- | ----------- |
|`s3_bucket_name`| string | Yes | Name of the S3 Bucket |

## Outputs

* `policy` - JSON encoded generated IAM policy.