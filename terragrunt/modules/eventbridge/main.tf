module "eventbridge" {
  source = "terraform-aws-modules/eventbridge/aws"

  bus_name     = var.bus_name
  log_config   = var.log_config
  log_delivery = var.log_delivery
  rules        = var.rules
  targets      = var.targets
  tags         = var.tags
}