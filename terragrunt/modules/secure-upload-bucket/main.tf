terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4"
    }
  }
}

locals {
  bucket_name = "${var.name}-uploads"

  # S3 Standard handles unpredictable, bursty PUT rates natively (it auto-scales
  # request partitions), so there is no provisioning/capacity concern here -
  # this is exactly the workload S3 is designed for. The only real design
  # decisions are lifecycle (cost) and compliance detection (correctness).
}

# -----------------------------------------------------------------------------
# Bucket
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "uploads" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = var.kms_key_arn != null
  }
}

resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# Lifecycle: 30-day transition to cheaper storage, 365-day expiration
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    id     = "retention-and-cost-tiering"
    status = "Enabled"

    filter {} # applies to all objects in the bucket

    dynamic "transition" {
      for_each = var.transition_to_infrequent_access_days > 0 ? [1] : []
      content {
        days          = var.transition_to_infrequent_access_days
        storage_class = "GLACIER_IR"
      }
    }

    dynamic "expiration" {
      for_each = var.expiration_days > 0 ? [1] : []
      content {
        days = var.expiration_days
      }
    }

    # Versioning is on (good practice, protects against accidental overwrite/
    # delete), so we also clean up noncurrent versions - otherwise "deleted"
    # objects would linger forever and quietly cost money.
    dynamic "noncurrent_version_transition" {
      for_each = var.transition_to_infrequent_access_days > 0 ? [1] : []
      content {
        noncurrent_days = var.transition_to_infrequent_access_days
        storage_class   = "GLACIER_IR"
      }
    }

    dynamic "noncurrent_version_expiration" {
      for_each = var.expiration_days > 0 ? [1] : []
      content {
        noncurrent_days = var.expiration_days
      }
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

