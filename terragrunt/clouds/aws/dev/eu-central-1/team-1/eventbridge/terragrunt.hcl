terraform {
  source = "../../../modules/eventbridge"
}

# Automatically find and include root terragrunt.hcl configuration (State/Providers)
include "root" {
  path = find_in_parent_folders()
}


# 3. DEPENDENCY BLOCK
# Safely pulls resource attributes from another live module (e.g., dedicated KMS key for encryption)
dependency "cloudwatch" {
  config_path = "../path/to/cloudwatch/resource"

  # Mock outputs ensure 'terragrunt plan' works before the kms module is actually applied

}

inputs = {
  bus_name = "${local.project}-${local.environment}-event-bus"

  # Map matching the 'log_config' object variable structure
  log_config = {
    include_detail = "FULL"
    level          = "INFO"
  }

  # Map matching the 'log_delivery' nested destination structure
  log_delivery = {
    cloudwatch_logs = {
      destination_arn = dependency.cloudwatch.outputs.log_group_arn
    }
    # Left as null/omitted since we are writing primarily to CloudWatch logs
    s3 = null 
  }

  # Map of objects defining the non-compliant event rules matching your assignment scenario
  rules = {
    detect_non_compliant_uploads = {
      description   = "Rule that captures non-compliant file extensions or missing metadata flags"
      enabled       = true
      # Pattern detects S3 Object Created alerts where the file suffix is a disallowed format (e.g., .exe)
      event_pattern = jsonencode({
        source      = ["aws.s3"]
        detail-type = ["Object Created"]
        detail = {
          bucket = {
            name = [dependency.s3.outputs.bucket_name]
          }
          object = {
            key = [{ suffix = ".exe" }, { suffix = ".bat" }, { suffix = ".sh" }]
          }
        }
      })
    }
  }