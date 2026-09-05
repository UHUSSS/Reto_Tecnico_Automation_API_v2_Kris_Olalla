# Reto Técnico – Automatización de Pruebas de APIs
Framework de automatización de pruebas de API con **[Karate DSL](https://karatelabs.github.io/karate/)** sobre [Fake Store API](https://fakestoreapi.com/docs), enfocado en el recurso **Products**.

## ¿Por qué Karate?

- **BDD sin capas redundantes**: el `.feature` (Gherkin) *es* el test, no hay que mantener step definitions manuales como en Cucumber+RestAssured. Menos código, menos puntos de fallo.
- **Match nativo tipado**: `match` valida estructura, tipos de dato y valores en una sola expresión (`'#number'`, `'#string'`, `'#regex ...'`, `'#notpresent'`, `#[n]`), sin librerías de aserciones adicionales.
- **Reporte con evidencia completa out-of-the-box**: cada step deja request/response completos (URL, headers, body) en el reporte HTML nativo, exactamente lo que exige el entregable de reportería de este reto.
- **JUnit5 + Maven**: se integra igual que cualquier suite Java (`mvn test`), corre en paralelo, e importa en cualquier CI sin configuración adicional.

## Tecnologías y versiones

| Herramienta | Versión | Uso |
|---|---|---|
| [Karate DSL](https://github.com/karatelabs/karate) | 1.4.1 | Motor de pruebas de API (BDD) |
| JUnit 5 (Jupiter) | 5.10.2 (vía `karate-junit5`) | Runner de la suite |
| [cucumber-reporting](https://github.com/damianszczepanik/cucumber-reporting) (masterthought) | 5.7.7 | Reporte HTML enriquecido a partir del `cucumber.json` de Karate |
| Java (JDK) | 17 o 21 LTS (probado con Eclipse Temurin 21.0.12) | Runtime |
| Apache Maven | 3.9.x | Build y ejecución |

## Estructura del repositorio

```
.
├── pom.xml
├── src/test/java/
│   ├── karate-config.js                  # config global (baseUrl, timeouts, logging)
│   ├── api/
│   │   ├── TestRunner.java               # runner único (JUnit5) de toda la suite
│   │   ├── common/
│   │   │   └── schemas.feature           # contrato JSON de Products, reutilizado (DRY)
│   │   ├── data/
│   │   │   └── valid-product-template.json  # dato de prueba estático (fixture)
│   │   └── products/
│   │       ├── get-product.feature           # Caso 1 (positivo)
│   │       ├── list-by-category.feature      # Caso 2 (positivo) + Caso 6 (negativo)
│   │       ├── create-product.feature        # Caso 3 (positivo) + Caso 7 (negativo)
│   │       ├── update-product.feature        # Caso 4 (positivo) + hallazgo de persistencia
│   │       ├── product-not-found.feature     # Caso 5 (negativo)
│   │       └── list-products-limit.feature   # Caso 8 (edge cases de paginación)
│   └── demo/                              # NO forma parte de la suite (ver seccion "Reporte de ejecucion")
│       ├── demo-failure.feature           #   escenario deliberadamente incorrecto (evidencia de fallo)
│       └── DemoFailureRunner.java         #   runner aislado, excluido del `mvn test` por defecto
├── evidencias/                            # snapshot COMMITEADO de la ultima ejecucion exitosa (14/14)
│   ├── karate-reports/                    #   copia de target/karate-reports (reporte nativo de Karate,
│   │                                      #   incluye demo.demo-failure.html: evidencia de fallo)
│   └── cucumber-html-reports/             #   copia de target/cucumber-html-reports (reporte masterthought)
├── target/karate-reports/                # reporte nativo de Karate (se regenera en cada `mvn test`)
├── target/cucumber-html-reports/         # reporte enriquecido masterthought (se regenera en cada `mvn test`)
├── README.md
└── EVALUATION.md
```

**Decisiones de diseño:**
- **Un `.feature` por endpoint/recurso**, no por caso individual: los Casos 2/6 y 3/7 comparten el mismo endpoint, así que su escenario positivo y negativo conviven en el mismo archivo — máxima cohesión, fácil de ubicar (principio de responsabilidad única a nivel de archivo).
- **`common/schemas.feature`** centraliza el contrato de datos de `Product` (single source of truth): si la API cambia un campo, se actualiza en un solo lugar y todos los `.feature` que lo consumen vía `call read(...)` quedan alineados (evita duplicación / DRY).
- **`data/valid-product-template.json`** separa el dato de prueba **estático** (fixture versionado) del dato **dinámico** (título único generado con `java.util.UUID.randomUUID()` en cada ejecución vía `karate.merge`), cubriendo ambos tipos de manejo de datos exigidos por el reto.
- **Tags** (`@positivo`, `@negativo`, `@casoN`, `@edge-case`, `@smoke`) permiten ejecutar subconjuntos (`mvn test -Dkarate.options="--tags @smoke"`) sin tocar código.

## Cobertura de casos implementados

Se implementaron los **8 casos** descritos en el reto (4 positivos + 4 negativos/edge-case), superando el mínimo de 4 exigido. Materializados en **14 escenarios ejecutables** (100% en verde en la última corrida — ver [`EVALUATION.md`](./EVALUATION.md#11-resultados-de-la-última-ejecución)), ya que varios casos se ampliaron con sub-escenarios de edge case (p. ej. Caso 8 con `limit=5/0/-1/abc`) y se sumó un escenario adicional de hallazgo (no persistencia en el Caso 4).

| # | Caso | Tipo | Archivo |
|---|---|---|---|
| 1 | Obtener producto específico | Positivo | `get-product.feature` |
| 2 | Listar productos por categoría | Positivo | `list-by-category.feature` |
| 3 | Crear producto exitosamente | Positivo | `create-product.feature` |
| 4 | Actualizar producto completo | Positivo | `update-product.feature` |
| 5 | Producto no encontrado | Negativo | `product-not-found.feature` |
| 6 | Categoría inválida | Negativo | `list-by-category.feature` |
| 7 | Crear producto con datos inválidos | Negativo | `create-product.feature` |
| 8 | Validación de límites de productos | Edge case | `list-products-limit.feature` |

> Varios de estos casos revelaron comportamientos reales de `fakestoreapi.com` que **difieren del enunciado** (p. ej. status codes esperados o manejo de errores). Cada hallazgo está documentado en el propio `.feature` (comentario junto a la aserción) y consolidado con más detalle en [`EVALUATION.md`](./EVALUATION.md).

## Requisitos previos

- **Java 17 o 21 (LTS)** (`java -version`)
- **Maven 3.8+** (`mvn -version`)
- Conexión a internet (la suite corre contra `https://fakestoreapi.com`, una API pública real, no un mock local)

## Cómo ejecutar

```bash
# clonar el repositorio
git clone <url-del-repo>
cd Reto_Tecnico_Automation_API_v2

# ejecutar toda la suite
mvn test

# ejecutar solo un subconjunto por tag (opcional)
mvn test -Dkarate.options="--tags @positivo"
mvn test -Dkarate.options="--tags @negativo"
mvn test -Dkarate.options="--tags @smoke"
```

Al finalizar, revisar:
- **`target/karate-reports/karate-summary.html`** → reporte nativo de Karate (resumen, tiempos por escenario/paso, request/response completos de cada llamada).
- **`target/cucumber-html-reports/overview-features.html`** → reporte enriquecido (masterthought) con gráficos de tendencia y navegación por feature/tag.
- **`target/karate-reports/*.json`** → resultado crudo (cucumber-json), útil para integrarlo a un pipeline de CI.

> 📁 **`evidencias/`** contiene una copia estática de estos mismos reportes correspondiente a la última ejecución exitosa (**14/14 escenarios en verde**), committeada al repositorio para que puedan revisarse directamente en el navegador sin necesidad de instalar Java/Maven ni ejecutar la suite.

## Reporte de ejecución (entregable 7.2)

| Requisito | Dónde verlo |
|---|---|
| Total de pruebas ejecutadas | `evidencias/karate-reports/karate-summary.html` → 7 features / 14 escenarios |
| Tasa de éxito / fallo | 14/14 (100%) ver `karate-summary.html` o [`EVALUATION.md`](./EVALUATION.md#11-resultados-de-la-última-ejecución) |
| Tiempo de ejecución por prueba | Tabla en [`EVALUATION.md`](./EVALUATION.md#13-tiempo-de-ejecución-por-escenario), y detalle por paso dentro de cada `.html` de `evidencias/karate-reports/` |
| Detalle de fallos con request/response completos | La suite no tiene fallos (0/14). Se dejó un escenario de demostración aislado — ver `evidencias/karate-reports/demo.demo-failure.html` y el detalle en [`EVALUATION.md`](./EVALUATION.md#14-evidencia-de-detalle-de-fallos-escenario-de-demostración) |

Ese escenario de demostración (`src/test/java/demo/demo-failure.feature`) fuerza a propósito una aserción incorrecta para dejar evidencia real de cómo Karate reporta un fallo (request, response y resultado de la validación completos). **No forma parte de la suite de regresión**: vive fuera del paquete `api` y su runner (`DemoFailureRunner.java`) está excluido del `mvn test` por defecto (el `pom.xml` restringe `surefire` a `TestRunner.java` únicamente). Para regenerarlo:

```bash
mvn test -Dtest=DemoFailureRunner
```

## Reproducibilidad

La suite no depende de estado previo ni de datos sembrados manualmente: cada escenario genera su propio dato dinámico cuando lo necesita (`java.util.UUID.randomUUID()`) y no encadena escenarios entre sí (cada uno es atómico e independiente), por lo que puede ejecutarse en paralelo (`Runner.parallel(5)`, configurado en `TestRunner.java`) o repetirse cualquier número de veces sin efectos colaterales.

