# Prueba Técnica — Cloud Engineer (Mid Level)

**Aplicación de inventario óptimo con inteligencia artificial**

## 1. Objetivo

Evaluar tu capacidad para **construir infraestructura en AWS que sea segura, idempotente y operable**, como código, sobre un proyecto que ya está armado.

El repositorio te entrega un entorno local completo con **LocalStack** (no necesitas cuenta de AWS ni generas costos), los **módulos de Terraform base ya implementados**, una **Lambda de ejemplo desplegada y funcionando**, el código de las Lambdas de ingesta y de la API, datos de prueba y un borrador del entorno de producción que dejó el equipo anterior.

Dos de tus entregables son de criterio: la **revisión de seguridad** de lo que ya existe y la **arquitectura de producción** de la aplicación completa. Se evalúa más cómo decides y cómo defiendes tus decisiones que la cantidad de recursos que escribas.

## 2. Contexto del caso

Se está desarrollando una aplicación que calcula el **inventario óptimo de cada producto en cada tienda** y emite instrucciones de transferencia entre ubicaciones. Un proceso externo deposita archivos CSV (ventas cada corte, inventario cada 30 minutos, catálogos diarios) y el ETL los carga en PostgreSQL.

Tú entras como **cloud engineer**. Tu rol es que los archivos lleguen al ETL **una sola vez, validados y sin perderse**, que la plataforma sea segura y que el equipo se entere cuando algo falla.

### 2.1 Componentes

| Componente | Ubicación | Estado |
|---|---|---|
| LocalStack 4.12 + contenedor de herramientas (Terraform, tflint, checkov, awscli, pytest) | `docker-compose.yml`, `Dockerfile.tools`, `Makefile` | ✅ Entregado |
| Módulos `s3_bucket`, `lambda_function`, `dynamodb_table`, `network` | `infra/modules/` | ✅ Entregado (revísalos) |
| Entorno local: buckets *landing* y *curado*, tabla de control, Lambda `salud` | `infra/envs/local/` | ✅ Entregado y funcionando |
| Borrador de producción: VPC, RDS PostgreSQL, buckets, Lambda | `infra/envs/prod/` | ✅ Entregado (revísalo) |
| Bootstrap de estado remoto | `infra/bootstrap/` | ✅ Entregado |
| Código de la Lambda de ingesta (validación y copia) | `services/ingesta/` | ✅ Lógica de validación · ⬜ lote, idempotencia y errores |
| Código de la Lambda de la API | `services/api_archivos/` | ✅ Entregado |
| Pipeline de CI con pruebas unitarias | `.github/workflows/ci.yml` | ✅ Base · ⬜ el resto |
| **Módulo `ingesta`: S3 → SQS → Lambda con DLQ** | `infra/modules/ingesta/` | ⬜ Tu entregable |
| **Módulo `api`: API Gateway → Lambda** | `infra/modules/api/` | ⬜ Tu entregable |
| **Módulo `observabilidad`: alarmas, SNS, retención de logs** | `infra/modules/observabilidad/` | ⬜ Tu entregable |
| **Revisión de seguridad y correcciones** | `docs/SEGURIDAD.md` | ⬜ Tu entregable |
| **Arquitectura de producción** | `docs/ARQUITECTURA.md` | ⬜ Tu entregable |

### 2.2 Comportamientos de la plataforma que debes manejar

Están presentes en las muestras de `data/muestras/` (ver su `LEEME.md`). **Son el corazón de la prueba.**

