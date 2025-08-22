# public website bucket

resource "aws_s3_bucket" "site" {
  bucket = "cloudlaunch-site-bucket"
  tags   = { Project = "CloudLaunch" }
}


# Enable website hosting on site bucket

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id
  

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.site.id
  key    = "index.html"
  source = "${path.module}/website/index.html"  # Path to your index.html file
  acl    = "public-read"  # Make it publicly readable
  
}


# Edit block public access settings for the site bucket
resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = false
  ignore_public_acls      = false 
  block_public_policy     = false  # allow policy for public read
  restrict_public_buckets = false
}


# Public read  bucket policy for site bucket
#public documentation:
resource "aws_s3_bucket_policy" "site_policy" {
  bucket = aws_s3_bucket.site.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.site.arn}/*"
      }
    ]
  })
}


# Private bucket (no public access)

resource "aws_s3_bucket" "private" {
  bucket = "cloudlaunch-private-bucket"
  tags   = { Project = "CloudLaunch" }
}

resource "aws_s3_bucket_public_access_block" "private" {
  bucket                  = aws_s3_bucket.private.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}


#Visible only bucket (no public access, but can be accessed by authenticated users)

resource "aws_s3_bucket" "visible_only" {
  bucket = "cloudlaunch-visible-only-bucket"
  tags   = { Project = "CloudLaunch" }
}

# Block public access settings for visible only bucket
resource "aws_s3_bucket_public_access_block" "visible_only" {
  bucket                  = aws_s3_bucket.visible_only.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}


# CloudFront distribution for the public website bucket
# This will serve the S3 bucket as a CDN
resource aws_cloudfront_distribution "cloudlaunch_site_cdn" {
  origin {
    domain_name = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id   = "S3-cloudlaunch-site-bucket"

  }

  enabled = true
  is_ipv6_enabled = true
    default_root_object = "index.html"
comment = "CloudFront distribution for CloudLaunch site"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-cloudlaunch-site-bucket"

    

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true # free aws ssl certificate
  }

  tags = {
    Project = "cloudlaunch-site-cdn"
  }


}