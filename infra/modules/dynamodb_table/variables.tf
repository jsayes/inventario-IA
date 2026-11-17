variable "nombre" {
  type = string
}

variable "hash_key" {
  type    = string
  default = "pk"
}

variable "gsi" {
  type = object({
    nombre    = string
    hash_key  = string
    range_key = optional(string)
  })
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
