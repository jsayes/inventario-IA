variable "nombre" {
  type        = string
  description = "Nombre global del bucket."
}

variable "acl" {
  type        = string
  description = "ACL canned del bucket."
  default     = "public-read"
}

variable "versionado" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
