resource "namecheap_record" "google_site_verification" {
  for_each = var.google_site_verification

  domain  = var.domain
  name    = "@"
  address = "google-site-verification=${replace(each.value, "google-site-verification=", "")}"
  type    = "TXT"
}
