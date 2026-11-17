"""Pruebas de la validación de contenido (implementada como referencia).

Pasan tal cual. Se espera que agregues las tuyas sobre la lógica que
implementes: la más valiosa es la que demuestra la idempotencia de la ingesta.
"""
import pytest

from conftest import MUESTRAS
from handler import ArchivoInvalido, destino_curado, fecha_de, validar_contenido


def test_corte_valido_de_ventas():
    contenido = (MUESTRAS / "ventas_20260302_0800.csv").read_bytes()
    meta = validar_contenido("ventas/intradia/ventas_20260302_0800.csv", contenido)
    assert meta == {"fuente": "ventas/intradia", "fecha": "2026-03-02", "filas": 10}


def test_snapshot_valido_de_inventario():
    contenido = (MUESTRAS / "inventario_20260302_0600.csv").read_bytes()
    meta = validar_contenido("inventario/intradia/inventario_20260302_0600.csv", contenido)
    assert meta["fuente"] == "inventario/intradia"
    assert meta["filas"] == 1080


def test_archivo_vacio_es_invalido():
    with pytest.raises(ArchivoInvalido, match="vacío"):
        validar_contenido("ventas/intradia/ventas_20260302_2000.csv", b"")


def test_encabezado_distinto_es_invalido():
    contenido = (MUESTRAS / "ventas_20260303_0800.csv").read_bytes()
    with pytest.raises(ArchivoInvalido, match="encabezado"):
        validar_contenido("ventas/intradia/ventas_20260303_0800.csv", contenido)


def test_prefijo_desconocido_es_invalido():
    with pytest.raises(ArchivoInvalido, match="prefijo"):
        validar_contenido("otros/archivo_20260302.csv", b"a,b\n1,2\n")


def test_fecha_y_destino_curado():
    assert fecha_de("inventario/intradia/inventario_20260302_0730.csv") == "2026-03-02"
    assert destino_curado("ventas/intradia/ventas_20260302_1400.csv", "ventas/intradia", "2026-03-02") == (
        "ventas/intradia/fecha=2026-03-02/ventas_20260302_1400.csv"
    )