- **S3 entrega los eventos al menos una vez.** El mismo evento puede llegar dos veces a la cola. Procesarlo dos veces no puede duplicar nada.
- **El origen reenvía archivos corregidos con el mismo nombre.** Un reenvío con contenido distinto **sí** debe procesarse como una versión nueva, sin perder el rastro de la anterior. Un reenvío con contenido idéntico, no.
- **Los archivos llegan fuera de orden.** El corte de las 14:00 puede llegar antes que el de las 08:00.
- **Hay archivos que nunca van a ser válidos**: uno vacío por una subida fallida y otro al que el origen le cambió el encabezado. Decide cuáles errores se reintentan y cuáles no: reintentar un archivo con el contrato roto no lo arregla.
- **Al configurar la notificación, S3 publica un `s3:TestEvent`** que no trae `Records`. Hoy la Lambda se cae con ese mensaje.
- **Un mensaje dañado no puede tumbar el lote completo** ni hacer que se reprocesen los mensajes buenos que venían con él.

> En LocalStack los permisos de IAM **no se hacen cumplir**. El mínimo privilegio se evalúa leyendo tu código y con checkov, no por si algo “funciona”.

## 3. Qué debes desarrollar

### 3.1 Revisión de seguridad y operación (20%)

La infraestructura entregada tiene **al menos ocho problemas de seguridad o de operación**, repartidos entre los módulos y el entorno de producción. Algunos se ven a simple vista y otros solo si entiendes cómo se usa el recurso.

- Encuéntralos, **priorízalos por riesgo** y corrige los que alcances.
- Documéntalos en `docs/SEGURIDAD.md`: archivo, problema, riesgo concreto, severidad, corrección y commit donde lo corregiste. Lo que no corrijas se documenta con cómo lo harías.
- Los módulos se comparten entre local y prod: **corregir uno no puede romper el entorno local.**

checkov ayuda, pero no encuentra todo y reporta cosas que no aplican. Se evalúa tu criterio para priorizar, no cuántos hallazgos de checkov copies.

### 3.2 Ingesta orientada a eventos (25%)

a. **Módulo `infra/modules/ingesta`**: cola SQS con DLQ, notificación del bucket *landing* hacia la cola, la Lambda de `services/ingesta` con una política de **mínimo privilegio** y el *event source mapping*. Las instrucciones mínimas están en el encabezado de `main.tf`. Conéctalo en `infra/envs/local/main.tf`.

b. **Lambda `services/ingesta/handler.py`**: la validación y la copia ya funcionan. Debes resolver:

- **Idempotencia**: decide la llave de idempotencia del registro de control y cómo la haces cumplir.
- **Fallas parciales del lote**: un mensaje malo no reprocesa a los buenos.
- **Clasificación de errores**: qué queda registrado como `RECHAZADO` sin reintento y qué se reintenta hasta terminar en la DLQ.
- El `s3:TestEvent`.

c. Decide y documenta en `DECISIONES.md`: tamaño de lote, *visibility timeout*, `maxReceiveCount`, retención de la DLQ y la llave de idempotencia.

**Verificación esperada:** ejecutar `make muestras` dos veces seguidas debe dejar **exactamente el mismo estado** en la tabla de control y en el bucket curado; el reenvío corregido del corte de las 08:00 sí debe aparecer como versión nueva, y la cola principal debe quedar vacía.

### 3.3 API de control (10%)

**Módulo `infra/modules/api`**: API Gateway REST (v1) con integración proxy hacia `services/api_archivos`, rutas `GET /archivos` y `GET /salud`, stage desplegado y permiso de invocación. La política de la Lambda solo debe permitir lo que el código necesita.

### 3.4 Observabilidad (10%)

**Módulo `infra/modules/observabilidad`**: tópico SNS de alertas y las alarmas de CloudWatch que consideres necesarias. Como mínimo, una que se dispare cuando un archivo termina en la DLQ. Retención de logs definida para **todas** las Lambdas.

En `docs/OPERACION.md`: qué alertas, con qué umbral y por qué; y el *runbook* de dos situaciones: **un archivo está en la DLQ** y **hay que reprocesar un archivo que ya se procesó**.

### 3.5 CI/CD (15%)

Completa `.github/workflows/ci.yml`:

