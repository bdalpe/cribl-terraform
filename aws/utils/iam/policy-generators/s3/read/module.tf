variable "s3_bucket_name" {
  type = string
}

locals {
  # Build ARN of bucket if only the name is passed
  bucket_arn = length(regexall("^arn:.+", var.s3_bucket_name)) > 0 ? var.s3_bucket_name : "arn:aws:s3:::${var.s3_bucket_name}"
}

output "policy" {
  value = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
        ]
        Effect   = "Allow"
        Resource = "${local.bucket_arn}/*"
      },
      {
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Effect   = "Allow"
        Resource = local.bucket_arn
      },
    ]
  })
}