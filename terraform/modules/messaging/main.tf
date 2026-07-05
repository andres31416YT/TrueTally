locals {
  name_prefix = "${var.project_name}-${var.env}"
}

resource "aws_sqs_queue" "vote_queue" {
  name                       = "${local.name_prefix}-vote-queue"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 1209600
  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "dlq" {
  name                       = "${local.name_prefix}-vote-dlq"
  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300
}

output "vote_queue_url" {
  value = aws_sqs_queue.vote_queue.url
}

output "vote_queue_arn" {
  value = aws_sqs_queue.vote_queue.arn
}

output "dlq_arn" {
  value = aws_sqs_queue.dlq.arn
}