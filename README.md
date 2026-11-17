# Plataforma cloud — Aplicación de inventario óptimo

Repositorio base de la prueba técnica para **Cloud Engineer (mid level)**.
Enunciado: [`ENUNCIADO.md`](ENUNCIADO.md). Esfuerzo esperado: **≈ 4 horas**.

Todo corre en tu máquina contra **LocalStack**: no necesitas cuenta de AWS y no genera costos.

## Qué ya está implementado y qué te toca

| Componente | Estado |
|---|---|
| LocalStack 4.12 + contenedor `tools` (Terraform 1.9, tflint, checkov, awscli, pytest) | ✅ Entregado |
| Módulos `s3_bucket`, `lambda_function`, `dynamodb_table`, `network` | ✅ Entregado (revísalos) |
| Entorno local: buckets, tabla de control, Lambda `salud` desplegada | ✅ Entregado |
| Borrador del entorno de producción y bootstrap del estado remoto | ✅ Entregado (revísalo) |
| Validación y copia en la Lambda de ingesta; Lambda de la API | ✅ Entregado |
| CI con pruebas unitarias | ✅ Entregado |
| **Módulo `ingesta` + idempotencia y manejo de errores de la Lambda** | ⬜ Tu entregable |
| **Módulos `api` y `observabilidad`** | ⬜ Tu entregable |
| **Revisión de seguridad y correcciones** | ⬜ Tu entregable |
| **CI completo y workflow de despliegue con OIDC** | ⬜ Tu entregable |
| **Arquitectura de producción** | ⬜ Tu entregable |
| **2 pruebas propias + prueba de humo** | ⬜ Tu entregable |

## Estructura

```
.
├── ENUNCIADO.md                 # qué se pide
├── DECISIONES.md                # (a completar)
├── Makefile                     # atajos (make up, apply-local, test, ...)
├── docker-compose.yml           # LocalStack 4.12 + tools
├── Dockerfile.tools
├── data/muestras/               # archivos de prueba y eventos (ver LEEME.md)
├── docs/
│   ├── SEGURIDAD.md             # (a completar)
│   ├── OPERACION.md             # (a completar)
│   └── ARQUITECTURA.md          # contexto entregado; diseño a completar
├── infra/
│   ├── bootstrap/               # estado remoto (S3 + bloqueo)
│   ├── modules/
│   │   ├── s3_bucket/           # entregado
│   │   ├── lambda_function/     # entregado
│   │   ├── dynamodb_table/      # entregado, referencia de buenas prácticas
│   │   ├── network/             # entregado, solo prod
│   │   ├── ingesta/             # <- tu entregable
│   │   ├── api/                 # <- tu entregable
│   │   └── observabilidad/      # <- tu entregable
│   └── envs/
│       ├── local/               # LocalStack: se aplica
│       └── prod/                # AWS real: solo validate
├── services/
│   ├── ingesta/                 # validación entregada; lote e idempotencia a completar
│   ├── api_archivos/            # entregado
│   └── salud/                   # Lambda de ejemplo
├── scripts/
│   ├── subir_muestras.sh        # simula al proceso externo
│   └── smoke_test.sh            # parte 1 entregada; 2 y 3 a completar
├── tests/
└── .github/workflows/ci.yml     # pruebas entregadas; el resto a completar
```

## Puesta en marcha

Requisitos: Docker (con Compose v2) y `make`. Nada más.

```bash
make up              # levanta LocalStack y construye la imagen de herramientas
make apply-local     # despliega el entorno local
make invocar-salud   # debe responder {"estado": "ok", "entorno": "local"}
make test            # pruebas unitarias
```

Comprobaciones estáticas:

```bash
make fmt
make validate        # local y prod, sin backend
make lint
make seguridad       # checkov
```

Herramientas a mano:

```bash
make shell
aws s3 ls                                   # ya apunta a LocalStack
aws dynamodb scan --table-name inv-local-control-archivos
```

Cuando tengas la ingesta:

```bash
make muestras        # sube los archivos de data/muestras al bucket landing
make smoke
```

Para empezar de cero: `make down && make up && make apply-local`.

## Notas

- La imagen de LocalStack está fijada en **4.12**, la última edición community que arranca sin token. No la cambies.
- En LocalStack, IAM **no se hace cumplir**: que algo funcione no prueba que sus permisos sean correctos.
- LocalStack ejecuta las Lambdas en contenedores hermanos, por eso monta `/var/run/docker.sock`.
