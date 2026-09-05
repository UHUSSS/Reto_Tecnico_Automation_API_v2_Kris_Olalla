Feature: Products - Obtener producto especifico (Caso 1)

  Background:
    * url baseUrl
    * def schemas = call read('classpath:api/common/schemas.feature')

  @caso1 @positivo @smoke
  Scenario: GET /products/{id} retorna el producto con estructura y tipos de dato correctos
    Given path 'products', 1
    When method get
    Then status 200
    And match response == schemas.productSchema
    And match response.id == 1
    # tipo de dato explicito: price debe ser number, no string
    And match response.price == '#number'
    And assert response.price > 0
    # estructura del objeto rating (rate, count)
    And match response.rating == { rate: '#number', count: '#number' }
    And assert response.rating.rate >= 0
    And assert response.rating.rate <= 5
    And assert response.rating.count >= 0
    # validaciones adicionales: campos de texto no vacios y URL de imagen valida
    And match response.title != ''
    And match response.category != ''
    And match response.image == '#regex https?://.+'
