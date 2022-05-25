terraform {
  backend "s3" {
    bucket         = "levis-bucket"
    key            = "s3-crr-project/terraform.state"
    region         = "eu-west-2"
    dynamodb_table = "S3-CRR"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.8.0"
    }
  }
}
