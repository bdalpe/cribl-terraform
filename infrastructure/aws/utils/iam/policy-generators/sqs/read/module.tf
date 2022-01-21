variable "sqs_queue_name" {
  type = string
}

variable "allow_create_queue" {
  type = bool
  default = false
}

locals {
  # Build ARN of queue if only the name is passed
  queue_arn = length(regexall("^arn:.+", var.sqs_queue_name)) > 0 ? var.sqs_queue_name : "arn:aws:sqs:::${var.sqs_queue_name}"
}

output "policy" {
  value = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = flatten([
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          var.allow_create_queue ? ["sqs:CreateQueue"] : []
        ])
        Effect   = "Allow"
        Resource = local.queue_arn
      },
    ]
  })
}