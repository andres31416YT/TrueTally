resource "aws_sqs_queue" "vote_queue" {
  name                       = "${local.name_prefix}-vote-queue"
  visibility_timeout_seconds = 300
  message_retention_seconds  = 1209600
  max_message_size           = 256000

  kms_master_key_id                 = aws_kms_key.main.arn
  kms_data_key_reuse_period_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.vote_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = "${local.name_prefix}-vote-queue"
  }
}

resource "aws_sqs_queue" "vote_dlq" {
  name                      = "${local.name_prefix}-vote-dlq"
  message_retention_seconds = 1209600
  kms_master_key_id         = aws_kms_key.main.arn

  tags = {
    Name = "${local.name_prefix}-vote-dlq"
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_queue_depth" {
  alarm_name          = "${local.name_prefix}-sqs-queue-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "60"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "SQS queue depth exceeds 100 messages"

  dimensions = {
    QueueName = aws_sqs_queue.vote_queue.name
  }
}