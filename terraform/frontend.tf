# --- Static frontend: private S3 bucket behind CloudFront -------------------

data "aws_caller_identity" "current" {}

# Managed cache policy AWS provides: good defaults for static sites (respects
# cache headers, compresses, long TTLs). Saves us hand-tuning caching.
data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}

# The warehouse. Bucket names are GLOBALLY unique, so we suffix with the
# account id. Stays private — only CloudFront may read it (policy below).
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project}-frontend-${data.aws_caller_identity.current.account_id}"
}

# Belt-and-suspenders: block every form of public access to the bucket.
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Origin Access Control: the mechanism that lets CloudFront (and nothing else)
# fetch objects from the private bucket, using signed requests.
resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "${var.project}-frontend-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# The courier network. Serves the bucket's files worldwide over HTTPS.
resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html" # "/" serves index.html
  comment             = "${var.project} frontend"
  price_class         = "PriceClass_100" # cheapest tier: US, Canada, Europe edges

  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "s3-frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-frontend"
    viewer_protocol_policy  = "redirect-to-https" # force HTTPS
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = data.aws_cloudfront_cache_policy.optimized.id
  }

  # Single-page-app fallback: if S3 says "no such key" (403/404), serve
  # index.html with a 200 so client-side routing still works.
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Free CloudFront-provided HTTPS cert (uses the *.cloudfront.net domain).
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Bucket policy: allow ONLY this CloudFront distribution to read objects.
data "aws_iam_policy_document" "frontend_bucket" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.frontend.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.frontend_bucket.json
}
