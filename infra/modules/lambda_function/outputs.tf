output "arn" {
  value = aws_lambda_function.this.arn
}

output "nombre" {
  value = aws_lambda_function.this.function_name
}

output "invoke_arn" {
  value = aws_lambda_function.this.invoke_arn
}

output "rol_nombre" {
  value = aws_iam_role.this.name
}

output "rol_arn" {
  value = aws_iam_role.this.arn
}
