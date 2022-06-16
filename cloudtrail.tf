# # ----------------------------------------------------------------
# # cloudtrail
# # ----------------------------------------------------------------
data "aws_caller_identity" "current" {}

resource "aws_cloudtrail" "S3_cloudtrail" {
  provider                      = aws.source
  name                          = "log_trail"
  s3_bucket_name                = aws_s3_bucket.log_bucket.id
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = false

  depends_on = [aws_s3_bucket_policy.log_bucket_policy]

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3"]
    }
  }
}

# # ----------------------------------------------------------------
# # S3 log bucket
# # ----------------------------------------------------------------
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

resource "aws_s3_bucket_policy" "log_bucket_policy" {
  provider = aws.source
  bucket   = aws_s3_bucket.log_bucket.id
  policy   = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "${aws_s3_bucket.log_bucket.arn}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "${aws_s3_bucket.log_bucket.arn}/cloudtrail/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}

# enable acl
resource "aws_s3_bucket_acl" "log_bucket_acl" {
  provider = aws.source
  bucket   = aws_s3_bucket.log_bucket.id
  acl      = "log-delivery-write"
}

# enable versioning
resource "aws_s3_bucket_versioning" "log_bucket" {
  provider = aws.source
  bucket   = aws_s3_bucket.log_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# enable server side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "logging_server_side_encryption" {
  provider = aws.source
  bucket   = aws_s3_bucket.log_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = module.s3_replication_source.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# bucket logging
resource "aws_s3_bucket_logging" "access_logging" {
  provider = aws.source
  bucket   = module.s3_replication_source.bucket_id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = var.log_prefix
}
