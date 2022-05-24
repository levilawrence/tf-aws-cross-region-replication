terraform {
  backend "s3" {
    bucket         = "general-state-lock"
    key            = "s3-crr-project/terraform.state"
    region         = "eu-west-2"
    dynamodb_table = "s3-crr"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.8.0"
    }
  }
}
