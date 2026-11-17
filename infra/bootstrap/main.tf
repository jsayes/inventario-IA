# ============================================================================
#  Bootstrap del estado remoto: bucket S3 versionado y cifrado + tabla de
#  bloqueo. IMPLEMENTADO. Se aplica una sola vez por cuenta.
#
#  Nadie lo conectó a ningún entorno todavía.
# ============================================================================
terraform {
  required_version = ">= 1.6, < 2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "nombre_bucket_estado" {
  type        = string
  description = "Nombre global del bucket de estado, p. ej. inv-tfstate-<id-cuenta>."
}

provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "estado" {
  bucket = var.nombre_bucket_estado
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "estado" {
  bucket = aws_s3_bucket.estado.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "estado" {
  bucket = aws_s3_bucket.estado.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "estado" {
  bucket                  = aws_s3_bucket.estado.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "bloqueo" {
  name         = "inv-tfstate-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

output "bucket_estado" {
  value = aws_s3_bucket.estado.id
}

output "tabla_bloqueo" {
  value = aws_dynamodb_table.bloqueo.name
}
