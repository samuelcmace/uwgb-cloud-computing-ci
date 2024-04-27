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

resource "aws_s3_bucket_website_configuration" "cs293ci_website_configuration" {
    bucket = aws_s3_bucket.cs293ci.id

    index_document {
      suffix = "index.html"
    }

    error_document {
      key = "error.html"
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
        resources = ["arn:aws:s3:::${aws_s3_bucket.cs293ci.bucket}/*"]
        effect = "Allow"
    }
}

resource "aws_s3_bucket_policy" "cs293ci_bucket_policy" {
    bucket = aws_s3_bucket.cs293ci.id
    policy = data.aws_iam_policy_document.cs293ci_iam_policy_document.json
}
