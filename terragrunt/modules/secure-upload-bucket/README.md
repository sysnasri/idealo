# secure-upload-bucket

Self-service S3 bucket for user file uploads: encrypted, versioned, private
by default, with cost-tiered retention and a zero-compute, detect-only
EventBridge rule that flags uploads with an unexpected file extension.

See the repository root [README](../../README.md) for architecture
rationale and production-readiness notes.

## Usage

```hcl
module "user_uploads" {
  source = "../../modules/secure-upload-bucket"

  name = "checkout-receipts"
}
```

With compliance checks tuned for a specific team's needs:

```hcl
module "kyc_documents" {
  source = "../../modules/secure-upload-bucket"

  name = "kyc-documents"

  allowed_extensions     = ["pdf", "jpg", "png"]
  compliance_alert_email = "compliance-team@example.com"

  tags = {
    team = "kyc"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| name | Logical name, used as a resource-name prefix. Lowercase letters/numbers/hyphens. | `string` | n/a | yes |
| tags | Tags applied to all resources. | `map(string)` | `{}` | no |
| transition_to_infrequent_access_days | Days before objects move to Glacier Instant Retrieval. `0` disables. | `number` | `30` | no |
| expiration_days | Days before objects are permanently deleted. `0` disables. | `number` | `365` | no |
| enable_compliance_scanning | Deploy the EventBridge rule that flags unexpected extensions. | `bool` | `true` | no |
| allowed_extensions | Lowercase extensions (no dot) considered compliant. Must be non-empty. | `list(string)` | `["pdf","jpg","jpeg","png"]` | no |
| compliance_alert_email | Email to notify via SNS on a non-compliant upload. | `string` | `null` | no |
| force_destroy | Allow Terraform to delete a non-empty bucket. | `bool` | `false` | no |
| kms_key_arn | Customer-managed KMS key ARN. `null` uses SSE-S3. | `string` | `null` | no |

## Outputs

| Name | Description |
|---|---|
| bucket_id | Bucket name. |
| bucket_arn | Bucket ARN. |
| bucket_domain_name | Regional domain name for building upload URLs. |
| compliance_rule_name | Name of the EventBridge rule flagging unexpected extensions (`null` if disabled). |
| compliance_alarm_name | CloudWatch alarm name for non-compliant uploads (`null` if disabled). |
| compliance_sns_topic_arn | SNS topic ARN for compliance alerts - subscribe additional endpoints to it as needed (`null` if disabled). |

## How the compliance check works

```
S3 PutObject -> EventBridge rule (matches key NOT ending in an allowed
                extension) -> SNS topic -> email subscription
```

No Lambda, no compute, nothing to build or deploy beyond Terraform itself.
EventBridge's S3 "Object Created" event carries the object key, so the
rule's event pattern uses an `anything-but`/`suffix` match to select only
uploads whose key doesn't end in one of `allowed_extensions`. An
`input_transformer` on the EventBridge target reshapes the alert into a
plain one-line message before it reaches SNS, instead of the raw JSON
event envelope.

**This only covers the file-extension check.** It cannot check for missing
custom object metadata (e.g. "this upload should have had an `uploaded-by`
header but didn't") - S3's EventBridge payload includes the key, size,
etag, and version-id, but never the object's `x-amz-meta-*` headers, since
those live on the object itself rather than on the bucket-level creation
event. Confirming metadata presence requires an actual `HeadObject` call,
which means compute (a Lambda or similar) - genuinely out of scope for a
zero-compute design. See the root README's Architecture Decisions section
for the full reasoning and what to do if a metadata check becomes a real
requirement later.

## What this module does NOT do

- Define who can read/write to the bucket - attach your own bucket policy
  or grant access via IAM to roles that need it. The module outputs
  `bucket_arn` for exactly this purpose.
- Check anything about an object's metadata, content type validity beyond
  the key's extension, or file contents (malware, PII). Use GuardDuty
  Malware Protection for S3 or Macie alongside this module if you need
  those.
- Fix or remove non-compliant uploads automatically. The rule detects and
  alerts only - it never modifies, moves, or deletes an object.
