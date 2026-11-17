# Revisión de seguridad y operación

> Plantilla a completar por el candidato (ENUNCIADO.md, sección 3.1).

## 1. Cómo hice la revisión

Qué revisaste, en qué orden y con qué herramientas. Qué hallazgos de checkov descartaste y por qué.

1. Principalmente se reviso el apartado de postgresSQl,
debido que las conexiones de BD debe tener seguridad por los atacantes.

2. Se reviso el acceso público.

4. Por ser una lambda, se debe revisar bien las politicas.

## 2. Hallazgos

Ordenados por severidad.

| # | Archivo | Problema | Riesgo concreto | Severidad | Corrección | Commit |
|---|---|---|---|---|---|---|
| 1 | | | | Crítica / Alta / Media / Baja | | |

1. Riesgo: Exposición directa de PostgreSQL a internet
resource "aws_security_group" "db" {

  ingress {
    description = "PostgreSQL"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

Problemas: 
- PostgreSQL expuesto a Internet (0.0.0.0/0)
- Subredes de datos configuradas como públicas (map_public_ip_on_launch = true
- Ausencia de Network ACLs personalizadas

Severidad: Crítica, para los atacantes.

2. Riesgo: No tiene seguridad, por lo que pueden eliminar el bucket aunque tenga información.

resource "aws_s3_bucket" "this" {
  bucket        = var.nombre
  force_destroy = true
}

2.1 Riesgo configuraciones futuras podrían publicar datos.

No existe. aws_s3_bucket_public_access_block

3. Riesgo: Tiene politicas de administrador, por lo que se debe limitar.

policy = coalesce(var.politica_json, jsonencode({
  Version = "2012-10-17"
  Statement = [{
    Effect   = "Allow"
    Action   = "*"
    Resource = "*"
  }]
}))

Adicional se agrego cloudwatch para tener logs y revisa cualquier incidencia que se presente

## 3. Lo que no corregí

| # | Hallazgo | Por qué no | Cómo lo haría |
|---|---|---|---|
| | | | |


## 4. Si esto ya estuviera en producción

Uno de los hallazgos implica que algo pudo haberse expuesto. ¿Qué harías además de corregir el código?

1. Es crítica ya que los atacantes pueden utilizar esta vulnerabilidad para obtener información sensible.

2. Una persona puede eliminar el recurso y borrar la informaciony sin el Public Access Block puede exponer de forma accidental los datos.

3. Tiene muchos privilegios la Lambda, por lo que personas externas pueden leer la información y realizar acciones a la Lambda.