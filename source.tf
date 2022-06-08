# ------------------------------------------------------------------------------
# Key for server side encryption on the source bucket
# ------------------------------------------------------------------------------
resource "aws_kms_key" "source" {
  provider                = aws.source
  deletion_window_in_days = 7

  tags = merge(
    {
      "Name" = "source_data"
    },
    var.tags,
  )
}

resource "aws_kms_alias" "source" {
  provider      = aws.source
  name          = "alias/source"
  target_key_id = aws_kms_key.source.key_id
}

# ------------------------------------------------------------------------------
# S3 source bucket
# ------------------------------------------------------------------------------

# create bucket
resource "aws_s3_bucket" "source" {
  provider      = aws.source
  bucket_prefix = var.source_prefix
  force_destroy = true

  tags = merge(
    {
      "Name" = "Source Bucket"
    },
    var.tags,
  )
}

# enable acl
resource "aws_s3_bucket_acl" "source_bucket_acl" {
  provider = aws.source
  bucket   = aws_s3_bucket.source.id
  acl      = "private"
}

# enable versioning
resource "aws_s3_bucket_versioning" "source" {
  provider = aws.source
  bucket   = aws_s3_bucket.source.id
  versioning_configuration {
    status = "Enabled"
  }
}

# enable server side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "source_server_side_encryption" {
  provider = aws.source
  bucket   = aws_s3_bucket.source.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.source.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# replication configuration
resource "aws_s3_bucket_replication_configuration" "source_replication" {
  provider   = aws.source
  depends_on = [aws_s3_bucket_versioning.source] # Must have bucket versioning enabled first

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.source.id

  rule {
    status = "Enabled"

    destination {
      bucket = aws_s3_bucket.destination.arn

      encryption_configuration {
        replica_kms_key_id = aws_kms_key.destination.arn
      }
    }

    # existing_object_replication {
    #   status = "Enabled"
    # }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }
  }
}

# bucket logging
resource "aws_s3_bucket_logging" "source_access_logging" {
  provider = aws.source
  bucket   = aws_s3_bucket.source.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = var.log_prefix
}

# ------------------------------------------------------------------------------
# put something in the bucket to replicate
# ------------------------------------------------------------------------------
resource "aws_s3_object" "sample_upload" {
  count = 2

  provider     = aws.source
  key          = "sample${count.index + 1}.txt"
  bucket       = aws_s3_bucket.source.id
  source       = "${path.module}/sample${count.index + 1}.txt"
  content_type = "text/plain"
  etag         = filemd5("${path.module}/sample${count.index + 1}.txt")

  depends_on = [
    aws_s3_bucket_replication_configuration.source_replication,
    aws_s3_bucket_lifecycle_configuration.source_delete_objects
  ]
}
