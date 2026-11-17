# ============================================================================
#  Módulo s3_bucket. IMPLEMENTADO y en uso (landing y curado).
#  Revisa sus valores por defecto: este módulo se reutiliza en local y en prod.
# ============================================================================
resource "aws_s3_bucket" "this" {
  bucket        = var.nombre
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "this" {
  depends_on = [aws_s3_bucket_ownership_controls.this]
  bucket     = aws_s3_bucket.this.id
  acl        = var.acl
}

resource "aws_s3_bucket_versioning" "this" {
  count  = var.versionado ? 1 : 0
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}
