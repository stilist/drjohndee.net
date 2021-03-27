output "aws_access_key" {
  value = aws_iam_access_key.static-website-manager.id
}

output "aws_secret_key" {
  value = aws_iam_access_key.static-website-manager.secret
}

output "aws_iam_access_key" {
  value = aws_iam_access_key.iam-manager.id
}

output "aws_iam_secret_key" {
  value = aws_iam_access_key.iam-manager.secret
}

output "aws_lambda_access_key" {
  value = aws_iam_access_key.lambda-manager.id
}

output "aws_lambda_secret_key" {
  value = aws_iam_access_key.lambda-manager.secret
}
