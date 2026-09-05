Feature: Products - Crear producto (Caso 3 positivo / Caso 7 negativo)

  Background:
    * url baseUrl
    * def productTemplate = read('classpath:api/data/valid-product-template.json')

  @caso3 @positivo
  Scenario: POST /products con datos validos crea el producto y retorna su ID
    # dato dinamico: titulo unico por ejecucion para evitar colisiones/falsos positivos
    * def uniqueTitle = 'QA Automation Product ' + java.util.UUID.randomUUID()
    * def payload = karate.merge(productTemplate, { title: uniqueTitle })
    Given path 'products'
    And request payload
    When method post
    # Hallazgo (ver EVALUATION.md): el enunciado indica 200; fakestoreapi.com responde
    # 201 Created (mas correcto semanticamente para una creacion). Se valida el contrato real.
    Then status 201
    And match response.id == '#number'
    And match response.title == payload.title
    And match response.price == payload.price
    And match response.description == payload.description
    And match response.category == payload.category
    And match response.image == payload.image
    # Hallazgo: la respuesta de creacion NO incluye el objeto 'rating' presente en el GET
    # (diferencia de contrato entre el esquema de lectura y el de escritura de este recurso)
    And match response.rating == '#notpresent'

  @caso7 @negativo
  Scenario: POST /products con payload vacio - la API no valida campos obligatorios
    # Hallazgo de calidad (ver EVALUATION.md): fakestoreapi.com es un mock sin
    # validacion de reglas de negocio en el backend. Un payload {} es aceptado
    # igual que uno valido: responde 201 y solo retorna un id autogenerado, sin
    # ningun error 4xx ni mensaje de validacion. Se documenta como riesgo si el
    # contrato real de un backend productivo tuviera que exigir campos obligatorios.
    Given path 'products'
    And request {}
    When method post
    Then status 201
    And match response == { id: '#number' }
    And match response.title == '#notpresent'
    And match response.price == '#notpresent'
