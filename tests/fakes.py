"""Dobles de prueba mínimos de S3 y DynamoDB, sin red ni credenciales.

Puedes extenderlos o reemplazarlos por `moto` si lo prefieres. Imitan solo lo
que usa la Lambda de ingesta.
"""
from __future__ import annotations

import io


class ConditionalCheckFailed(Exception):
    """Imita el ClientError de botocore con código ConditionalCheckFailedException."""

    def __init__(self) -> None:
        super().__init__("The conditional request failed")
        self.response = {"Error": {"Code": "ConditionalCheckFailedException"}}


class FakeS3:
    def __init__(self) -> None:
        self.objetos: dict[tuple[str, str], bytes] = {}
        self.copias: list[tuple[str, str]] = []

    def put(self, bucket: str, key: str, contenido: bytes) -> None:
        self.objetos[(bucket, key)] = contenido

    def get_object(self, Bucket: str, Key: str) -> dict:
        return {"Body": io.BytesIO(self.objetos[(Bucket, Key)])}

    def copy_object(self, CopySource: dict, Bucket: str, Key: str) -> dict:
        self.objetos[(Bucket, Key)] = self.objetos[(CopySource["Bucket"], CopySource["Key"])]
        self.copias.append((Bucket, Key))
        return {}


class FakeTable:
    """Soporta put_item con ConditionExpression='attribute_not_exists(pk)'."""

    def __init__(self) -> None:
        self.items: dict[str, dict] = {}

    def put_item(self, Item: dict, ConditionExpression: str | None = None, **_) -> dict:
        if ConditionExpression and "attribute_not_exists" in ConditionExpression and Item["pk"] in self.items:
            raise ConditionalCheckFailed()
        self.items[Item["pk"]] = dict(Item)
        return {}

    def get_item(self, Key: dict, **_) -> dict:
        item = self.items.get(Key["pk"])
        return {"Item": item} if item else {}


def evento_s3(bucket: str, key: str, etag: str = "abc123") -> dict:
    return {
        "Records": [
            {
                "eventSource": "aws:s3",
                "eventName": "ObjectCreated:Put",
                "s3": {"bucket": {"name": bucket}, "object": {"key": key, "eTag": etag, "size": 1}},
            }
        ]
    }
