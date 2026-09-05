Feature: Products - Listar productos por categoria (Caso 2 positivo / Caso 6 negativo)

  Background:
    * url baseUrl
    * def schemas = call read('classpath:api/common/schemas.feature')

  @caso2 @positivo
  Scenario: GET /products/category/electronics retorna solo productos de esa categoria
    Given path 'products', 'category', 'electronics'
    When method get
    Then status 200
    # la categoria si tiene productos: el arreglo no debe venir vacio
    And match response == '#[_ > 0]'
    And match each response == schemas.productSchema
    And match each response[*].category == 'electronics'
    # validacion adicional: sin duplicados de id en la respuesta
    * def ids = karate.map(response, function(p){ return p.id })
    * def uniqueIds = karate.distinct(ids)
    * assert ids.length == uniqueIds.length

  @caso6 @negativo
  Scenario: GET /products/category/{categoria-inexistente} - manejo de error
    # Hallazgo (ver EVALUATION.md): fakestoreapi.com NO responde 404 para una categoria
    # inexistente. Responde 200 OK con un arreglo JSON vacio. Se valida el contrato REAL
    # de la API en lugar de asumir un status de error que esta API no implementa.
    Given path 'products', 'category', 'categoria-inexistente-xyz'
    When method get
    Then status 200
    And match response == []
