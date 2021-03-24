resource "aws_s3_bucket" "bare_domain" {
  bucket = var.domain
  acl    = "public-read"

  website {
    redirect_all_requests_to = "www.${var.domain}"
  }

  tags = {
    Managed = true
  }
}

resource "aws_s3_bucket" "www_domain" {
  bucket = "www.${var.domain}"
  acl    = "public-read"

  website {
    index_document = "index.html"
  }

  tags = {
    Managed = true
  }
}
