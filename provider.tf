provider "aws" {
  alias  = "source"
  region = var.source_region

  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "dest"
  region = var.dest_region
}
