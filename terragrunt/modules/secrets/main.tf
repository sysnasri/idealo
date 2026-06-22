module "secret" {
  source = "terraform-aws-modules/secrets-manager/aws"

  name_prefix             = var.secrets_manager_config.name_prefix
  description             = var.secrets_manager_config.description
  recovery_window_in_days = var.secrets_manager_config.recovery_window_in_days

  create_policy       = var.secrets_manager_config.create_policy
  block_public_policy = var.secrets_manager_config.block_public_policy
  policy_statements   = var.secrets_manager_config.policy_statements

  create_random_password           = var.secrets_manager_config.create_random_password
  random_password_length           = var.secrets_manager_config.random_password_length
  random_password_override_special = var.secrets_manager_config.random_password_override_special

  tags = var.secrets_manager_config.tags
}