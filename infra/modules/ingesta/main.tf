# ============================================================================
#  Módulo ingesta. ⬜ TU ENTREGABLE (ENUNCIADO.md, sección 3.2).
#
#  S3 (landing) --notificación--> SQS --event source mapping--> Lambda
#                                  └── DLQ (redrive policy)
#
#  Debe incluir, como mínimo:
#    · cola principal y DLQ, con su redrive policy y política de cola que solo
#      permita a ESTE bucket publicar en ella;
#    · notificación del bucket landing hacia la cola (solo los prefijos que
#      la Lambda sabe validar, solo archivos .csv);
#    · la Lambda de services/ingesta usando el módulo lambda_function, con una
#      política de mínimo privilegio (no la de por defecto);
#    · el event source mapping, con tamaño de lote y reporte de fallas
#      parciales;
#    · un visibility timeout coherente con el timeout de la Lambda.
#
#  Decide y documenta en DECISIONES.md: maxReceiveCount, batch size,
#  visibility timeout, retención de la DLQ.
# ============================================================================

########################################
# DLQ
########################################

resource "aws_sqs_queue" "dlq" {
  name = "${var.nombre}-dlq"

  message_retention_seconds = 1209600

  tags = var.tags
}

########################################
# COLA PRINCIPAL
########################################

resource "aws_sqs_queue" "principal" {
  name = "${var.nombre}-queue"

  visibility_timeout_seconds = 180

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })

  tags = var.tags
}

########################################
# PERMITIR SOLO AL BUCKET LANDING
########################################

resource "aws_sqs_queue_policy" "landing" {
  queue_url = aws_sqs_queue.principal.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowLandingBucketOnly"
        Effect = "Allow"

        Principal = {
          Service = "s3.amazonaws.com"
        }

        Action = "sqs:SendMessage"

        Resource = aws_sqs_queue.principal.arn

        Condition = {
          ArnEquals = {
            "aws:SourceArn" = var.bucket_landing_arn
          }
        }
      }
    ]
  })
}

########################################
# NOTIFICACION S3 -> SQS
########################################

resource "aws_s3_bucket_notification" "landing" {
  bucket = var.bucket_landing_id

  queue {
    queue_arn = aws_sqs_queue.principal.arn

    events = [
      "s3:ObjectCreated:*"
    ]

    filter_prefix = "ingesta/"
    filter_suffix = ".csv"
  }

  depends_on = [
    aws_sqs_queue_policy.landing
  ]
}

########################################
# LAMBDA INGESTA
########################################

module "lambda_ingesta" {

  source = "../lambda_function"

  nombre = var.nombre

  source_dir = "${path.root}/../../services/ingesta"

  runtime = "python3.12"

  handler = "app.lambda_handler"

  timeout = 60

  memoria_mb = 256

  tags = var.tags

  politica_json = jsonencode({
    Version = "2012-10-17"

    Statement = [

      {
        Sid    = "ConsumeQueue"
        Effect = "Allow"

        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]

        Resource = aws_sqs_queue.principal.arn
      },

      {
        Sid    = "ReadLandingBucket"
        Effect = "Allow"

        Action = [
          "s3:GetObject"
        ]

        Resource = [
          "${var.bucket_landing_arn}/*"
        ]
      },

      {
        Sid    = "WriteLogs"
        Effect = "Allow"

        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Resource = "*"
      }
    ]
  })
}

########################################
# SQS -> LAMBDA
########################################

resource "aws_lambda_event_source_mapping" "ingesta" {

  event_source_arn = aws_sqs_queue.principal.arn

  function_name = module.lambda_ingesta.function_arn

  batch_size = 10

  enabled = true

  function_response_types = [
    "ReportBatchItemFailures"
  ]
}
