variable "region" {
  type    = string
  default = "us-east-1"
}

variable "entorno" {
  type    = string
  default = "prod"
}

variable "db_usuario" {
  type = string
}

variable "db_password" {
  type = string
}

variable "db_clase" {
  type    = string
  default = "db.t4g.medium"
}
