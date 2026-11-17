#!/usr/bin/env bash
# Simula al proceso externo que deposita archivos en el bucket landing.
# Sube los archivos en un orden deliberado: el corte de las 14:00 llega
# ANTES que el de las 08:00, y luego el origen reenvía el de las 08:00
# corregido (mismo nombre, contenido distinto).
set -euo pipefail

BUCKET="${BUCKET_LANDING:-inv-local-landing}"
M=data/muestras

subir () { echo "→ s3://$BUCKET/$2"; aws s3 cp "$1" "s3://$BUCKET/$2" --only-show-errors; }

subir $M/catalogo_tiendas_20260301.csv   catalogos/tiendas/catalogo_tiendas_20260301.csv
subir $M/ventas_20260302_1400.csv        ventas/intradia/ventas_20260302_1400.csv
subir $M/ventas_20260302_0800.csv        ventas/intradia/ventas_20260302_0800.csv
subir $M/inventario_20260302_0600.csv    inventario/intradia/inventario_20260302_0600.csv
subir $M/ventas_20260302_2000.csv        ventas/intradia/ventas_20260302_2000.csv      # vacío
subir $M/ventas_20260303_0800.csv        ventas/intradia/ventas_20260303_0800.csv      # encabezado distinto
sleep 5
subir $M/reenvio/ventas_20260302_0800.csv ventas/intradia/ventas_20260302_0800.csv     # reenvío corregido
subir $M/ventas_20260302_1400.csv        ventas/intradia/ventas_20260302_1400.csv      # mismo contenido otra vez
echo "listo"
