# Set these values for these variables in `terraform/secrets.tfvars`.
# If `terraform/secrets.tfvars` doesn't currently exist make a copy of
# `terraform/secrets.tfvars.example` and name it `terraform/secrets.tfvars`.
#
# * aws_account_id
# * aws_access_key
# * aws_secret_key
# * domain
# * namecheap_apiuser
# * namecheap_ip
# * namecheap_token
# * namecheap_username
# * namecheap_use_sandbox
variable "aws_account_id" {
  type    = number
  default = 400201108990
}

variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type = string
}

variable "domain" {
  type = string
}

variable "namecheap_api_key" {
  type = string
}

variable "namecheap_api_user" {
  type = string
}

variable "namecheap_ip" {
  type = string
}

variable "namecheap_username" {
  type = string
}

# You can override these in `terraform/secrets.tfvars` if desired, but the
# defaults will work.
# * aws_manager_iam_group_name
# * aws_region
# * namecheap_use_sandbox

# You'll need to create this IAM group manually.
#
# When you create the group attach the `AmazonS3FullAccess`,
# `AWSCertificateManagerFullAccess`, and `CloudFrontFullAccess` policies.
variable "aws_manager_iam_group_name" {
  type    = string
  default = "static-website-manager"
}

# Note that this setting will be ignored for ACM (AWS Certificate Manager):
# CloudFront can only ACM certificates created in the `us-east-1` region.
variable "aws_region" {
  type    = string
  default = "us-west-2"
}

# This is a map of email addresses and DNS TXT records, used to validate access
# in Google's Webmaster tools.
#
# @example
# ```
# google_site_verification = {
#   "webmaster@drjondee.net" = "LLhwq30UU25YpAJ4-xe4d0TeOINaNPiEHHL0IYH8YdyRzNUkmSpiFcddowUk"
# }
# ```
#
# @see https://support.google.com/webmasters/answer/9008080
variable "google_site_verification" {
  type    = map(any)
  default = {}
}

# @see https://www.namecheap.com/support/knowledgebase/article.aspx/763/63/what-is-sandbox/
variable "namecheap_use_sandbox" {
  type    = bool
  default = true
}
