output "backup_lambda_name" {
  value = aws_lambda_function.backup_lambda.function_name
}

output "backup_lambda_arn" {
  value = aws_lambda_function.backup_lambda.arn
}
