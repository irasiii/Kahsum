resource "aws_s3_bucket" "flutter_web" {
  bucket = "khasm-${var.environment}-flutter-web"

  tags = {
    Name        = "khasm-${var.environment}-flutter-web"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_ownership_controls" "flutter_web" {
  bucket = aws_s3_bucket.flutter_web.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "flutter_web" {
  bucket                  = aws_s3_bucket.flutter_web.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "flutter_web" {
  depends_on = [aws_s3_bucket_public_access_block.flutter_web]
  bucket     = aws_s3_bucket.flutter_web.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.flutter_web.arn}/*"
    }]
  })
}

resource "aws_s3_bucket_website_configuration" "flutter_web" {
  bucket = aws_s3_bucket.flutter_web.id
  index_document { suffix = "index.html" }
  error_document { key = "index.html" }
}

resource "aws_s3_bucket" "nextjs_site" {
  bucket = "khasm-${var.environment}-nextjs"

  tags = {
    Name        = "khasm-${var.environment}-nextjs"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_ownership_controls" "nextjs_site" {
  bucket = aws_s3_bucket.nextjs_site.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "nextjs_site" {
  bucket                  = aws_s3_bucket.nextjs_site.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "nextjs_site" {
  depends_on = [aws_s3_bucket_public_access_block.nextjs_site]
  bucket     = aws_s3_bucket.nextjs_site.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.nextjs_site.arn}/*"
    }]
  })
}

resource "aws_s3_bucket_website_configuration" "nextjs_site" {
  bucket = aws_s3_bucket.nextjs_site.id
  index_document { suffix = "index.html" }
  error_document { key = "index.html" }
}

resource "aws_cloudfront_origin_access_control" "flutter_web" {
  name                              = "khasm-${var.environment}-flutter-web-oac"
  description                       = "OAC for Flutter web"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "flutter_web" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  origin {
    domain_name = aws_s3_bucket_website_configuration.flutter_web.website_endpoint
    origin_id   = "flutter-web"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "flutter-web"
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

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

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "khasm-${var.environment}-flutter-web"
    Environment = var.environment
  }
}

resource "aws_cloudfront_origin_access_control" "nextjs_site" {
  name                              = "khasm-${var.environment}-nextjs-oac"
  description                       = "OAC for Next.js site"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "nextjs_site" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  origin {
    domain_name = aws_s3_bucket_website_configuration.nextjs_site.website_endpoint
    origin_id   = "nextjs-site"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "nextjs-site"
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "khasm-${var.environment}-nextjs"
    Environment = var.environment
  }
}
