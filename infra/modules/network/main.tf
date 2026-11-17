# ============================================================================
#  Módulo network. IMPLEMENTADO. Solo se usa en infra/envs/prod (AWS real).
#  VPC con 2 subredes públicas y 2 subredes para base de datos, en 2 AZ.
# ============================================================================
data "aws_availability_zones" "disponibles" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.disponibles.names, 0, 2)
}

########################################
# VPC
########################################

resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.prefijo}-vpc"
  })
}

########################################
# INTERNET GATEWAY
########################################

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.prefijo}-igw"
  })
}

########################################
# SUBREDES PUBLICAS
########################################

resource "aws_subnet" "publica" {
  count = 2

  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.cidr, 8, count.index)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.prefijo}-publica-${count.index}"
  })
}

########################################
# SUBREDES PRIVADAS PARA DATOS
########################################

resource "aws_subnet" "datos" {
  count = 2

  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.cidr, 8, count.index + 10)
  availability_zone       = local.azs[count.index]

  # CORREGIDO
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.prefijo}-datos-${count.index}"
  })
}

########################################
# RUTA PUBLICA
########################################

resource "aws_route_table" "publica" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, {
    Name = "${var.prefijo}-rt-publica"
  })
}

########################################
# RUTA PRIVADA
########################################

resource "aws_route_table" "privada" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.prefijo}-rt-privada"
  })
}

########################################
# ASOCIACION SUBREDES PUBLICAS
########################################

resource "aws_route_table_association" "publica" {
  count = 2

  subnet_id      = aws_subnet.publica[count.index].id
  route_table_id = aws_route_table.publica.id
}

########################################
# ASOCIACION SUBREDES PRIVADAS
########################################

resource "aws_route_table_association" "datos" {
  count = 2

  subnet_id      = aws_subnet.datos[count.index].id
  route_table_id = aws_route_table.privada.id
}

########################################
# SECURITY GROUP APP
########################################

resource "aws_security_group" "app" {
  name        = "${var.prefijo}-app"
  description = "Aplicaciones"

  vpc_id = aws_vpc.this.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

########################################
# SECURITY GROUP DB
########################################

resource "aws_security_group" "db" {
  name        = "${var.prefijo}-db"
  description = "PostgreSQL Privado"

  vpc_id = aws_vpc.this.id

  ingress {
    description     = "PostgreSQL desde APP"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Solo trafico interno VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr]
  }

  tags = var.tags
}

########################################
# DB SUBNET GROUP
########################################

resource "aws_db_subnet_group" "this" {
  name = "${var.prefijo}-db-subnet-group"

  subnet_ids = [
    aws_subnet.datos[0].id,
    aws_subnet.datos[1].id
  ]

  tags = merge(var.tags, {
    Name = "${var.prefijo}-db-subnet-group"
  })
}
