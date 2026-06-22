# -----------------------------------------------------------------------------
# Compliance scanning (detect-only) - EventBridge content filtering, no compute
#
# Flow: S3 PutObject -> EventBridge (s3:ObjectCreated:*) -> SNS (email)
#
# EventBridge's S3 "Object Created" event includes the object key, so an
# event pattern can match (and alert on) any upload whose key does NOT end
# in an allowed extension - entirely declaratively, no Lambda, no IAM role
# that reads object data, nothing to build or deploy.
#
# This deliberately covers extension/format only. The brief's other example
# - "missing metadata" - cannot be done this way: S3's EventBridge payload
# carries the key, size, etag, and version-id, but never the object's
# custom x-amz-meta-* headers, because metadata lives on the object itself,
# not on the bucket-level creation event. Detecting it would require an
# actual HeadObject call (compute), which is out of scope for this rule.
# See the module README for the full reasoning and what to do if a
# metadata check is genuinely needed later.
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_notification" "eventbridge" {
  count  = var.enable_compliance_scanning ? 1 : 0
  bucket = aws_s3_bucket.uploads.id

  eventbridge = true
}

resource "aws_sns_topic" "compliance_alerts" {
  count = var.enable_compliance_scanning ? 1 : 0
  name  = "${local.bucket_name}-compliance-alerts"
  tags  = var.tags
}

# EventBridge needs an explicit resource policy on the SNS topic before it's
# allowed to publish to it - unlike Lambda, where aws_lambda_permission
# grants the invoke right, SNS authorizes callers via its own topic policy.
resource "aws_sns_topic_policy" "allow_eventbridge" {
  count = var.enable_compliance_scanning ? 1 : 0
  arn   = aws_sns_topic.compliance_alerts[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowEventBridgePublish"
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sns:Publish"
      Resource  = aws_sns_topic.compliance_alerts[0].arn
      Condition = {
        ArnEquals = { "aws:SourceArn" = aws_cloudwatch_event_rule.non_compliant_extension[0].arn }
      }
    }]
  })
}

resource "aws_sns_topic_subscription" "compliance_alerts_email" {
  count     = var.enable_compliance_scanning && var.compliance_alert_email != null ? 1 : 0
  topic_arn = aws_sns_topic.compliance_alerts[0].arn
  protocol  = "email"
  endpoint  = var.compliance_alert_email
}

resource "aws_cloudwatch_event_rule" "non_compliant_extension" {
  count       = var.enable_compliance_scanning ? 1 : 0
  name        = "${local.bucket_name}-non-compliant-extension"
  description = "Matches uploads to ${local.bucket_name} whose key does NOT end in an allowed extension."

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = { name = [local.bucket_name] }
      object = {
        key = [
          { "anything-but" = { suffix = [for ext in var.allowed_extensions : ".${ext}"] } }
        ]
      }
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "sns" {
  count = var.enable_compliance_scanning ? 1 : 0
  rule  = aws_cloudwatch_event_rule.non_compliant_extension[0].name
  arn   = aws_sns_topic.compliance_alerts[0].arn

  # Without this, the email/log target gets the raw EventBridge JSON
  # envelope. The transformer reshapes it into the one-line, human-readable
  # message the brief asked for ("a log line is fine").
  input_transformer {
    input_paths = {
      bucket = "$.detail.bucket.name"
      key    = "$.detail.object.key"
      time   = "$.time"
    }
    input_template = "\"Non-compliant upload detected at <time>: s3://<bucket>/<key> - unexpected file extension (allowed: ${join(", ", var.allowed_extensions)})\""
  }
}

# CloudWatch tracks this natively via the rule's own invocation metrics -
# no custom metric needed since there's no Lambda computing one. Useful for
# a dashboard or an additional alarm without relying solely on email.
resource "aws_cloudwatch_metric_alarm" "non_compliant_uploads" {
  count               = var.enable_compliance_scanning ? 1 : 0
  alarm_name          = "${local.bucket_name}-non-compliant-uploads"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Invocations"
  namespace           = "AWS/Events"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_description   = "One or more uploads to ${local.bucket_name} had an unexpected file extension."
  alarm_actions       = var.compliance_alert_email != null ? [aws_sns_topic.compliance_alerts[0].arn] : []

  dimensions = {
    RuleName = aws_cloudwatch_event_rule.non_compliant_extension[0].name
  }

  tags = var.tags
}
