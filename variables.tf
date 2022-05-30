variable "tags" {
  default = {
    "owner"   = "levi"
    "project" = "s3-replication"
    "client"  = "Internal"
  }
}

variable "source_region" {
  default = "eu-west-1"
}

variable "dest_region" {
  default = "eu-west-2"
}

variable "source_prefix" {
  default = "crr-source"
}

variable "dest_prefix" {
  default = "crr-dest"
}

variable "aws_region" {
  default = "eu-west-2"
}
