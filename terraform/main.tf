terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.33.0"
    }
  }
}

# CloudFront can only use ACM certificates created in the `us-east-1` region.
#
# @see https://github.com/hashicorp/terraform/issues/10957#issuecomment-269653276
provider "aws" {
  access_key = var.access_key
  region     = "us-east-1"
  secret_key = var.secret_key

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

provider "aws" {
  access_key = var.access_key
  region     = var.region
  secret_key = var.secret_key
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
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.domain}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"

    # based on AWS' pre-built `Managed-CachingOptimized` policy
    compress    = true
    min_ttl     = 1
    default_ttl = 86400
    max_ttl     = 31536000
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
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-www.${var.domain}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"

    # based on AWS' pre-built `Managed-CachingOptimized` policy
    compress    = true
    min_ttl     = 1
    default_ttl = 86400
    max_ttl     = 31536000
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
