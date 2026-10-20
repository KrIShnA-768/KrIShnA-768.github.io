# Static site on S3 behind CloudFront. Week 10 of the roadmap.
#
# PARTIALLY IMPLEMENTED, same approach as the main project: the fiddly, easy-to-get-wrong
# parts are written out (two providers, the OAC bucket policy, the private bucket), and the
# resources worth typing yourself are TODOs with the arguments that matter.
#
# The pattern to understand, because the old tutorials all get it wrong:
#   - The bucket is PRIVATE. No public access, no S3 website endpoint.
#   - CloudFront reaches it through Origin Access Control (OAC), authenticated with SigV4.
#   - The bucket policy allows ONLY this distribution, by ARN.
# A public bucket serving a website still works, but it is an outdated pattern and a
# reviewer will notice.

terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "portfolio"
      ManagedBy = "terraform"
    }
  }
}

# A SECOND provider, aliased, pinned to us-east-1.
#
# This is not optional and not a style choice: CloudFront only reads ACM certificates from
# us-east-1, no matter where the rest of your infrastructure lives. A certificate created in
# ap-south-1 will simply not attach, with an unhelpful error.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project   = "portfolio"
      ManagedBy = "terraform"
    }
  }
}

locals {
  # Prefer the apex domain; www redirects to it.
  aliases = [var.domain_name, "www.${var.domain_name}"]
}

# ---------------------------------------------------------------------------
# Origin bucket — private
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "site" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id

  # Cheap insurance: lets you recover the previous version of the site after a bad sync.
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ---------------------------------------------------------------------------
# Origin Access Control
#
# Replaces the old Origin Access Identity. The bucket policy below trusts the distribution
# by ARN — so only CloudFront can read the objects, and only this distribution.
# ---------------------------------------------------------------------------

resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${var.bucket_name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# HEADS UP: this data source and the bucket policy below both reference
# aws_cloudfront_distribution.site, which is TODO 2 and does not exist yet. Until you write
# it, `terraform validate` will fail here with "reference to undeclared resource".
#
# That is expected. Either comment out these two blocks while you build the bucket, or write
# TODO 2 first. Terraform resolves the dependency cycle fine once both exist — the
# distribution is created, then the policy is attached.
data "aws_iam_policy_document" "site" {
  statement {
    sid    = "AllowCloudFrontRead"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site.json
}

# ===========================================================================
# YOUR WORK STARTS HERE
# ===========================================================================

# TODO 1 - Certificate (note the provider override)
#
#   resource "aws_acm_certificate" "site" {
#     provider          = aws.us_east_1        # REQUIRED. See the comment above.
#     domain_name       = var.domain_name
#     subject_alternative_names = ["www.${var.domain_name}"]
#     validation_method = "DNS"
#
#     lifecycle { create_before_destroy = true }
#   }
#
#   resource "aws_route53_record" "cert_validation"   for_each over
#     aws_acm_certificate.site.domain_validation_options, creating the CNAME records
#
#   resource "aws_acm_certificate_validation" "site"
#     provider = aws.us_east_1
#     certificate_arn = aws_acm_certificate.site.arn
#     validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
#
#   The validation resource is what makes Terraform WAIT for the certificate to be issued.
#   Without it, the distribution tries to attach a pending certificate and fails.

# TODO 2 - Distribution
#
#   resource "aws_cloudfront_distribution" "site"
#     enabled             = true
#     is_ipv6_enabled     = true
#     default_root_object = "index.html"
#     aliases             = local.aliases
#     price_class         = "PriceClass_200"   # includes India; All is pointless here
#
#     origin {
#       domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
#       origin_id                = "s3-site"
#       origin_access_control_id = aws_cloudfront_origin_access_control.site.id
#     }
#
#     default_cache_behavior {
#       target_origin_id       = "s3-site"
#       viewer_protocol_policy = "redirect-to-https"
#       allowed_methods        = ["GET", "HEAD", "OPTIONS"]
#       cached_methods         = ["GET", "HEAD"]
#       compress               = true
#       # Managed CachingOptimized policy - do not hand-roll a cache policy
#       cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
#     }
#
#     viewer_certificate {
#       acm_certificate_arn      = aws_acm_certificate_validation.site.certificate_arn
#       ssl_support_method       = "sni-only"
#       minimum_protocol_version = "TLSv1.2_2021"
#     }
#
#     # S3 returns 403, not 404, for a missing key behind OAC. Without this your 404 page
#     # never shows and visitors get an XML access-denied document instead.
#     custom_error_response {
#       error_code         = 403
#       response_code      = 404
#       response_page_path = "/404.html"
#     }
#     custom_error_response {
#       error_code         = 404
#       response_code      = 404
#       response_page_path = "/404.html"
#     }
#
#     restrictions {
#       geo_restriction { restriction_type = "none" }
#     }
#
#   Expect the first apply to take 10-20 minutes. CloudFront distributions are slow to
#   create and slow to change; this is normal, not a hang.

# TODO 3 - DNS
#
#   data "aws_route53_zone" "this"  name = var.domain_name
#
#   aws_route53_record for the apex and for www:
#     type = "A", and an alias block pointing at the distribution:
#       name                   = aws_cloudfront_distribution.site.domain_name
#       zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
#       evaluate_target_health = false
#
#   Use an ALIAS record, not a CNAME. A CNAME cannot exist at the apex of a zone - this is a
#   DNS rule, not an AWS one, and it is worth being able to explain.

# TODO 4 - Deploy pipeline
#
#   Replace .github/workflows/deploy-pages.yml with a workflow that:
#     1. assumes the OIDC role (same pattern as the main project)
#     2. aws s3 sync . s3://<bucket> --delete --exclude "terraform/*" --exclude ".git/*" --exclude "*.md"
#     3. aws cloudfront create-invalidation --distribution-id <id> --paths "/*"
#
#   Step 3 is not optional. Without it you will fix something, see no change, and lose an
#   hour to a cache you forgot you had.
#
#   Set Cache-Control when syncing: long max-age for assets, short for index.html, or a
#   cached stale homepage defeats the invalidation you just paid for.
