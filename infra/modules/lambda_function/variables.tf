variable "nombre" {
  type = string
}

variable "source_dir" {
  type        = string
  description = "Directorio con el código de la Lambda (se empaqueta en zip)."
}

variable "handler" {
  type    = string
  default = "handler.handler"
}

variable "runtime" {
  type    = string
  default = "python3.12"
}

variable "timeout" {
  type    = number
  default = 30
}

variable "memoria_mb" {
  type    = number
  default = 256
}

variable "variables_entorno" {
  type    = map(string)
  default = {}
}

variable "politica_json" {
  type        = string
  description = "Política IAM inline del rol. Si se omite, se usa la política por defecto."
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
