provider "aws" {
  region = "us-east-1"  
}

import {
  to = aws_cloudfront_distribution.cloud-resume-cf
  id = "E30SE787VM1OZF"
}

resource "aws_s3_bucket" "resume_site" {
  bucket = "sengwei-resume-site-2025"  

    tags = {
        Name        = "Sengwei Yeoh Resume Site"
        Environment = "Production"
    }
}


resource "aws_s3_bucket_website_configuration" "resume_site" {
  bucket = aws_s3_bucket.resume_site.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }
}

resource "aws_s3_bucket_policy" "public_read_access" {
  bucket = aws_s3_bucket.resume_site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.resume_site.arn}/*"
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "cloud-resume-cf" {
  aliases                         = ["www.sengweiyeoh.com", "sengweiyeoh.com"]
  anycast_ip_list_id              = null
  comment                         = "cloudfront distribution for my personal resume"
  continuous_deployment_policy_id = null
  default_root_object             = null
  enabled                         = true
  http_version                    = "http2"
  is_ipv6_enabled                 = true
  price_class                     = "PriceClass_All"
  retain_on_delete                = false
  staging                         = false
  tags = {
    Name = "cloud-resume-cf"
  }
  tags_all = {
    Name = "cloud-resume-cf"
  }
  wait_for_deployment = true
  web_acl_id          = null
  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD"]
    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    default_ttl                = 0
    field_level_encryption_id  = null
    max_ttl                    = 0
    min_ttl                    = 0
    origin_request_policy_id   = null
    realtime_log_config_arn    = null
    response_headers_policy_id = null
    smooth_streaming           = false
    target_origin_id           = "sengwei-resume-site-2025.s3-website-us-east-1.amazonaws.com-md536837hkw"
    trusted_key_groups         = []
    trusted_signers            = []
    viewer_protocol_policy     = "redirect-to-https"
    grpc_config {
      enabled = false
    }
  }
  origin {
    connection_attempts      = 3
    connection_timeout       = 10
    domain_name              = "sengwei-resume-site-2025.s3-website-us-east-1.amazonaws.com"
    origin_access_control_id = null
    origin_id                = "sengwei-resume-site-2025.s3-website-us-east-1.amazonaws.com-md536837hkw"
    origin_path              = null
    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "http-only"
      origin_read_timeout      = 30
      origin_ssl_protocols     = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }
  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.cloud-resume-cert.arn
    ssl_support_method             = "sni-only"
  }
}

resource "aws_route53_zone" "cloud-resume-hz" {
  name = "sengweiyeoh.com"
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.cloud-resume-hz.zone_id
  name    = "www.${aws_route53_zone.cloud-resume-hz.name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cloud-resume-cf.domain_name
    zone_id                = aws_cloudfront_distribution.cloud-resume-cf.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.cloud-resume-hz.zone_id
  name    = "${aws_route53_zone.cloud-resume-hz.name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cloud-resume-cf.domain_name
    zone_id                = aws_cloudfront_distribution.cloud-resume-cf.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate" "cloud-resume-cert" {
  
  domain_name       = "sengweiyeoh.com"
  validation_method = "DNS"
  subject_alternative_names = ["www.sengweiyeoh.com"]
}