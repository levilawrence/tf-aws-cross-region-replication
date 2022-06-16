module "replication_role" {
  source = "../../modules/iam/"

  name_prefix = "replication"
  description = "Allows reading for replication."

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "s3ReplicationAssume",
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "s3.amazonaws.com"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
  })

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "s3:GetReplicationConfiguration",
            "s3:ListBucket",
            "s3:GetObjectVersion",
            "s3:GetObjectVersionForReplication",
            "s3:GetObjectVersionAcl",
            "s3:GetObjectVersionTagging",
            "s3:GetObjectVersion",
            "s3:ObjectOwnerOverrideToBucketOwner"
          ],
          "Effect" : "Allow",
          "Resource" : [
            "${module.s3_replication_source.bucket_arn}",
            "${module.s3_replication_source.bucket_arn}/*"
          ]
        },
        {
          "Action" : [
            "s3:ReplicateObject",
            "s3:ReplicateDelete",
            "s3:ReplicateTags",
            "s3:GetObjectVersionTagging",
            "s3:ObjectOwnerOverrideToBucketOwner"
          ],
          "Effect" : "Allow",
          "Resource" : "${module.s3_replication_destination.bucket_arn}/*"
        },
        {
          "Action" : [
            "kms:Decrypt"
          ],
          "Effect" : "Allow",
          "Resource" : [
            module.s3_replication_source.kms_key_arn,
            # module.s3_replication_destination.kms_key_arn
          ]
        },
        {
          "Action" : [
            "kms:Encrypt"
          ],
          "Effect" : "Allow",
          "Resource" : [
            module.s3_replication_source.kms_key_arn,
            # module.s3_replication_destination.kms_key_arn
          ]
        }
      ]
  })

  name       = "replication"
  roles      = [module.replication_role.roles]
  policy_arn = module.replication_role.policy_arn
}
