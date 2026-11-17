"""Lambda de ingesta: valida los archivos que el proceso externo deposita en
el bucket *landing* y los publica en el bucket *curado*.

Flujo esperado:  S3 (landing) --evento--> SQS --lote--> esta Lambda
                 --> copia a S3 (curado) + registro en DynamoDB (control)

El ETL (Prefect, fuera de esta prueba) solo lee archivos del bucket curado
cuyo registro de control esté en estado PROCESADO.

ESTADO: la lógica de validación y de copia está IMPLEMENTADA y funciona.
El manejo del lote, la idempotencia y la clasificación de errores NO están
bien resueltos: es parte de tu entregable (ver ENUNCIADO.md, sección 3.2).
"""
"""
Lambda de ingesta: valida los archivos que el proceso externo deposita en
el bucket landing y los publica en el bucket curado.

Flujo:
S3 (landing) -> SQS -> Lambda -> S3 (curado) + DynamoDB (control)
"""

from __future__ import annotations

import csv
import io
import json
import logging
import os
import re
import urllib.parse

from datetime import datetime, timezone

logger = logging.getLogger()
logger.setLevel(os.getenv("LOG_LEVEL", "INFO"))


ESQUEMAS: dict[str, list[str]] = {
    "ventas/intradia/": [
        "id_transaccion",
        "linea",
        "fecha_hora",
        "codigo_tienda",
        "codigo_articulo",
        "unidades",
        "precio_unitario",
        "descuento",
        "costo_unitario",
        "estado",
        "canal",
        "id_cajero",
        "fecha_actualizacion",
    ],
    "inventario/intradia/": [
        "fecha_snapshot",
        "hora_snapshot",
        "codigo_tienda",
        "codigo_articulo",
        "unidades_disponibles",
        "unidades_transito",
        "unidades_comprometidas",
        "costo_promedio",
        "ubicacion",
        "fecha_actualizacion",
    ],
    "catalogos/tiendas/": [
        "codigo_tienda",
        "nombre_tienda",
        "departamento",
        "region",
        "formato",
        "es_centro_distribucion",
        "activa_modelo",
        "metros_cuadrados",
        "fecha_apertura",
    ],
    "catalogos/articulos/": [
        "codigo_articulo",
        "descripcion",
        "codigo_categoria",
        "categoria",
        "subcategoria",
        "marca",
        "unidad_medida",
        "costo_estandar",
        "precio_lista",
        "en_modelo",
        "activo",
    ],
}

_FECHA_EN_NOMBRE = re.compile(r"_(\d{8})(?:_\d{4})?\.csv$")


class ArchivoInvalido(Exception):
    """El archivo no cumple el contrato."""


def fuente_de(key: str) -> str:
    for prefijo in ESQUEMAS:
        if key.startswith(prefijo):
            return prefijo

    raise ArchivoInvalido(
        f"prefijo no reconocido: {key}"
    )


def fecha_de(key: str) -> str:
    m = _FECHA_EN_NOMBRE.search(key)

    if not m:
        raise ArchivoInvalido(
            f"el nombre no trae fecha AAAAMMDD: {key}"
        )

    d = m.group(1)

    return f"{d[0:4]}-{d[4:6]}-{d[6:8]}"


def validar_contenido(
    key: str,
    contenido: bytes,
) -> dict:

    prefijo = fuente_de(key)

    if not contenido.strip():
        raise ArchivoInvalido("archivo vacío")

    texto = contenido.decode("utf-8-sig")

    lector = csv.reader(
        io.StringIO(texto)
    )

    encabezado = [
        c.strip().lower()
        for c in next(lector)
    ]

    esperado = ESQUEMAS[prefijo]

    if encabezado != esperado:

        faltan = sorted(
            set(esperado) - set(encabezado)
        )

        sobran = sorted(
            set(encabezado) - set(esperado)
        )

        raise ArchivoInvalido(
            f"encabezado distinto; faltan={faltan} sobran={sobran}"
        )

    filas = sum(
        1
        for fila in lector
        if any(c.strip() for c in fila)
    )

    if filas == 0:
        raise ArchivoInvalido(
            "solo trae encabezado"
        )

    return {
        "fuente": prefijo.rstrip("/"),
        "fecha": fecha_de(key),
        "filas": filas,
    }


def destino_curado(
    key: str,
    fuente: str,
    fecha: str,
) -> str:

    nombre = key.rsplit("/", 1)[-1]

    return (
        f"{fuente}/fecha={fecha}/{nombre}"
    )


def registrar_rechazo(
    tabla,
    key,
    detalle,
):

    tabla.put_item(
        Item={
            "pk": f"RECHAZADO#{key}",
            "estado": "RECHAZADO",
            "detalle": detalle,
            "procesado_en": datetime.now(
                timezone.utc
            ).isoformat(),
        }
    )


def procesar_objeto(
    s3,
    tabla,
    bucket,
    key,
    etag,
    bucket_curado,
):

    pk = f"{bucket}#{key}#{etag}"

    existente = tabla.get_item(
        Key={"pk": pk}
    )

    if "Item" in existente:

        logger.info(
            "objeto ya procesado %s",
            key,
        )

        return

    obj = s3.get_object(
        Bucket=bucket,
        Key=key,
    )

    meta = validar_contenido(
        key,
        obj["Body"].read(),
    )

    s3.copy_object(
        CopySource={
            "Bucket": bucket,
            "Key": key,
        },
        Bucket=bucket_curado,
        Key=destino_curado(
            key,
            meta["fuente"],
            meta["fecha"],
        ),
    )

    ahora = datetime.now(
        timezone.utc
    ).isoformat()

    tabla.put_item(
        Item={
            "pk": pk,
            "fecha": meta["fecha"],
            "fuente": meta["fuente"],
            "key": key,
            "etag": etag,
            "filas": meta["filas"],
            "estado": "PROCESADO",
            "procesado_en": ahora,
        }
    )

    logger.info(
        "procesado %s (%s filas)",
        key,
        meta["filas"],
    )


def procesar_mensaje(
    body,
    s3,
    tabla,
    bucket_curado,
):

    evento = json.loads(body)

    if evento.get("Event") == "s3:TestEvent":

        logger.info(
            "ignorado s3:TestEvent"
        )

        return

    if "Records" not in evento:

        logger.warning(
            "evento sin Records"
        )

        return

    for r in evento["Records"]:

        bucket = r["s3"]["bucket"]["name"]

        key = urllib.parse.unquote_plus(
            r["s3"]["object"]["key"]
        )

        etag = r["s3"]["object"].get(
            "eTag",
            "",
        )

        procesar_objeto(
            s3,
            tabla,
            bucket,
            key,
            etag,
            bucket_curado,
        )


def handler(event, context):

    import boto3

    s3 = boto3.client("s3")

    tabla = boto3.resource(
        "dynamodb"
    ).Table(
        os.environ["TABLA_CONTROL"]
    )

    bucket_curado = os.environ[
        "BUCKET_CURADO"
    ]

    failures = []

    for mensaje in event["Records"]:

        try:

            procesar_mensaje(
                mensaje["body"],
                s3,
                tabla,
                bucket_curado,
            )

        except ArchivoInvalido as ex:

            logger.warning(
                "archivo rechazado: %s",
                ex,
            )

            registrar_rechazo(
                tabla,
                mensaje["messageId"],
                str(ex),
            )

        except Exception as ex:

            logger.exception(
                "error reintentable: %s",
                ex,
            )

            failures.append(
                {
                    "itemIdentifier":
                    mensaje["messageId"]
                }
            )

    return {
        "batchItemFailures": failures
    }