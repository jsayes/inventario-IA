output "bucket_landing" {
  value = module.bucket_landing.id
}

output "bucket_curado" {
  value = module.bucket_curado.id
}

output "tabla_control" {
  value = module.tabla_control.nombre
}

output "lambda_salud" {
  value = module.lambda_salud.nombre
}

# ⬜ Agrega aquí los outputs que use scripts/smoke_test.sh (id y URL de la API,
#    URL de la cola y de la DLQ).
