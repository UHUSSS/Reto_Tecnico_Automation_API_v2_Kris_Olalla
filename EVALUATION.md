# EVALUATION.md – Conclusiones y hallazgos

## 1. Resumen ejecutivo

Se implementó una suite de automatización con **Karate DSL** para el recurso **Products** de `fakestoreapi.com`, cubriendo los **8 casos** descritos en el reto (4 positivos, 4 negativos/edge-case), es decir el doble del mínimo exigido (4). Esos 8 casos se materializaron en **14 escenarios ejecutables** (varios casos se descompusieron en sub-escenarios para cubrir edge cases adicionales — p. ej. Caso 8 se probó con `limit=5`, `0`, `-1` y `abc` — y se sumó un escenario extra de hallazgo sobre persistencia en el Caso 4). Todos pasan, pero el hallazgo más relevante del ejercicio **no es que la API "funcione"**, sino que **su comportamiento real difiere en varios puntos del comportamiento asumido por el enunciado** — y una automatización de calidad debe validar el contrato *real*, no el asumido. Esta sección documenta cada discrepancia, cómo se decidió tratarla en el test, y qué implicaría en un contexto productivo real.

## 1.1 Resultados de la última ejecución

| Métrica | Resultado |
|---|---|
| Features ejecutados | 7 |
| Escenarios ejecutados | **14** |
| Escenarios exitosos | **14 (100%)** |
| Escenarios fallidos | 0 |
| Tiempo total (con `parallel(5)`) | ~12.2 s |
| Tiempo acumulado de todos los escenarios (`thread time`) | ~16.5 s |
| Entorno validado | Eclipse Temurin 21.0.12 (Windows 11), Maven 3.9.11, Karate 1.4.1 |

Evidencia completa (request/response por paso, tiempos por escenario, tags): `target/karate-reports/karate-summary.html` y `target/cucumber-html-reports/overview-features.html` (se generan al ejecutar `mvn test`, ver [`README.md`](./README.md)).

## 2. Metodología

Antes de escribir cualquier aserción, cada endpoint se exploró manualmente con `curl` (headers y body completos, no solo el body "bonito") para conocer el contrato real antes de asumirlo. Esto evitó escribir tests que fallaran por asunciones incorrectas del enunciado (p. ej. asumir `404` donde la API responde `200`) y, más importante, permitió que los tests **codifiquen y protejan** ese comportamiento real como regresión futura.

## 3. Hallazgos de contrato (API real vs. enunciado)

| # | Lo que dice el enunciado | Lo que hace `fakestoreapi.com` | Decisión tomada en el test |
|---|---|---|---|
| 1 | Caso 3 (crear producto): status 200 | Responde **201 Created** | Se valida `201` (semánticamente correcto para creación) y se documenta la discrepancia. |
| 2 | Caso 5 (producto no encontrado): "validar status code" (implícito 404) | Responde **200 OK** con **body completamente vacío** (`Content-Length: 0`, ni `{}` ni `null`) | Se valida el contrato real (`200` + cuerpo vacío) en vez de forzar un `404` que la API nunca retorna. |
| 3 | Caso 6 (categoría inválida): "validar manejo de error apropiado" | Responde **200 OK** con arreglo vacío `[]` (sin error) | Coincide con lo sugerido por el propio enunciado ("o un array vacío"); se valida `== []`. |
| 4 | Caso 7 (payload vacío en creación): "validar manejo de errores apropiado" | Responde **201 Created** igualmente, sin ningún error de validación; solo retorna `{"id": N}` | La API **no realiza validación de negocio** en el backend. El test documenta y **codifica este riesgo como hallazgo de calidad**, en lugar de forzar artificialmente un `4xx` que la API jamás produce. |
| 5 | Caso 4 (actualizar producto): no se menciona persistencia | El `PUT` responde `200` reflejando los datos enviados, pero un `GET` posterior al mismo `id` retorna el **producto original sin cambios** | Se agregó un escenario adicional (`@hallazgo`) que **prueba explícitamente la no persistencia**: es un mock que simula la operación sin escribir a una base de datos real. |
| 6 | Caso 1 vs Caso 3: no se compara el esquema de lectura vs. escritura | La respuesta de `POST /products` **no incluye** el objeto `rating` presente en `GET /products/{id}` | Se valida `response.rating == '#notpresent'` en la creación, documentando que el esquema de escritura difiere del de lectura. |
| 7 | Caso 8 (límite de productos): "validar que el parámetro de paginación funciona correctamente" | `limit` solo se aplica si es un entero positivo. Equivale a `Array.prototype.slice(0, limit)` en el backend: `limit=5` → 5 items; `limit=0` → se ignora (retorna los 20); `limit=-1` → aplica slice negativo de JS y **descarta el último elemento** (19 de 20); `limit` no numérico → se ignora (retorna los 20) | Se agregó un `Scenario Outline` con los 3 edge cases (`0`, `-1`, `abc`) para caracterizar y dejar documentado el comportamiento exacto del parámetro, no solo el caso feliz (`limit=5`). |

