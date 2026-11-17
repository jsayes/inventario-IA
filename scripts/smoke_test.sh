#!/usr/bin/env bash
# Prueba de humo de punta a punta contra LocalStack.
# ✅ Parte 1 (entregada): la Lambda de ejemplo responde.
# ⬜ Parte 2 y 3: complétalas cuando tengas ingesta y API (sección 3.7).
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== 1. Lambda de ejemplo"
aws lambda invoke --function-name inv-local-salud /tmp/salud.json >/dev/null
grep -q '"ok"' /tmp/salud.json && echo "OK salud"

echo "== 2. Ingesta"
# ⬜ Sube las muestras (scripts/subir_muestras.sh), espera a que la cola se
#    vacíe y comprueba en la tabla de control que:
#      - hay exactamente UN registro por versión de archivo válida,
#      - los inválidos quedaron como RECHAZADO (o donde tu diseño diga),
#      - nada quedó atascado en la cola principal.

echo "== 3. API"
# ⬜ Obtén la URL desde `terraform output` y comprueba
#      GET /salud -> 200
#      GET /archivos?fecha=2026-03-02 -> 200 con los archivos del día
#      GET /archivos (sin fecha) -> 400
#    En LocalStack la URL tiene la forma:
#    http://localstack:4566/restapis/<api_id>/<stage>/_user_request_/archivos
