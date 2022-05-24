# ------------------------------------------------------------------------------
# KMS key for server side encryption on the destination bucket
# ------------------------------------------------------------------------------
resource "aws_kms_key" "destination" {
  provider                = aws.dest
  deletion_window_in_days = 7

  tags = merge(
    {
      "Name" = "destination_data"
    },
    var.tags,
  )
}

resource "aws_kms_alias" "destination" {
  provider      = aws.dest
  name          = "alias/destination"
  target_key_id = aws_kms_key.destination.key_id
}


# ------------------------------------------------------------------------------
# S3 destination bucket
# ------------------------------------------------------------------------------

# create bucket
resource "aws_s3_bucket" "destination" {
  provider      = aws.dest
  bucket_prefix = var.bucket_prefix
    region        = var.dest_region

  lifecycle {
    prevent_destroy = false
  }
}

# enable acl
resource "aws_s3_bucket_acl" "destination" {
  bucket = aws_s3_bucket.destination.id
  acl    = "private"
}

# enable versioning
resource "aws_s3_bucket_versioning" "destination" {
  bucket = aws_s3_bucket.destination.id
  versioning_configuration {
    status = "Enabled"
  }
}

# enable server side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "apply_server_side_encryption_dest" {
  bucket = aws_s3_bucket.destination.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.destination.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# bucket replication config
resource "aws_s3_bucket_replication_configuration" "replication" {
  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.destination]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.destination.id

  rule {
    # prefix = ""
    status = "Enabled"

    destination {
      bucket             = aws_s3_bucket.destination.arn
    #   replica_kms_key_id = aws_kms_key.destination.arn
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        enabled = "true"
      }
    }
  }
}