## 4. ¿Por qué no "forzar" los status codes del enunciado?

Una automatización que fuerza aserciones contra el comportamiento *deseado* en lugar del *real* genera **falsos positivos de defecto**: el pipeline de CI queda rojo permanentemente por un "bug" que en realidad es el comportamiento documentado (o no documentado, pero real) de un servicio de terceros sobre el que el equipo QA no tiene control. La automatización debe:
1. Validar el contrato **real** vigente (lo que efectivamente protege contra regresiones).
2. **Documentar la discrepancia** frente al comportamiento esperado/ideal (lo que efectivamente informa al negocio/desarrollo de un gap).

Ambas cosas se hicieron aquí: los tests pasan (protegen el contrato real) y cada discrepancia queda registrada tanto en el comentario del propio `.feature` como en este documento (informa el gap).

## 5. Riesgo de calidad más relevante encontrado

El hallazgo #4 (Caso 7) es el más significativo desde la perspectiva de un QA: **`fakestoreapi.com` no aplica ninguna validación de negocio en el backend de creación de productos**. Un payload vacío (`{}`) es aceptado con `201 Created` igual que uno completo. Si este fuera un backend productivo real (no una API pública de demostración), esto representaría un defecto de severidad alta: permitiría crear registros corruptos/incompletos en el catálogo sin ningún mecanismo de rechazo. Se recomienda, para un contrato real de e-commerce, exigir como mínimo: `title`, `price` (> 0) y `category` no vacíos, y que el backend responda `400 Bad Request` con detalle del campo faltante cuando no se cumplan.

## 6. Otros hallazgos

- **Ausencia de paginación real vía metadata**: el endpoint `/products` no retorna cabeceras ni campos de metadata de paginación (`total`, `page`, `X-Total-Count`, etc.); `limit` es la única forma de controlar el tamaño de la respuesta, y como se documentó, su comportamiento en valores límite (`0`, negativos, no numéricos) no está especificado ni es intuitivo.
- **API pública compartida**: al ser un servicio público de terceros usado por múltiples consumidores simultáneamente, los IDs devueltos por `POST /products` (autoincrementales) no son estables entre corridas ni predecibles; el diseño de los tests evita depender de un ID fijo devuelto por una creación previa.
- **Independencia de escenarios**: dado el hallazgo de no-persistencia (#5), cada escenario es atómico y no depende del estado dejado por otro; esto además permite ejecutar la suite en paralelo (`Runner.parallel(5)`) sin condiciones de carrera de datos.

## 7. Arquitectura y principios aplicados

- **DRY / Single Source of Truth**: el contrato JSON de `Product` vive en un único lugar (`api/common/schemas.feature`) y se reutiliza vía `call read(...)` en cada feature que lo necesita, evitando duplicar `match` idénticos.
- **Separación de datos y lógica**: la fixture estática (`api/data/valid-product-template.json`) separa el *dato* del *escenario*; el dato dinámico (`java.util.UUID.randomUUID()`) se inyecta en runtime vía `karate.merge`, cubriendo ambos tipos de manejo de datos exigidos por el reto sin mezclar responsabilidades.
- **Cohesión por recurso**: un `.feature` por endpoint (no por caso aislado) agrupa el escenario positivo y su contraparte negativa cuando comparten el mismo endpoint (Casos 2/6 y 3/7), reduciendo el número de archivos sin perder trazabilidad (cada `Scenario` mantiene su tag `@casoN`).
- **Trazabilidad**: tags (`@caso1`...`@caso8`, `@positivo`, `@negativo`, `@edge-case`, `@smoke`, `@hallazgo`) permiten filtrar la ejecución (`mvn test -Dkarate.options="--tags @smoke"`) y mapear 1:1 cada escenario contra la sección del enunciado que cubre.

## 8. Qué se automatizaría a continuación (fuera de alcance de este reto)

1. Cobertura de los recursos **Carts**, **Users** y **Auth** mencionados en el enunciado (no incluidos en el detalle de los 8 casos, por lo que se priorizó profundidad en Products sobre amplitud superficial en los cuatro recursos).
2. Un `Scenario Outline` de contract-testing que recorra **todas** las categorías reales (`/products/categories`) y valide el Caso 2 contra cada una, en vez de solo `electronics`.
3. Integración en un pipeline CI (GitHub Actions) que publique `target/cucumber-html-reports` como artefacto y falle el build si `results.getFailCount() > 0`.
4. Pruebas de contrato con un esquema JSON Schema formal (Draft-07) versionado, en vez de `match` inline, si el equipo decide adoptar un enfoque de contract-testing más estricto compartido con otros consumidores de la API.
