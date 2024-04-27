terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 4.16"
        }
    }

    required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-east-2"
}

resource "aws_s3_bucket" "cs293ci" {
    bucket = "cs293ci"

    tags = {
        Name = "cs293ci"
        Environment = "Sandbox"
    }
}

data "aws_iam_policy_document" "cs293ci_iam_policy_document" {
    statement {
        principals {
            type = "AWS"
            identifiers = ["*"]
        }
        sid = "PublicReadGetObject"
        actions = ["s3:GetObject"]
        resources = ["${aws_s3_bucket.cs293ci.arn}/*"]
        effect = "Allow"
    }
}

resource "aws_s3_bucket_policy" "cs293ci_bucket_policy" {
    bucket = aws_s3_bucket.cs293ci.id
    policy = data.aws_iam_policy_document.cs293ci_iam_policy_document.json
}

resource "aws_cloudfront_origin_access_control" "cs293ci_cloudfront_origin_access_control" {
    name = "cs293ci_cloudfront_origin_access_control"
    description = "Cloudfront Origin Access Control for the cs293ci Bucket"
    origin_access_control_origin_type = "s3"
    signing_behavior = "always"
    signing_protocol = "sigv4"
}

resource "aws_cloudfront_distribution" "cs293ci_cloudfront_distribution" {
    origin {
        domain_name = aws_s3_bucket.cs293ci.bucket_regional_domain_name
        origin_access_control_id = aws_cloudfront_origin_access_control.cs293ci_cloudfront_origin_access_control.id
        origin_id = aws_s3_bucket.cs293ci.id
    }

    enabled = true
    is_ipv6_enabled = true
    default_root_object = "index.html"

    default_cache_behavior {
        allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = aws_s3_bucket.cs293ci.id

        forwarded_values {
          query_string = false

          cookies {
            forward = "none"
          }
        }

        viewer_protocol_policy = "allow-all"
    }

    restrictions {
      geo_restriction {
        restriction_type = "whitelist"
        locations = ["US", "CA", "GB", "DE"]
      }
    }

    viewer_certificate {
      cloudfront_default_certificate = true
    }
}