- En cada PR: `terraform fmt`, `validate`, `tflint`, checkov y las pruebas. Decide si checkov bloquea el PR o solo reporta y justifícalo.
- Un job que levante LocalStack 4.12 y haga `plan` (o `apply` + prueba de humo) del entorno local.
- El workflow de despliegue a producción **escrito pero sin ejecutar**: autenticación por **OIDC con un rol de IAM** (sin llaves de acceso), `plan` en el PR y `apply` en `main` con aprobación manual.

El pipeline debe correr en verde en tu Pull Request.

### 3.6 Arquitectura de producción (20%)

El borrador de `infra/envs/prod` solo cubre una parte. En `docs/ARQUITECTURA.md` diseña cómo se despliega **la aplicación completa** en AWS. El contexto para decidir (usuarios, volumen, horario, RPO/RTO, presupuesto y tamaño del equipo) está en la sección 1 de ese archivo.

Debes entregar:

- **Dónde corre cada componente** (API, frontend, PostgreSQL, ETL con Prefect, el modelo de IA nocturno) y por qué ese servicio y no otro.
- **Red, cuentas y ambientes**, y la **región** que elegirías.
- **Secretos, identidades y acceso** de los usuarios.
- Cómo cumples el **RPO y el RTO**.
- Una **estimación de costo mensual** contra el presupuesto, y qué harías si no alcanza.
- Un diagrama (Mermaid en el mismo archivo es suficiente).
- **Qué sacrificas** con tu diseño. Esto es lo que más se evalúa del apartado.

No se implementa: es diseño. Si quieres, puedes reflejar parte en `infra/envs/prod`, pero solo debe pasar `terraform validate`.

### 3.7 Pruebas

Las pruebas de `tests/test_validacion.py` pasan tal cual. Agrega **2 pruebas propias** sobre tu lógica; la más valiosa es la que demuestra la **idempotencia de la ingesta** (en `tests/fakes.py` hay dobles de S3 y DynamoDB que puedes usar o extender). Completa además `scripts/smoke_test.sh`.

## 4. Entregables

Un repositorio de GitHub (público o con acceso al evaluador) con:

1. Módulos `ingesta`, `api` y `observabilidad` conectados en `infra/envs/local`, y que `make apply-local` y `make smoke` funcionen desde cero.
2. Cambios en `services/ingesta/handler.py` y sus pruebas.
3. `.github/workflows/` con CI y el workflow de despliegue.
4. `docs/SEGURIDAD.md` con los hallazgos y su corrección.
5. `docs/OPERACION.md` con alertas y runbooks.
6. `docs/ARQUITECTURA.md` con la arquitectura de producción.
7. `DECISIONES.md`: supuestos, decisiones técnicas y qué quedó fuera de alcance con el motivo.
8. `README.md` actualizado: los pasos para ejecutar lo que tú agregaste deben quedar claros.

### 4.1 Requisitos de Git / GitHub

- Trabajar en al menos dos ramas (por ejemplo `main` y `feature/ingesta`).
- Commits descriptivos. No un único commit final. Las correcciones de seguridad, en commits propios.
- Al terminar, abrir un **Pull Request** de la rama de trabajo hacia la principal, con descripción del cambio. **Déjalo abierto, no lo fusiones**: forma parte de lo que se revisa, incluido el resultado del CI.
- No versionar `.env`, archivos de estado de Terraform, ni credenciales.

## 5. Restricciones técnicas

- Terraform ≥ 1.6, proveedor AWS 5.x y Lambdas en Python 3.12. Todo viene preconfigurado en el contenedor `tools`.
- **No cambies la versión de LocalStack** (4.12). Las versiones posteriores exigen cuenta y token.
- **No apliques nada en una cuenta real de AWS.** Producción solo se valida y se diseña.
- Reutiliza los módulos entregados. Si decides reescribir alguno, justifícalo; el tiempo sale del presupuesto de las **4 horas**.
- Se permite el uso de asistentes de IA, siempre que puedas explicar y defender cada decisión en la sustentación.
- No se requiere frontend ni el modelo de IA.
