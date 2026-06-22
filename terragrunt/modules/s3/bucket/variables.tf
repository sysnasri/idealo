variable "s3_bucket_config" {
  type = object({
    bucket                   = string
    acl                      = string
    control_object_ownership = bool
    object_ownership         = string
    versioning = object({
      enabled = bool
    })
  })
  description = "Configuration parameters for the S3 bucket platform module"
}