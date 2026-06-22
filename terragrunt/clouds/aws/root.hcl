#here we can have some common configs for aws cloud.



 ---------------------------------------------------------------------------------------------------------------------
# REMOTE STATE MANAGEMENT
# This configures Terragrunt to automatically create and manage the S3 backend for all child modules.
# ---------------------------------------------------------------------------------------------------------------------
# remote_state {
#   backend = "s3"
  
#   generate = {
#     path      = "backend.tf"
#     if_exists = "overwrite_terragrunt"
#   }

#   config = {
#     bucket         = "my-company-terraform-state-${local.aws_region}"
#     key            = "${path_relative_to_include()}/terraform.tfstate"
#     region         = local.aws_region
#     encrypt        = true
#     dynamodb_table = "my-company-terraform-locks"
    
#     # s3_bucket_tags = {
#     #   Owner       = "DevOps Team"
#     #   Environment = local.environment
#     # }

#     # dynamodb_table_tags = {
#     #   Owner       = "DevOps Team"
#     #   Environment = local.environment
#     # }
#   }
# }

# ---------------------------------------------------------------------------------------------------------------------
# PROVIDER GENERATION
# This injects the AWS provider configuration into every child module that inherits this root file.
# ---------------------------------------------------------------------------------------------------------------------
# generate "provider" {
#   path      = "provider.tf"
#   if_exists = "overwrite_terragrunt"
#   contents  = <<EOF
# provider "aws" {
#   region = "${local.aws_region}"

#   # Default tags to apply to all resources managed by this provider
#   default_tags {
#     tags = {
#       Environment = "${local.environment}"
#       ManagedBy   = "Terragrunt"
#     }
#   }
# }
# EOF
# }

# ---------------------------------------------------------------------------------------------------------------------
# # LOCALS
# # Define common variables/context used across your Terragrunt configurations.
# # ---------------------------------------------------------------------------------------------------------------------
# locals {
#   # You can parse these from environment variables or parent folder names
#   aws_region  = "us-east-1"
#   environment = "production"
# }