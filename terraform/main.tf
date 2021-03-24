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
resource "aws_acm_certificate" "domain" {
  provider = aws.us_east_1

  domain_name               = "*.${var.domain}"
  subject_alternative_names = [var.domain]
  validation_method         = "EMAIL"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Managed = true
  }
}

# This is a replacement for the existing email-validated certificate.
resource "aws_acm_certificate" "domain_via_dns" {
  provider = aws.us_east_1

  domain_name               = "*.${var.domain}"
  subject_alternative_names = [var.domain]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Managed = true
  }
}

provider "aws" {
  access_key = var.aws_access_key
  region     = var.aws_region
  secret_key = var.aws_secret_key
}

resource "aws_s3_bucket" "bare_domain" {
  bucket = var.domain
  acl    = "public-read"
  # policy = file("policy.json")

  website {
    redirect_all_requests_to = "www.${var.domain}"
  }

  tags = {
    Managed = true
  }
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
}

resource "aws_cloudfront_distribution" "bare_domain" {
  origin {
    domain_name = aws_s3_bucket.bare_domain.bucket_domain_name
    origin_id   = "S3-${var.domain}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index-bare.html"

  aliases = [var.domain]

  default_cache_behavior {
    allowed_methods          = ["GET", "HEAD"]
    cached_methods           = ["GET", "HEAD"]
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_optimized.id
    compress                 = true
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.cors_s3.id
    target_origin_id         = "S3-${var.domain}"

    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate.domain.arn
    minimum_protocol_version       = "TLSv1.2_2019"
    ssl_support_method             = "sni-only"
  }

  tags = {
    Managed = true
  }
}

resource "aws_s3_bucket" "www_domain" {
  bucket = "www.${var.domain}"
  acl    = "public-read"
  # policy = file("policy.json")

  website {
    index_document = "index.html"
  }

  tags = {
    Managed = true
  }
}

resource "aws_cloudfront_distribution" "www_domain" {
  origin {
    domain_name = aws_s3_bucket.www_domain.bucket_domain_name
    origin_id   = "S3-www.${var.domain}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = ["www.${var.domain}"]

  default_cache_behavior {
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_optimized.id
    compress                 = true
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.cors_s3.id
    target_origin_id         = "S3-www.${var.domain}"

    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate.domain.arn
    minimum_protocol_version       = "TLSv1.2_2019"
    ssl_support_method             = "sni-only"
  }

  tags = {
    Managed = true
  }
}

provider "namecheap" {
  api_user    = var.namecheap_api_user
  ip          = var.namecheap_ip
  token       = var.namecheap_api_key
  use_sandbox = var.namecheap_use_sandbox
  username    = var.namecheap_username
}
# @note This can't be an A record -- if it is, TXT records for the bare domain
#   will not be accessible. This is a restriction of the DNS specification.
resource "namecheap_record" "root_alias" {
  domain  = var.domain
  name    = "@"
  address = "${aws_cloudfront_distribution.bare_domain.domain_name}."
  ttl     = 300
  type    = "ALIAS"
}
resource "namecheap_record" "www" {
  domain  = var.domain
  name    = "www"
  address = "${aws_cloudfront_distribution.www_domain.domain_name}."
  type    = "CNAME"
}
resource "namecheap_record" "google_site_verification" {
  for_each = var.google_site_verification

  domain  = var.domain
  name    = "@"
  address = "google-site-verification=${replace(each.value, "google-site-verification=", "")}"
  type    = "TXT"
}

locals {
  # @note The `domain_validation_options` set has two members: one for the bare
  #   domain, and one for the subdomain wildcard. All the details are identical
  #   so it doesn't matter which one is used. To get an individual object from
  #   the set it's first cast to a list, and then the first element of the list
  #   is used. Sets are unordered, but because the object details are identical
  #   (aside from `domain`, which we already have as `var.domain`) it doesn't
  #   matter which one is returned.
  acm_verification_details = element(tolist(aws_acm_certificate.domain_via_dns.domain_validation_options), 0)
}
resource "namecheap_record" "acm_verification" {
  domain  = var.domain
  name    = local.acm_verification_details.resource_record_name
  address = local.acm_verification_details.resource_record_value
  type    = local.acm_verification_details.resource_record_type
}
