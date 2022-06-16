variable "tags" {
  default = {
    "owner"   = "levi"
    "project" = "s3-replication"
  }
}

variable "source_region" {
  default = "eu-west-1"
}

variable "dest_region" {
  default = "eu-west-2"
}

variable "name_prefix" {
}

variable "description" {
}

variable "policy" {
}

variable "assume_role_policy" {
}

variable "name" {
}

variable "roles" {
}

variable "policy_arn" {
}
