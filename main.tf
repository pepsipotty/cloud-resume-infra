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
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.url_rewrite.arn
    }
  }
  
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/404.html"  
  }

  custom_error_response {
  error_code         = 403
  response_code      = 200  
  response_page_path = "/index.html"
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

resource "aws_cloudfront_function" "url_rewrite" {
  name    = "add-trailing-slash"
  runtime = "cloudfront-js-1.0"
  comment = "Add trailing slash to URLs for Hugo"
  publish = true

  code = <<-EOT
    function handler(event) {
        var request = event.request;
        var uri = request.uri;
        
        var response_feed = {
            statusCode: 301,
            statusDescription: "Moved Permanently",
            headers: {
                "location": { "value": "/index.xml" }
            }
        }
        
        if (uri === "/feed" || uri === "/feed/") {
            return response_feed;
        }
        
        if (uri.endsWith('/')) {
            request.uri += 'index.html';
        }
        else if (!uri.includes('.')) {
            request.uri += '/index.html';
        }
        
        return request;
    }
EOT
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

// custom email domain
resource "aws_route53_record" "email" {
  zone_id = aws_route53_zone.cloud-resume-hz.zone_id
  name    = ""  
  type    = "MX"
  ttl     = 300

  records = [
    "10 mx01.mail.icloud.com.",
    "10 mx02.mail.icloud.com."
  ]
}
resource "aws_route53_record" "email_spf" {
  zone_id = aws_route53_zone.cloud-resume-hz.zone_id
  name    = ""  
  type    = "TXT"
  ttl     = 300

  records = [
    "v=spf1 include:icloud.com ~all",
    "apple-domain=oByg7zrKFA5O9Grn"
  ]
}
resource "aws_route53_record" "email_dkim" {
  zone_id = aws_route53_zone.cloud-resume-hz.zone_id
  name    = "sig1._domainkey"
  type    = "CNAME"
  ttl     = 300

  records = [
    "sig1.dkim.sengweiyeoh.com.at.icloudmailadmin.com."
  ]
}

resource "aws_acm_certificate" "cloud-resume-cert" {
  
  domain_name       = "sengweiyeoh.com"
  validation_method = "DNS"
  subject_alternative_names = ["www.sengweiyeoh.com"]
}

  resource "aws_dynamodb_table" "visitor_counter" {
    name           = "resume-visitor-counter"
    billing_mode   = "PAY_PER_REQUEST"
    hash_key = "id"
    attribute {
      name = "id"                            
      type = "S"                            
    }
  }

  resource "aws_dynamodb_table_item" "visitor_count_initialization" {
  table_name = aws_dynamodb_table.visitor_counter.name
  hash_key   = aws_dynamodb_table.visitor_counter.hash_key

  item = jsonencode({
    id = {
      S = "visitor_count"
    }
    count = {
      N = "0"
    }
  })
  lifecycle {
    ignore_changes = [item]  
  }
}