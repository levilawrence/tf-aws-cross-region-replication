variable "region" {
}

variable "kms_deletion_window_in_days" {
}

variable "kms_tags" {
}

variable "kms_alias_name" {
}

# variable "kms_alias_target_key_id" {
# }

# variable "bucket" {
# }

variable "bucket_prefix" {
}

variable "acl" {
}

variable "force_destroy" {
}

variable "versioning_configuration" {
}

variable "server_side_encryption_rule" {
}

variable "s3_bucket_tags" {
}

variable "logging_target_bucket" {
}

variable "logging_target_prefix" {
}

variable "replication_role" {
}

variable "tags" {
  default = {
    "owner"   = "levi"
    "project" = "s3-replication"
  }
}

variable "replication_configuration_rule" {
  type = object({
    rule_id                   = string
    rule_status               = string
    rule_filter_prefix        = string
    destination_bucket        = string
    destination_storage_class = string
  })

  default = {
    rule_id                   = "foobar"
    rule_status               = "Enabled"
    rule_filter_prefix        = "foo"
    destination_bucket        = "aws_s3_bucket.destination.arn"
    destination_storage_class = "STANDARD"
  }
}






# variable "file_upload_count" {
# }

# variable "file_key" {
# }

# variable "file_ext" {
# }

# variable "file_source" {
# }

# variable "file_content_type" {
# }

# variable "file_etag" {
# }

# -----------------------------------------------------

