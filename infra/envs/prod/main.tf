# ============================================================================
#  Producción. Primer borrador que dejó el equipo anterior.
#  Se usa como base de la revisión de seguridad (sección 3.1) y de la
#  arquitectura objetivo (sección 3.6). Solo validate/plan.
# ============================================================================
locals {
  prefijo = "inv-${var.entorno}"
  tags = {
    proyecto = "inventario-optimo"
    entorno  = var.entorno
  }
}

module "red" {
  source  = "../../modules/network"
  prefijo = local.prefijo
  tags    = local.tags
}

module "bucket_landing" {
  source     = "../../modules/s3_bucket"
  nombre     = "${local.prefijo}-landing"
  versionado = true
  tags       = local.tags
}

module "bucket_curado" {
  source = "../../modules/s3_bucket"
  nombre = "${local.prefijo}-curado"
  tags   = local.tags
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.prefijo}-db"
  subnet_ids = module.red.subredes_datos
  tags       = local.tags
}

resource "aws_db_instance" "postgres" {
  identifier              = "${local.prefijo}-postgres"
  engine                  = "postgres"
  engine_version          = "16"
  instance_class          = var.db_clase
  allocated_storage       = 50
  db_name                 = "inventario_db"
  username                = var.db_usuario
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [module.red.sg_db_id]
  publicly_accessible     = true
  storage_encrypted       = false
  multi_az                = false
  backup_retention_period = 0
  deletion_protection     = false
  skip_final_snapshot     = true
  tags                    = local.tags
}

module "lambda_salud" {
  source     = "../../modules/lambda_function"
  nombre     = "${local.prefijo}-salud"
  source_dir = "${path.module}/../../../services/salud"
  variables_entorno = {
    ENTORNO     = var.entorno
    DB_HOST     = aws_db_instance.postgres.address
    DB_PASSWORD = var.db_password
  }
  tags = local.tags
}
