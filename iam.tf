resource "aws_iam_role" "replication" {
  # provider    = aws.dest
  name_prefix = "replication"
  # description = "Allow S3 to assume the role for replication"

  assume_role_policy = jsonencode(
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
  })
}

resource "aws_iam_policy" "replication" {
  name_prefix = "replication_policy"
  description = "Allows reading for replication."

  policy = jsonencode(
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging", 
          "s3:GetObjectVersion", 
          "s3:ObjectOwnerOverrideToBucketOwner"
        ],
        "Effect": "Allow",
        "Resource": [
          "${aws_s3_bucket.source.arn}",
          "${aws_s3_bucket.source.arn}/*"
        ]
      },
      {
        "Action": [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags", 
          "s3:GetObjectVersionTagging", 
          "s3:ObjectOwnerOverrideToBucketOwner" 
        ],
        "Effect": "Allow",
        "Resource": "${aws_s3_bucket.destination.arn}/*"
      },
      { 
        "Action": [ 
          "kms:Decrypt" 
        ], 
        "Effect": "Allow", 
        "Resource": [
          aws_kms_key.source.arn,
          aws_kms_key.destination.arn
        ]
      }, 
      { 
        "Action": [ 
          "kms:Encrypt" 
        ], 
        "Effect": "Allow", 
        "Resource": [
          aws_kms_key.source.arn,
          aws_kms_key.destination.arn
        ]
      } 
    ]
  })
}

resource "aws_iam_policy_attachment" "replication" {
  # provider   = aws.dest
  name       = "replication"
  roles      = [aws_iam_role.replication.name]
  policy_arn = aws_iam_policy.replication.arn
}
