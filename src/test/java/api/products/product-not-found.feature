Feature: Products - Producto no encontrado (Caso 5 negativo)

  Background:
    * url baseUrl

  @caso5 @negativo
  Scenario: GET /products/999999 - la API no retorna 404, responde 200 con cuerpo vacio
    # Hallazgo (ver EVALUATION.md): fakestoreapi.com no implementa manejo de error HTTP
    # para IDs inexistentes. Responde 200 OK con el body completamente vacio (Content-Length: 0,
    # ni siquiera '{}' o 'null'). Se valida el contrato REAL en vez de asumir un 404 que la
    # API nunca produce.
    Given path 'products', 999999
    When method get
    Then status 200
    And match response == ''
    And assert responseBytes.length == 0

  @caso5 @negativo @edge-case
  Scenario: GET /products/{id no numerico} - mismo comportamiento inconsistente
    Given path 'products', 'abc'
    When method get
    Then status 200
    And match response == ''
    And assert responseBytes.length == 0
