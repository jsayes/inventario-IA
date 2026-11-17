# Revisión de seguridad y operación

> Plantilla a completar por el candidato (ENUNCIADO.md, sección 3.1).

## 1. Cómo hice la revisión

Qué revisaste, en qué orden y con qué herramientas. Qué hallazgos de checkov descartaste y por qué.

1. Principalmente se reviso el apartado de postgresSQl,
debido que las conexiones de BD debe tener seguridad por los atacantes.

2. Se reviso el acceso público.

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


## 3. Lo que no corregí

| # | Hallazgo | Por qué no | Cómo lo haría |
|---|---|---|---|
| | | | |

1. 

2. 

## 4. Si esto ya estuviera en producción

Uno de los hallazgos implica que algo pudo haberse expuesto. ¿Qué harías además de corregir el código?

1. Es crítica ya que los atacantes pueden utilizar esta vulnerabilidad para obtener información sensible.

2. Una persona puede eliminar el recurso y borrar la informaciony sin el Public Access Block puede exponer de forma accidental los datos.