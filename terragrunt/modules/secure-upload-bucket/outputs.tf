output "bucket_id" {
  description = "Name of the S3 bucket."
  value       = aws_s3_bucket.uploads.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = aws_s3_bucket.uploads.arn
}

output "bucket_domain_name" {
  description = "Regional domain name of the bucket, useful for constructing upload URLs."
  value       = aws_s3_bucket.uploads.bucket_regional_domain_name
}

output "compliance_rule_name" {
  description = "Name of the EventBridge rule that flags uploads with an unexpected extension (null if compliance scanning is disabled)."
  value       = var.enable_compliance_scanning ? aws_cloudwatch_event_rule.non_compliant_extension[0].name : null
}

output "compliance_alarm_name" {
  description = "Name of the CloudWatch alarm that fires on non-compliant uploads (null if compliance scanning is disabled)."
  value       = var.enable_compliance_scanning ? aws_cloudwatch_metric_alarm.non_compliant_uploads[0].alarm_name : null
}

output "compliance_sns_topic_arn" {
  description = "ARN of the SNS topic that receives compliance alerts - subscribe additional endpoints (Slack, PagerDuty, etc.) to it as needed (null if compliance scanning is disabled)."
  value       = var.enable_compliance_scanning ? aws_sns_topic.compliance_alerts[0].arn : null
}
