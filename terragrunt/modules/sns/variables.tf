variable "sns_topic_config" {
  type = object({
    name = string
    topic_policy_statements = map(object({
      actions = list(string)
      principals = list(object({
        type        = string
        identifiers = list(string)
      }))
      conditions = optional(list(object({
        test     = string
        variable = string
        values   = list(string)
      })), [])
    }))
    subscriptions = map(object({
      protocol = string
      endpoint = string
    }))
    tags = map(string)
  })
  description = "Configuration parameters for the platform SNS topic module"
}