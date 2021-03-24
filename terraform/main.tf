terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.33.0"
    }
    namecheap = {
      source  = "robgmills/namecheap"
      version = "1.7.0"
    }
  }
}

# CloudFront can only use ACM certificates created in the `us-east-1` region.
#
# @see https://github.com/hashicorp/terraform/issues/10957#issuecomment-269653276
provider "aws" {
  access_key = var.aws_access_key
  region     = "us-east-1"
  secret_key = var.aws_secret_key

  alias = "us_east_1"
}

provider "aws" {
  access_key = var.aws_access_key
  region     = var.aws_region
  secret_key = var.aws_secret_key
}

provider "namecheap" {
  api_user    = var.namecheap_api_user
  ip          = var.namecheap_ip
  token       = var.namecheap_api_key
  use_sandbox = var.namecheap_use_sandbox
  username    = var.namecheap_username
}
