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
  bucket_prefix = var.dest_prefix
  force_destroy = true

    tags = merge(
    {
      "Name" = "Destination Bucket"
    },
    var.tags,
  )
}

# enable acl
resource "aws_s3_bucket_acl" "destination" {
  bucket = aws_s3_bucket.destination.id
  acl    = "private"
}

# enable versioning
resource "aws_s3_bucket_versioning" "dest_destination" {
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
