provider "aws" {
  alias  = "source"
  region = var.source_region
}

provider "aws" {
  alias  = "dest"
  region = var.dest_region
}
