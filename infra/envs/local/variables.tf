variable "region" {
  type    = string
  default = "us-east-1"
}

variable "entorno" {
  type    = string
  default = "local"
}

variable "endpoint_localstack" {
  type        = string
  description = "http://localstack:4566 dentro del contenedor tools; http://localhost:4566 desde el host."
  default     = "http://localstack:4566"
}
