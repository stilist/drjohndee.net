# Set these values for these variables in `terraform/secrets.tfvars`.
# If `terraform/secrets.tfvars` doesn't currently exist make a copy of
# `terraform/secrets.tfvars.example` and name it `terraform/secrets.tfvars`.
variable "access_key" {
  type = string
}
variable "domain" {
  type = string
}
variable "secret_key" {
  type = string
}

# You can override these in `terraform/secrets.tfvars` if desired, but the
# defaults will work.
variable "account_id" {
  type    = number
  default = 400201108990
}
# You'll need to create this IAM group manually.
#
# When you create the group attach the `AmazonS3FullAccess`,
# `AWSCertificateManagerFullAccess`, and `CloudFrontFullAccess` policies.
variable "manager_iam_group_name" {
  type    = string
  default = "static-website-manager"
}
variable "region" {
  type    = string
  default = "us-west-2"
}
