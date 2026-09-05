Feature: Products - Actualizar producto completo (Caso 4 positivo)

  Background:
    * url baseUrl
    * def productTemplate = read('classpath:api/data/valid-product-template.json')

  @caso4 @positivo
  Scenario: PUT /products/{id} con datos completos actualiza el producto correctamente
    * def uniqueTitle = 'QA Updated Product ' + java.util.UUID.randomUUID()
    * def payload = karate.merge(productTemplate, { title: uniqueTitle, price: 49.99, category: 'jewelery' })
    Given path 'products', 1
    And request payload
    When method put
    Then status 200
    And match response.id == 1
    # se valida CADA campo del producto contra lo enviado (todos los campos, no solo algunos)
    And match response.title == payload.title
    And match response.price == payload.price
    And match response.description == payload.description
    And match response.category == payload.category
    And match response.image == payload.image

  @caso4 @positivo @hallazgo
  Scenario: Hallazgo - fakestoreapi.com no persiste realmente la actualizacion
    # La respuesta del PUT refleja fielmente los datos enviados (el CONTRATO es correcto),
    # pero un GET posterior al mismo recurso retorna el estado ORIGINAL del producto.
    # Conclusion (ver EVALUATION.md): es una API mock que simula la operacion sin
    # escribir en una base de datos real; no se puede usar GET para verificar
    # persistencia entre escenarios, la unica fuente de verdad es la respuesta del propio PUT.
    * def uniqueTitle = 'QA Persistence Check ' + java.util.UUID.randomUUID()
    * def payload = karate.merge(productTemplate, { title: uniqueTitle })
    Given path 'products', 1
    And request payload
    When method put
    Then status 200
    And match response.title == payload.title

    Given path 'products', 1
    When method get
    Then status 200
    And match response.title != payload.title
