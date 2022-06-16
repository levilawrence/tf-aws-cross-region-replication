module "s3_replication_source" {
  source = "./modules/s3/"

  region = var.source_region

  kms_deletion_window_in_days = 7

  kms_tags = merge(
    {
      "Name" = "${var.source_prefix}"
    },
    var.tags,
  )

  kms_alias_name = "alias/source"

  bucket_prefix = var.source_prefix
  acl           = "private"
  force_destroy = true

  versioning_configuration = "Enabled"

  server_side_encryption_rule = tomap(
    {
      apply_server_side_encryption_by_default_kms_master_key_id = module.s3_replication_source.kms_key_id
      sse_algorithm                                             = "aws:kms"

    }
  )

  s3_bucket_tags = merge(
    {
      "Name" = "${var.source_prefix}"
    },
    var.tags,
  )

  logging_target_bucket = aws_s3_bucket.log_bucket.id
  logging_target_prefix = var.log_prefix

  replication_role = module.replication_role.roles
  replication_configuration_rule = tomap(
    {
      status                                                     = "Enabled",
      destination_bucket                                         = module.s3_replication_destination.bucket_arn # dest module
      encryption_configuration_replica_kms_key_id                = module.s3_replication_destination.kms_key_arn
      source_selection_criteria_sse_kms_encrypted_objects_status = "Enabled"
    }
  )
}

resource "aws_s3_object" "sample_upload" {
  count = 2

  provider     = aws.source
  key          = "sample${count.index + 1}.txt"
  bucket       = module.s3_replication_source.bucket_id
  source       = "${path.module}/sample${count.index + 1}.txt"
  content_type = "text/plain"
  etag         = filemd5("${path.module}/sample${count.index + 1}.txt")

  depends_on = [module.s3_replication_source]
}

# ------------------------------------------------------------------------------

module "s3_replication_destination" {
  source = "./modules/s3/"

  region = var.dest_region

  kms_deletion_window_in_days = 7

  kms_tags = merge(
    {
      "Name" = "${var.dest_prefix}"
    },
    var.tags,
  )

  kms_alias_name = "alias/destination"

  bucket_prefix = var.dest_prefix
  force_destroy = true
  acl           = "private"

  versioning_configuration = "Enabled"

  server_side_encryption_rule = tomap(
    {
      apply_server_side_encryption_by_default_kms_master_key_id = module.s3_replication_destination.kms_key_id
      sse_algorithm                                             = "aws:kms"
    }
  )

  s3_bucket_tags = merge(
    {
      "Name" = "${var.dest_prefix}"
    },
    var.tags,
  )

  # ----------------------------------------------------------------
  logging_target_bucket = "aws_s3_bucket.log_bucket.id"
  logging_target_prefix = var.log_prefix
  # ----------------------------------------------------------------
}
