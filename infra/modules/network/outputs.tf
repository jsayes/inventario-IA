output "vpc_id" {
  value = aws_vpc.this.id
}

output "subredes_publicas" {
  value = aws_subnet.publica[*].id
}

output "subredes_datos" {
  value = aws_subnet.datos[*].id
}

output "sg_db_id" {
  value = aws_security_group.db.id
}
