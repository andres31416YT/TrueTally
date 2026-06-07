output "sqs_queue_url"{
  value=aws_sqs_queue.vote_queue.id
}

output "sqs_queue_arn"{
  value=aws_sqs_queue.vote_queue.arn
}

output "sqs_dlq_url"{
  value=aws_sqs_queue.vote_dlq.id
}

output "sqs_dlq_arn"{
  value=aws_sqs_queue.vote_dlq.arn
}