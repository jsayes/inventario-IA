"""API de control de archivos. IMPLEMENTADA COMO REFERENCIA.

La consume el equipo de operaciones para ver qué archivos llegaron en un día
y en qué estado quedaron. Se expone detrás de API Gateway (proxy integration).

    GET /archivos?fecha=AAAA-MM-DD   -> registros de control de ese día
    GET /salud                       -> 200 si la Lambda responde

Necesita leer la tabla de control por el índice `por_fecha`. Nada más.
"""
from __future__ import annotations

import json
import os
import re

_FECHA = re.compile(r"^\d{4}-\d{2}-\d{2}$")


def _respuesta(status: int, cuerpo) -> dict:
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(cuerpo, default=str, ensure_ascii=False),
    }


def listar_archivos(tabla, fecha: str) -> list[dict]:
    from boto3.dynamodb.conditions import Key

    items, kwargs = [], {"IndexName": "por_fecha", "KeyConditionExpression": Key("fecha").eq(fecha)}
    while True:
        r = tabla.query(**kwargs)
        items.extend(r.get("Items", []))
        if "LastEvaluatedKey" not in r:
            return items
        kwargs["ExclusiveStartKey"] = r["LastEvaluatedKey"]


def handler(event, context):
    ruta = event.get("path") or event.get("rawPath") or ""
    if ruta.endswith("/salud"):
        return _respuesta(200, {"estado": "ok"})

    if ruta.endswith("/archivos"):
        fecha = (event.get("queryStringParameters") or {}).get("fecha", "")
        if not _FECHA.match(fecha):
            return _respuesta(400, {"error": "parámetro fecha requerido (AAAA-MM-DD)"})
        import boto3

        tabla = boto3.resource("dynamodb").Table(os.environ["TABLA_CONTROL"])
        return _respuesta(200, {"fecha": fecha, "archivos": listar_archivos(tabla, fecha)})

    return _respuesta(404, {"error": "ruta no encontrada"})
