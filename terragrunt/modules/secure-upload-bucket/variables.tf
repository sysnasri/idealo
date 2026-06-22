variable "name" {
  description = "Logical name for this upload bucket, used as a prefix for resource names (e.g. \"customer-invoices\"). Must be DNS-compatible: lowercase letters, numbers, and hyphens only."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,40}$", var.name))
    error_message = "name must be 2-41 chars, lowercase letters/numbers/hyphens, starting with a letter or number."
  }
}

variable "tags" {
  description = "Tags applied to all resources created by this module."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Lifecycle / retention
# ---------------------------------------------------------------------------

variable "transition_to_infrequent_access_days" {
  description = "Days after upload before objects move to a cheaper, infrequent-access storage class. Set to 0 to disable the transition and keep everything in S3 Standard."
  type        = number
  default     = 30

  validation {
    condition     = var.transition_to_infrequent_access_days >= 0
    error_message = "transition_to_infrequent_access_days must be >= 0."
  }
}

variable "expiration_days" {
  description = "Days after upload before objects are permanently deleted. Set to 0 to disable expiration and retain objects indefinitely."
  type        = number
  default     = 365

  validation {
    condition     = var.expiration_days >= 0
    error_message = "expiration_days must be >= 0."
  }
}

# ---------------------------------------------------------------------------
# Compliance scanning (detect-only)
# ---------------------------------------------------------------------------

variable "enable_compliance_scanning" {
  description = "Whether to deploy the EventBridge rule that flags uploads with an unexpected file extension. Detect-only — it never modifies or deletes objects, and involves no compute (EventBridge content filtering routes directly to SNS)."
  type        = bool
  default     = true
}

variable "allowed_extensions" {
  description = "Lowercase file extensions (without the dot) considered compliant, e.g. [\"pdf\", \"jpg\", \"png\"]. Uploads whose key doesn't end in one of these raise an alert. Only enforced when enable_compliance_scanning is true. Must contain at least one extension - if you want no extension check at all, set enable_compliance_scanning = false instead of emptying this list."
  type        = list(string)
  default     = ["pdf", "jpg", "jpeg", "png"]

  validation {
    condition     = length(var.allowed_extensions) > 0
    error_message = "allowed_extensions cannot be empty - set enable_compliance_scanning = false to disable the check entirely."
  }
}

variable "compliance_alert_email" {
  description = "Optional email address to notify (via SNS) when a non-compliant upload is detected. Leave null to rely on the CloudWatch alarm/metric only (e.g. if you'll attach your own SNS subscription)."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Security knobs (sensible defaults, rarely need to change)
# ---------------------------------------------------------------------------

variable "force_destroy" {
  description = "If true, allows Terraform to delete the bucket even if it still contains objects. Leave false in production; useful for ephemeral/test environments."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "ARN of a customer-managed KMS key to encrypt objects with. Leave null to use SSE-S3 (AES256), which is sufficient for most workloads and has no extra cost or key-management overhead."
  type        = string
  default     = null
}
