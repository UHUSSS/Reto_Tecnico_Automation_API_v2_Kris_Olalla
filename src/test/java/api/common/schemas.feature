Feature: Esquemas JSON reutilizables (contract testing) para el recurso Products
  # Se centraliza aqui la definicion del contrato de datos de Products para que todas
  # las features lo reutilicen via 'call read(...)', evitando duplicar el esquema
  # en cada escenario (principio DRY / Single Source of Truth para el contrato).

  Scenario: definicion de esquemas
    * def productSchema =
    """
    {
      id: '#number',
      title: '#string',
      price: '#number',
      description: '#string',
      category: '#string',
      image: '#string',
      rating: { rate: '#number', count: '#number' }
    }
    """
    * def productCreateResponseSchema =
    """
    {
      id: '#number',
      title: '#string',
      price: '#number',
      description: '#string',
      category: '#string',
      image: '#string'
    }
    """
