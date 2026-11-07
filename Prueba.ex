
reportes = []

# Registrar mascota perdida
{:ok, reportes} =
  Mascotas.registrar(reportes, %{
    id: "M001",
    tipo: "perdida",
    especie: "perro",
    nombre: "Max",
    caracteristicas: "mancha blanca en el pecho",
    color: "cafe",
    tamanio: "mediano",
    zona: "zona_norte",
    contacto: "3001234567"
  })

# Registrar mascota encontrada
{:ok, reportes} =
  Mascotas.registrar(reportes, %{
    id: "M002",
    tipo: "encontrada",
    especie: "perro",
    nombre: "Max",
    caracteristicas: "mancha blanca en el pecho",
    color: "cafe",
    tamanio: "mediano",
    zona: "zona_norte",
    contacto: "3007654321"
  })

# Buscar coincidencias
{:ok, reportes, coincidencias} =
  Mascotas.buscar_coincidencias(reportes, "M001")

IO.inspect(coincidencias, label: "Coincidencias encontradas")

# Confirmar coincidencia
{:ok, reportes} =
  Mascotas.confirmar_coincidencia(reportes, "M001", "M002")

IO.inspect(reportes, label: "Reportes resueltos")

# Intentar confirmar nuevamente
IO.inspect(
  Mascotas.confirmar_coincidencia(reportes, "M001", "M002"),
  label: "Segunda confirmación"
)

# Intentar buscar coincidencias de un reporte resuelto
IO.inspect(
  Mascotas.buscar_coincidencias(reportes, "M001"),
  label: "Búsqueda de reporte resuelto"
)

# Intentar comparar dos reportes del mismo tipo
{:ok, reportes2} =
  Mascotas.registrar(reportes, %{
    id: "M003",
    tipo: "perdida",
    especie: "perro",
    nombre: "Max",
    caracteristicas: "mancha blanca en el pecho",
    color: "cafe",
    tamanio: "mediano",
    zona: "zona_norte",
    contacto: "3001111111"
  })

IO.inspect(
  Mascotas.confirmar_coincidencia(reportes2, "M001", "M003"),
  label: "Reportes del mismo tipo"
)
