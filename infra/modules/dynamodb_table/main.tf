# ============================================================================
#  Módulo dynamodb_table. IMPLEMENTADO COMO REFERENCIA de buenas prácticas:
#  bajo demanda, cifrado, PITR y un GSI opcional.
# ============================================================================
resource "aws_dynamodb_table" "this" {
  name         = var.nombre
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = var.hash_key

  attribute {
    name = var.hash_key
    type = "S"
  }

  dynamic "attribute" {
    for_each = var.gsi == null ? toset([]) : setsubtract(compact([var.gsi.hash_key, var.gsi.range_key]), [var.hash_key])
    content {
      name = attribute.value
      type = "S"
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.gsi == null ? [] : [var.gsi]
    content {
      name            = global_secondary_index.value.nombre
      hash_key        = global_secondary_index.value.hash_key
      range_key       = global_secondary_index.value.range_key
      projection_type = "ALL"
    }
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = var.tags
}
