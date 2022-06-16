# ------------------------------------------------------------------------------
# Key for server side encryption on the source bucket
# ------------------------------------------------------------------------------
resource "aws_kms_key" "kms_key" {
  deletion_window_in_days = 7

  tags = merge(
    {
      "Name" = "key_data"
    },
    var.kms_tags,
  )
}

resource "aws_kms_alias" "kms_alias" {
  name          = "alias/source"
  target_key_id = aws_kms_key.kms_key.key_id
}

# ------------------------------------------------------------------------------
# S3 source bucket
# ------------------------------------------------------------------------------

# create bucket
resource "aws_s3_bucket" "bucket" {
  bucket_prefix = "${var.bucket_prefix}-"
  force_destroy = var.force_destroy

  tags = merge(
    {
      "Name" = "Source Bucket"
    },
    var.s3_bucket_tags,
  )
}

# enable acl
resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = var.acl
}

# enable versioning
resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = var.versioning_configuration
  }
}

# enable server side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "server_side_encryption" {
  bucket = aws_s3_bucket.bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.kms_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# replication configuration
resource "aws_s3_bucket_replication_configuration" "s3_replication" {
  depends_on = [aws_s3_bucket_versioning.bucket_versioning]

  role   = var.replication_role
  bucket = aws_s3_bucket.bucket.id

  rule {
    id = var.replication_configuration_rule["rule_id"]
    status = var.replication_configuration_rule["status"]

    filter {
      prefix = "foo"
    }
    
    destination {
      bucket = var.replication_configuration_rule["destination_bucket"]

      encryption_configuration {
        replica_kms_key_id = var.replication_configuration_rule["encryption_configuration_replica_kms_key_id"]
      }
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = var.replication_configuration_rule["source_selection_criteria_sse_kms_encrypted_objects_status"]
      }
    }
  }
}

# bucket logging
resource "aws_s3_bucket_logging" "source_access_logging" {
  bucket = aws_s3_bucket.bucket.id

  target_bucket = var.logging_target_bucket
  target_prefix = var.logging_target_prefix
}

# ------------------------------------------------------------------------------
# put something in the bucket to replicate
# ------------------------------------------------------------------------------
# resource "aws_s3_object" "sample_upload" {
#   count = var.file_upload_count

#   key          = "${var.file_key}-${count.index + 1}.${var.file_ext}"
#   bucket       = aws_s3_bucket.bucket.id
#   source       = "${path.module}/${var.file_key}-${count.index + 1}.${var.file_ext}"
#   content_type = var.file_content_type
#   etag         = filemd5("${path.module}/${var.file_key}-${count.index + 1}.${var.file_ext}")

#   depends_on = [
#     aws_s3_bucket_replication_configuration.source_replication,
#     aws_s3_bucket_lifecycle_configuration.source_delete_objects
#   ]
# }
