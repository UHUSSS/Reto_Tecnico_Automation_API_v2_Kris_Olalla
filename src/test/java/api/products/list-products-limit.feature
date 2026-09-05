Feature: Products - Validacion de limite de productos (Caso 8)

  Background:
    * url baseUrl
    * def schemas = call read('classpath:api/common/schemas.feature')

  @caso8 @positivo @edge-case
  Scenario: GET /products?limit=5 retorna como maximo 5 productos
    Given path 'products'
    And param limit = 5
    When method get
    Then status 200
    And match response == '#[5]'
    And match each response == schemas.productSchema

  @caso8 @negativo @edge-case
  Scenario Outline: GET /products?limit=<limit> - comportamiento en valores limite (edge cases)
    # Hallazgo (ver EVALUATION.md): el parametro limit solo se aplica si es un entero
    # positivo (comportamiento equivalente a Array.prototype.slice(0, limit) en el
    # backend). limit=0 y limit no-numerico son tratados como "falsy" y se ignoran
    # (retornan el catalogo completo de 20 productos); limit=-1 SI se aplica con
    # semantica de slice negativo de JS (recorta el ultimo elemento: 20 -> 19).
    Given path 'products'
    And param limit = '<limit>'
    When method get
    Then status 200
    And match response == '#[<esperado>]'

    Examples:
      | limit | esperado |
      | 0     | 20       |
      | -1    | 19       |
      | abc   | 20       |
