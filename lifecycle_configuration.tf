resource "aws_s3_bucket_lifecycle_configuration" "delete_objects" {
  provider = aws.source
  bucket   = aws_s3_bucket.source.id

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
