# Arquitectura de producción

> Plantilla a completar por el candidato (ENUNCIADO.md, sección 3.6). Se evalúa el argumento, no la cantidad de servicios.

## 1. Contexto para decidir (entregado)

**La aplicación**

| Componente | Descripción |
|---|---|
| Frontend | SPA estática (React). |
| API | Servicio en contenedor (Python, FastAPI), sin estado. Autenticación propia con JWT y *refresh tokens* hoy; permisos por usuario × módulo. |
| Base de datos | PostgreSQL 16. ~40 GB hoy, crece ~15 GB al año. Contiene costos, márgenes y precios: información confidencial. |
| ETL | Prefect 3 (servidor + worker). Flujos cada 30 min (inventario), 3 veces al día (ventas) y un cierre diario. Cada corrida dura de 1 a 6 minutos. |
| Modelo de IA | Batch nocturno a las 02:00. Hoy tarda ~45 min en una máquina de 8 vCPU y 32 GB. No usa GPU. Lee de PostgreSQL y escribe las instrucciones. |
| Ingesta | Lo que construiste en esta prueba (S3 → SQS → Lambda). |

**El negocio**

- 18 tiendas en Guatemala (3 son centros de distribución). ~60 usuarios internos: compras, operaciones y gerentes de tienda.
- Uso entre las 06:00 y las 22:00, hora de Guatemala. Picos de consulta del dashboard 15 minutos después de cada corte de ventas.
- La empresa usa **Microsoft 365** y quiere que los usuarios entren con su cuenta corporativa.
- **RPO: 15 minutos. RTO: 4 horas** para la base de datos. Si la aplicación cae de noche, nadie la usa; si cae a las 08:15, sí.
- **Presupuesto: USD 1,200 al mes** sumando producción y no producción.
- Equipo: 2 desarrolladores y tú. No hay equipo de guardia 24/7.

## 2. Arquitectura propuesta

### 2.1 Diagrama

```mermaid
flowchart LR
    %% Reemplazar con tu diseño
```

### 2.2 Dónde corre cada componente

| Componente | Servicio de AWS | Por qué este y no otro | Alternativa descartada |
|---|---|---|---|
| Frontend | | | |
| API | | | |
| PostgreSQL | | | |
| Prefect (servidor) | | | |
| Prefect (worker) | | | |
| Modelo de IA | | | |

## 3. Red, cuentas, ambientes y región

## 4. Identidad, secretos y acceso

- Acceso de los usuarios finales:
- Acceso del equipo a la consola y a la base de datos:
- Secretos de las aplicaciones y su rotación:

## 5. Respaldo y recuperación

Cómo cumples el RPO de 15 minutos y el RTO de 4 horas. Qué probarías y cada cuánto.

## 6. Costo mensual estimado

| Componente | Configuración | USD / mes |
|---|---|---|
| | | |
| **Total** | | |

Fuente o método de la estimación. **Qué recortarías primero** si el presupuesto no alcanza.

## 7. Qué sacrifico con este diseño

## 8. Qué haría distinto con el doble de presupuesto o con un equipo de guardia
