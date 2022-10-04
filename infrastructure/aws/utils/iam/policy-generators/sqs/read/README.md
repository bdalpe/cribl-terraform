# AWS IAM SQS Read Policy Generator

Creates an AWS IAM Policy that allows for a role to read events from a specific SQS Queue.

Grants the following permissions:

* `sqs:ReceiveMessage`
* `sqs:DeleteMessage`
* `sqs:GetQueueAttributes`
* `sqs:GetQueueUrl`
* `sqs:CreateQueue` (Optional)

## Example

```terraform
module "iam_sqs_read_policy" {
  source             = "./infrastructure/aws/utils/iam/policy-generators/sqs/read"
  sqs_queue_name     = "sample-queue-name"
  allow_create_queue = true  # Optional
}
```

## Inputs

| Name | Type | Required | Description                                                 |
| ---- | ---- | -------- |-------------------------------------------------------------|
|`sqs_queue_name`| string | Yes | Name of the SQS Queue                                       |
|`allow_create_queue`| bool | No | Allows Cribl Stream to create a queue if it does not exist. |

## Outputs

* `policy` - JSON encoded generated IAM policy.