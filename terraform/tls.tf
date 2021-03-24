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
