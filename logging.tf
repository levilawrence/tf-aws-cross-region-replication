# create log bucket
resource "aws_s3_bucket" "log_bucket" {
  provider      = aws.source
  bucket_prefix = var.log_prefix
  force_destroy = true

  tags = merge(
    {
      "Name" = "Log Bucket"
    },
    var.tags,
  )
}

# enable acl
resource "aws_s3_bucket_acl" "log_bucket_acl" {
  provider      = aws.source
  bucket = aws_s3_bucket.log_bucket.id
  acl    = "log-delivery-write"
}

# enable versioning
resource "aws_s3_bucket_versioning" "log_bucket" {
  provider = aws.source
  bucket = aws_s3_bucket.log_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# enable server side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "logging_server_side_encryption" {
  provider = aws.source
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.source.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# bucket logging
resource "aws_s3_bucket_logging" "log_bucket" {
  provider = aws.source
  bucket   = aws_s3_bucket.log_bucket.id

  target_bucket = aws_s3_bucket.source.id
  target_prefix = ""
}
