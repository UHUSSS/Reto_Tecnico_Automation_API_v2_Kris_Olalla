Feature: DEMO - Evidencia de reporte de fallo (NO forma parte de la suite de regresion)

  # Este feature NO se ejecuta con `mvn test` (ver pom.xml: surefire solo incluye TestRunner.java
  # por defecto). Existe unicamente para dejar en el repositorio una evidencia REAL y navegable
  # de como Karate reporta un fallo -con request/response completos y el resultado de cada
  # validacion- ya que la suite principal esta 100% en verde (14/14) y por lo tanto no genera
  # ningun fallo real que mostrar para el entregable 7.2 (Reporte de ejecucion).
  #
  # Para regenerar esta evidencia: mvn test -Dtest=DemoFailureRunner
  # (ver README.md, seccion "Reporte de ejecucion").

  Background:
    * url baseUrl

  @demo-fallo
  Scenario: DEMO - assertion deliberadamente incorrecta para capturar el reporte de fallo
    Given path 'products', 1
    When method get
    Then status 200
    # asercion intencionalmente incorrecta: el precio real de este producto es 109.95,
    # no 999.99. Se fuerza el fallo para que el reporte capture el diff completo
    # (esperado vs. real) junto con el request/response de la llamada.
    And match response.price == 999.99
