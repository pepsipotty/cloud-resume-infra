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


# {
#   "Version": "2012-10-17",           // Always this for modern policies
#   "Statement": [{
#     "Effect": "Allow",              // Allow or Deny
#     "Principal": { WHO },            
#     "Action": "WHAT_ACTION",         
#     "Resource": "WHICH_RESOURCES",   
#     "Condition": { WHEN }           
#   }]
# }
# 

resource "aws_s3_bucket_policy" "cloudfront_access" {
  bucket = aws_s3_bucket.resume_site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.resume_site.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cloud-resume-cf.arn
          }
        }
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "cloud-resume-cf" {
  aliases                         = ["www.sengweiyeoh.com", "sengweiyeoh.com"]
  anycast_ip_list_id              = null
  comment                         = "cloudfront distribution for my personal resume"
  continuous_deployment_policy_id = null
  default_root_object             = "index.html"
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
    target_origin_id           = "resume-s3-bucket-origin"
    trusted_key_groups         = []
    trusted_signers            = []
    viewer_protocol_policy     = "redirect-to-https"
    grpc_config {
      enabled = false
    }
  }
  origin {
    domain_name = aws_s3_bucket.resume_site.bucket_regional_domain_name
    origin_id = "resume-s3-bucket-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.cloud_resume_s3_oac.id
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

# resource "aws_cloudfront_origin_access_control" "example" {
#   name                              = "example"
#   description                       = "Example Policy"
#   origin_access_control_origin_type = "s3"
#   signing_behavior                  = "always"
#   signing_protocol                  = "sigv4"
# }

resource "aws_cloudfront_origin_access_control" "cloud_resume_s3_oac" {
  name                              = "cloud_resume_s3_oac"
  description                       = "OAC for s3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
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