# ============================================================================
#  Composición del entorno local.
#  ✅ Entregado: buckets, tabla de control y la Lambda `salud` de ejemplo.
#  ⬜ Tu entregable: módulos ingesta, api y observabilidad.
# ============================================================================
locals {
  prefijo = "inv-${var.entorno}"
  tags = {
    proyecto = "inventario-optimo"
    entorno  = var.entorno
    gestion  = "terraform"
  }
  raiz_servicios = "${path.module}/../../../services"
}

module "bucket_landing" {
  source = "../../modules/s3_bucket"
  nombre = "${local.prefijo}-landing"
}

module "bucket_curado" {
  source = "../../modules/s3_bucket"
  nombre = "${local.prefijo}-curado"
}

module "tabla_control" {
  source   = "../../modules/dynamodb_table"
  nombre   = "${local.prefijo}-control-archivos"
  hash_key = "pk"
  gsi = {
    nombre    = "por_fecha"
    hash_key  = "fecha"
    range_key = "pk"
  }
}

module "lambda_salud" {
  source     = "../../modules/lambda_function"
  nombre     = "${local.prefijo}-salud"
  source_dir = "${local.raiz_servicios}/salud"
  variables_entorno = {
    ENTORNO = var.entorno
  }
}

# ⬜ module "ingesta" {
#   source = "../../modules/ingesta"
#   ...
# }

# ⬜ module "api" {
#   source = "../../modules/api"
#   ...
# }

# ⬜ module "observabilidad" {
#   source = "../../modules/observabilidad"
#   ...
# }
