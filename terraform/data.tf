data "archive_file" "inject_headers_lambda" {
  type        = "zip"
  source_file = "${path.module}/inject_headers.js"
  output_path = "${path.module}/inject-headers.zip"
}

# @see https://github.com/hashicorp/terraform-provider-aws/issues/14373#issuecomment-784813532
data "aws_cloudfront_origin_request_policy" "cors_s3" {
  name = "Managed-CORS-S3Origin"
}

# @see https://github.com/hashicorp/terraform-provider-aws/issues/14373#issuecomment-784813532
data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_iam_policy" "AWSCertificateManagerFullAccess" {
  provider = aws.iam
  arn      = "arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess"
}

data "aws_iam_policy" "AWSLambda_FullAccess" {
  provider = aws.iam
  arn      = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}

data "aws_iam_policy" "AWSLambda_ReadOnlyAccess" {
  provider = aws.iam
  arn      = "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess"
}

data "aws_iam_policy" "AmazonS3FullAccess" {
  provider = aws.iam
  arn      = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

data "aws_iam_policy" "CloudFrontFullAccess" {
  provider = aws.iam
  arn      = "arn:aws:iam::aws:policy/CloudFrontFullAccess"
}

data "aws_iam_policy" "IAMFullAccess" {
  provider = aws.iam
  arn      = "arn:aws:iam::aws:policy/IAMFullAccess"
}

data "aws_iam_policy_document" "lambda_edge_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    effect = "Allow"

    # @see https://advancedweb.hu/how-to-use-lambda-edge-with-terraform/
    principals {
      type = "Service"
      identifiers = [
        "edgelambda.amazonaws.com",
        "lambda.amazonaws.com",
      ]
    }
  }

  statement {
    actions = [
      "lambda:EnableReplication*",
    ]
    effect = "Allow"
    resources = [
      aws_lambda_function.inject_headers,
    ]
  }
}

data "aws_iam_policy_document" "IamCreateServiceLinkedRole" {
  statement {
    actions = [
      # @see https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-edge-permissions.html
      "iam:CreateServiceLinkedRole",
    ]
    effect = "Allow"
    resources = [
      aws_iam_role.lambda_edge_assume_role.arn,
    ]
  }
}

data "aws_iam_policy_document" "lambda_edge_execute" {
  statement {
    effect = "Allow"
    actions = [
      # @see https://stackoverflow.com/a/44381157
      "lambda:GetFunctionConfiguration",
      # @see https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-edge-permissions.html
      "lambda:GetFunction",
      "lambda:EnableReplication*",
    ]

    resources = [
      aws_lambda_function.inject_headers.arn,
    ]
  }

  statement {
    actions = [
      # @see https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-edge-permissions.html
      "cloudfront:UpdateDistribution",
    ]
    effect = "Allow"
    resources = [
      aws_cloudfront_distribution.www_domain.arn,
    ]
  }
}
