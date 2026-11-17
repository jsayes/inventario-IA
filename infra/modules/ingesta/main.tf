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
