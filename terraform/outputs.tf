output "s3_bucket_name" {
  value = aws_s3_bucket.log_bucket.bucket
}

output "sns_topic_arn" {
  value = aws_sns_topic.log_alerts.arn
}

output "grafana_public_ip" {
  value = aws_instance.grafana_server.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.mysql.endpoint
}

output "cloudwatch_log_group" {
  value = aws_cloudwatch_log_group.log_group.name
}
