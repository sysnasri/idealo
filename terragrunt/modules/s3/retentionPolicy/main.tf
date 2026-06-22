resource "aws_s3_bucket_lifecycle_configuration" "example" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    id = "rule-1"

    filter {
      prefix = "logs/"
    }

    # ... other transition/expiration actions ...

    status = "Enabled"
  }

  rule {
    id = "rule-2"

    filter {
      prefix = "tmp/"
    }

    # ... other transition/expiration actions ...

    status = "Enabled"
  }
}