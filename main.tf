terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.19.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_kms_key" "encryption_key" {
  description             = "Encryption key to protect SNS and SQS"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.encryption_key_policy.json
  tags                    = var.mandatory_tags
}

data "aws_iam_policy_document" "encryption_key_policy" {
  version = "2012-10-17"
  statement {
    sid     = "AdminCanManageKey"
    effect  = "Allow"
    actions = ["kms:*"]
    principals {
      identifiers = ["arn:aws:iam::${local.current_account_id}:root"]
      type        = "AWS"
    }
    resources = ["arn:aws:kms:${local.current_region_name}:${local.current_account_id}:key/*"]
  }
  statement {
    sid = "S3CanEncrypt"
    principals {
      identifiers = ["s3.amazonaws.com"]
      type        = "Service"
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["arn:aws:kms:${local.current_region_name}:${local.current_account_id}:key/*"]
    condition {
      test     = "ArnEquals"
      values   = ["arn:aws:s3:::${var.s3_bucket_name}"]
      variable = "aws:SourceArn"
    }
  }
statement {
    sid = "CloudWatchCanEncrypt"
    principals {
      identifiers = ["cloudwatch.amazonaws.com"]
      type        = "Service"
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["arn:aws:kms:${local.current_region_name}:${local.current_account_id}:key/*"]
  }
  statement {
    sid = "SNSCanEncrypt"
    principals {
      identifiers = ["sns.amazonaws.com"]
      type        = "Service"
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["arn:aws:kms:${local.current_region_name}:${local.current_account_id}:key/*"]
    condition {
      test = "ForAnyValue:StringEquals"
      values = [
        "arn:aws:sns:${local.current_region_name}:${local.current_account_id}:${local.new_objects_topic_name}",
        "arn:aws:sns:${local.current_region_name}:${local.current_account_id}:${local.integration_alarm_topic_name}"
      ]
      variable = "aws:SourceArn"
    }
  }
  statement {
    sid = "SQSCanEncrypt"
    principals {
      identifiers = ["sqs.amazonaws.com"]
      type        = "Service"
    }
actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["arn:aws:kms:${local.current_region_name}:${local.current_account_id}:key/*"]
    condition {
      test = "ForAnyValue:StringEquals"
      values = [
        "arn:aws:sqs:${local.current_region_name}:${local.current_account_id}:${local.new_objects_queue_name}",
        "arn:aws:sqs:${local.current_region_name}:${local.current_account_id}:${local.new_objects_dlq_name}"
      ]
      variable = "aws:SourceArn"
    }
  }
  statement {
    sid = "LogForwardingRoleCanDecrypt"
    principals {
      identifiers = [aws_iam_role.log_forwarding_role.arn]
      type        = "AWS"
    }
    actions   = ["kms:Decrypt"]
    resources = ["arn:aws:kms:${local.current_region_name}:${local.current_account_id}:key/*"]
    condition {
      test     = "StringEquals"
      values   = [var.trusted_vpc_id]
      variable = "aws:SourceVpc"
    }
    condition {
      test     = "StringEquals"
      values   = [var.trusted_account_id]
      variable = "aws:PrincipalAccount"
    }
  }
}


