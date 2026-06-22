module "sns_topic" {
  source  = "terraform-aws-modules/sns/aws"

  name                    = var.sns_topic_config.name
  topic_policy_statements = var.sns_topic_config.topic_policy_statements
  subscriptions           = var.sns_topic_config.subscriptions
  tags                    = var.sns_topic_config.tags
}