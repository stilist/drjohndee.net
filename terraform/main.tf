terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "2.1.0"
    }
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

provider "archive" {}

# CloudFront can only use ACM certificates created in the `us-east-1` region.
#
# @see https://github.com/hashicorp/terraform/issues/10957#issuecomment-269653276
provider "aws" {
  access_key = var.aws_access_key
  region     = "us-east-1"
  secret_key = var.aws_secret_key

  alias = "us_east_1"
}

# This provider instance is only for managing IAM users. The associated IAM
# user must have the 'IAMFullAccess' policy attached.
provider "aws" {
  access_key = var.aws_iam_access_key
  region     = var.aws_region
  secret_key = var.aws_iam_secret_key

  alias = "iam"
}

# Manage the 'iam-manager' user's own permissions.
resource "aws_iam_user" "iam-manager" {
  provider = aws.iam
  name     = "iam-manager"

  tags = {
    Managed = true
  }
}

resource "aws_iam_user_policy_attachment" "iam-full-access" {
  provider   = aws.iam
  policy_arn = data.aws_iam_policy.IAMFullAccess.arn
  user       = aws_iam_user.iam-manager.name
}

resource "aws_iam_access_key" "iam-manager" {
  provider = aws.iam
  user     = aws_iam_user.iam-manager.name
}

# This provider instance is only for managing Lambda. The associated IAM
# user must have the 'AWSLambda_FullAccess' policy attached.
#
# @note Lambda@Edge functions must be deployed in the 'us-east-1' region.
provider "aws" {
  access_key = var.aws_lambda_access_key
  region     = "us-east-1"
  secret_key = var.aws_lambda_secret_key

  alias = "lambda"
}

resource "aws_iam_user" "lambda-manager" {
  provider = aws.iam
  name     = "lambda-manager"

  tags = {
    Managed = true
  }
}

resource "aws_iam_user_policy_attachment" "lambda-full-access" {
  provider   = aws.iam
  policy_arn = data.aws_iam_policy.AWSLambda_FullAccess.arn
  user       = aws_iam_user.lambda-manager.name
}

resource "aws_iam_access_key" "lambda-manager" {
  provider = aws.iam
  user     = aws_iam_user.lambda-manager.name
}

provider "aws" {
  access_key = var.aws_access_key
  region     = var.aws_region
  secret_key = var.aws_secret_key
}

resource "aws_iam_user" "static-website-manager" {
  provider = aws.iam
  name     = "static-website-manager"

  tags = {
    Managed = true
  }
}

resource "aws_iam_user_policy_attachment" "acm-full-access" {
  provider   = aws.iam
  policy_arn = data.aws_iam_policy.AWSCertificateManagerFullAccess.arn
  user       = aws_iam_user.static-website-manager.name
}

resource "aws_iam_user_policy_attachment" "cloudfront-full-access" {
  provider   = aws.iam
  policy_arn = data.aws_iam_policy.CloudFrontFullAccess.arn
  user       = aws_iam_user.static-website-manager.name
}

resource "aws_iam_user_policy_attachment" "lambda-read-access" {
  provider   = aws.iam
  policy_arn = data.aws_iam_policy.AWSLambda_ReadOnlyAccess.arn
  user       = aws_iam_user.static-website-manager.name
}

resource "aws_iam_user_policy_attachment" "s3-full-access" {
  provider   = aws.iam
  policy_arn = data.aws_iam_policy.AmazonS3FullAccess.arn
  user       = aws_iam_user.static-website-manager.name
}

resource "aws_iam_user_policy" "iam-createservicelinkedrole" {
  provider   = aws.iam
  policy     = data.aws_iam_policy_document.IamCreateServiceLinkedRole.json
  user       = aws_iam_user.static-website-manager.name
}

resource "aws_iam_access_key" "static-website-manager" {
  provider = aws.iam
  user     = aws_iam_user.static-website-manager.name
}

provider "namecheap" {
  api_user    = var.namecheap_api_user
  ip          = var.namecheap_ip
  token       = var.namecheap_api_key
  use_sandbox = var.namecheap_use_sandbox
  username    = var.namecheap_username
}
