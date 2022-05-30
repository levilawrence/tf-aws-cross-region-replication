# ------------------------------------------------------------------------------
# IAM role that S3 can use to read our bucket for replication
# ------------------------------------------------------------------------------
resource "aws_iam_role" "replication" {
  provider    = aws.source
  name_prefix = "replication"
  description = "Allow S3 to assume the role for replication"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "s3ReplicationAssume",
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "replication" {
  provider    = aws.source
  name_prefix = "replication"
  description = "Allows reading for replication."

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.source.arn}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersion",
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.source.arn}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.destination.arn}/*"
    },
    {
      "Action": [
        "kms:Decrypt"
      ],
      "Effect": "Allow",
      "Condition": {
        "StringLike": {
          "kms:ViaService": "s3.${var.source_region}.amazonaws.com",
          "kms:EncryptionContext:aws:s3:arn": [
            "${aws_s3_bucket.source.arn}"
          ]
        }
      },
      "Resource": [
        "${aws_kms_key.source.arn}"
      ]
    },
    {
      "Action": [
        "kms:Encrypt"
      ],
      "Effect": "Allow",
      "Condition": {
        "StringLike": {
          "kms:ViaService": "s3.${var.dest_region}.amazonaws.com",
          "kms:EncryptionContext:aws:s3:arn": [
            "${aws_s3_bucket.destination.arn}"
          ]
        }
      },
      "Resource": [
        "${aws_kms_key.destination.arn}"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_policy_attachment" "replication" {
  provider   = aws.source
  name       = "replication"
  roles      = [aws_iam_role.replication.name]
  policy_arn = aws_iam_policy.replication.arn
}

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
  bucket_prefix = var.bucket_prefix

  lifecycle {
    prevent_destroy = false
  }

  tags = merge(
    {
      "Name" = "Source Bucket"
    },
    var.tags,
  )
}

# replication configuration
resource "aws_s3_bucket_replication_configuration" "source_replication" {
  provider = aws.source
  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.source]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.source.id

  rule {
    status = "Enabled"
    filter {
      prefix = ""
    }
    
    delete_marker_replication {
      status = "Enabled"
    }

    destination {
      bucket = aws_s3_bucket.destination.arn
      encryption_configuration {
        replica_kms_key_id = aws_kms_key.destination.arn
      }
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
      replica_modifications {
        status = "Enabled"
      }
    }
  }
}

# enable acl
resource "aws_s3_bucket_acl" "source" {
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
resource "aws_s3_bucket_server_side_encryption_configuration" "apply_server_side_encryption_source" {
  provider = aws.source
  bucket   = aws_s3_bucket.source.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.source.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# ------------------------------------------------------------------------------
# put something in the bucket to replicate
# ------------------------------------------------------------------------------
resource "aws_s3_object" "sample" {
  count        = 2

  provider     = aws.source
  key          = "sample${count.index+1}.txt"
  bucket       = aws_s3_bucket.source.id
  source       = "${path.module}/sample${count.index+1}.txt"
  content_type = "text/plain"
  etag         = filemd5("${path.module}/sample${count.index+1}.txt")

  depends_on = [aws_s3_bucket_replication_configuration.source_replication]
}
