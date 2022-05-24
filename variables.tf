variable "tags" {
  default = {
    "owner"   = "levi"
    "project" = "s3-replication"
    "client"  = "Internal"
  }
}

variable "source_region" {
  default = "eu-west-2"
}

variable "dest_region" {
  default = "eu-west-1"
}

variable "bucket_prefix" {
  default = "crr-example"
}

variable "aws_region" {
  default = "eu-west-2"
}

# variable "aws_profile" {
# }
