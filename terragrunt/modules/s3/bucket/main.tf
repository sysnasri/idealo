module "bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = var.s3_bucket_config.bucket
  acl    = var.s3_bucket_config.acl

  control_object_ownership = var.s3_bucket_config.control_object_ownership
  object_ownership         = var.s3_bucket_config.object_ownership

  versioning = {
    enabled = var.s3_bucket_config.versioning.enabled
  }
}