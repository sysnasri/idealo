variable "secrets_manager_config" {
  type = object({
    name_prefix             = string
    description             = string
    recovery_window_in_days = optional(number, 30)
    
    # Policy configuration
    create_policy       = optional(bool, true)
    block_public_policy = optional(bool, true)
    policy_statements = optional(map(object({
      sid = string
      principals = list(object({
        type        = string
        identifiers = list(string)
      }))
      actions   = list(string)
      resources = list(string)
    })), {})

    # Secret Content configuration
    create_random_password           = optional(bool, true)
    random_password_length           = optional(number, 64)
    random_password_override_special = optional(string, "!@#$%^&*()_+")

    tags = map(string)
  })
  description = "Configuration parameters for the platform Secrets Manager module"
}