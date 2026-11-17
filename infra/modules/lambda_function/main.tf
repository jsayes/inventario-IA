# ============================================================================
#  Módulo lambda_function. IMPLEMENTADO y en uso (Lambda `salud`).
#  Empaqueta un directorio de services/ y crea rol + función.
# ============================================================================
data "archive_file" "zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.root}/.build/${var.nombre}.zip"
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.nombre}-rol"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "permisos" {
  name = "${var.nombre}-permisos"
  role = aws_iam_role.this.id
  policy = coalesce(var.politica_json, jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "*"
      Resource = "*"
    }]
  }))
}

resource "aws_lambda_function" "this" {
  function_name    = var.nombre
  role             = aws_iam_role.this.arn
  handler          = var.handler
  runtime          = var.runtime
  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  timeout          = var.timeout
  memory_size      = var.memoria_mb

  environment {
    variables = var.variables_entorno
  }

  tags = var.tags
}
