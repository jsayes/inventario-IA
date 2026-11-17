# Muestras

| Archivo | Qué representa |
|---|---|
| `ventas_20260302_0800.csv` | Corte válido de las 08:00 (10 líneas) |
| `ventas_20260302_1400.csv` | Corte válido de las 14:00, acumulado |
| `ventas_20260302_2000.csv` | **0 bytes**: la subida del origen falló |
| `ventas_20260303_0800.csv` | **Encabezado distinto**: el origen renombró una columna y quitó otra sin avisar |
| `reenvio/ventas_20260302_0800.csv` | El origen **reenvía** el corte de las 08:00 con una corrección (mismo nombre, otro contenido) |
| `inventario_20260302_0600.csv` | Snapshot válido de inventario (1,080 filas) |
| `catalogo_tiendas_20260301.csv` | Catálogo de tiendas |
| `eventos/s3_test_event.json` | Mensaje que S3 publica en la cola **al configurar** la notificación. No trae `Records` |
| `eventos/s3_evento_duplicado.json` | Un evento de S3 tal como llega en el `body` del mensaje de SQS. S3 puede entregarlo **más de una vez** |
