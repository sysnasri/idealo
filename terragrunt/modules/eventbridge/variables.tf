variable "bus_name" {
  description = "The name of the EventBridge event bus"
  type        = string
}

variable "log_config" {
  description = "Logging configuration for the event bus"
  type = object({
    include_detail = optional(string, "FULL")
    level          = optional(string, "INFO")
  })
  default = {}
}

variable "log_delivery" {
  description = "Log delivery destinations for CloudWatch or S3"
  type = object({
    cloudwatch_logs = optional(object({
      destination_arn = string
    }))
    s3 = optional(object({
      destination_arn = string
    }))
  })
  default = {}
}

variable "rules" {
  description = "Map of EventBridge rules to create"
  type = map(object({
    description   = optional(string)
    event_pattern = string
    enabled       = optional(bool, true)
  }))
  default = {}
}

variable "targets" {
  description = "Map of targets for the EventBridge rules"
  type = map(list(object({
    name              = string
    arn               = string
    dead_letter_arn   = optional(string)
    input_transformer = optional(any) # Using any to support dynamic input_transformer map structures
  })))
  default = {}
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}