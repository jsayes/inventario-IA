"""Lambda de ejemplo. IMPLEMENTADA y DESPLEGADA en el entorno local.

Sirve para comprobar que el entorno funciona de punta a punta
(`make apply-local && make invocar-salud`) y como ejemplo de uso del módulo
`infra/modules/lambda_function`.
"""
import os


def handler(event, context):
    return {"estado": "ok", "entorno": os.getenv("ENTORNO", "desconocido")}
