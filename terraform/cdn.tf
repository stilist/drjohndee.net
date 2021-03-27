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

resource "aws_iam_role" "lambda_edge_assume_role" {
  provider           = aws.iam
  name               = "lambda_edge_assume_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_edge_assume_role.json

  tags = {
    Managed = true
  }
}

# resource "aws_iam_role_policy" "lambda_edge_execute" {
#   provider = aws.iam
#   name     = "lambda_edge_execute"
#   policy   = data.aws_iam_policy_document.lambda_edge_execute.json
#   role     = aws_iam_role.lambda_edge_assume_role.id
# }

resource "aws_lambda_function" "inject_headers" {
  provider         = aws.lambda
  filename         = data.archive_file.inject_headers_lambda.output_path
  function_name    = "inject-headers"
  role             = aws_iam_role.lambda_edge_assume_role.arn
  handler          = "inject_headers.handler"
  publish          = true
  source_code_hash = filebase64sha256(data.archive_file.inject_headers_lambda.output_path)
  # As of 2021-03-25 Lambda@Edge doesn't support nodejs14.x.
  runtime = "nodejs12.x"

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

  aliases             = ["www.${var.domain}"]
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_All"

  default_cache_behavior {
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_optimized.id
    compress                 = true
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.cors_s3.id
    target_origin_id         = "S3-www.${var.domain}"
    viewer_protocol_policy   = "redirect-to-https"

    lambda_function_association {
      event_type   = "origin-response"
      include_body = false
      lambda_arn   = aws_lambda_function.inject_headers.qualified_arn
    }
  }

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

# @note This can't be an A record -- if it is, TXT records for the bare domain
#   will not be accessible. This is a restriction of the DNS specification.
# @see https://serverfault.com/a/834403
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
