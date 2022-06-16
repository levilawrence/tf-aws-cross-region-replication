resource "aws_s3_bucket_lifecycle_configuration" "source_delete_objects" {
  provider = aws.source
  bucket   = module.s3_replication_source.bucket_id

  rule {
    id = "delete_objects"

    expiration {
      days = 1
    }

    filter {
      prefix = ""
    }

    status = "Enabled"
  }
}
