defmodule Recursos do

  @moduledoc """
  Módulo encargado de la gestión y administración de los recursos disponibles dentro del sistema de coordinación
  y gestion de emergencias.

  - Autores: Briyith Sanchez Alonso y Nicolas Arango Gutierrez
  - Fecha: Octubre del 2026
  - Licencia: GNU GPL V3
  """

  @doc """
  Funcion para registrar un nuevo recurso dentro del inventario
  del sistema.

  ## Parametros
  - Recursos: Lista que contiene los recursos registrados.
  - Datos: Mapa con la informacion del nuevo recurso:

  ## Ejemplo
  iex> datos = %{nombre: "Agua potable", categoria: "Suministros", cantidad: 50, unidad: "litros", ubicacion: "Centro"}
  iex> Recursos.registrar_recurso([], datos)
  {:ok, [nuevo_recurso]}
  """
  def registrar_recurso(recursos, datos) do

    nombre = Map.get(datos, :nombre)
    categoria = Map.get(datos, :categoria)
    cantidad = Map.get(datos, :cantidad)
    unidad = Map.get(datos, :unidad)
    ubicacion = Map.get(datos, :ubicacion)

    cond do
      not is_binary(nombre) or nombre == "" ->
        {:error, "El nombre del recurso no es válido"}

      not is_binary(categoria) or categoria == "" ->
        {:error, "La categoría no es válida"}

      not is_integer(cantidad) or cantidad < 0 ->
        {:error, "La cantidad no puede ser negativa"}

      not is_binary(unidad) or unidad == "" ->
        {:error, "La unidad no es válida"}

      not is_binary(ubicacion) or ubicacion == "" ->
        {:error, "La ubicación no es válida"}

      true ->
        codigo = generar_codigo(recursos)

        nuevo_recurso = %{
          codigo: codigo,
          nombre: nombre,
          categoria: categoria,
          cantidad_disponible: cantidad,
          unidad: unidad,
          ubicacion: ubicacion,
          historial: []
        }

        {:ok, [nuevo_recurso | recursos]}
    end
  end

  @doc """
  Función para generar automaticamente el código identificador
  de un nuevo recurso.

  ## Parametros
  - Recursos: Lista de recursos registrados en el inventario.

  ## Ejemplo
  iex> Recursos.generar_codigo([])
  "REC-001"
  """
  def generar_codigo(recursos) do

    numero = length(recursos) + 1

    "REC-" <> String.pad_leading(
      Integer.to_string(numero),
      3,
      "0"
    )
  end


  @doc """
  Funcion para listar todos los recursos registrados en el sistema.

  ## Parametros
  - Recursos: Lista que contiene los recursos registrados.

  ## Ejemplo
  iex> Recursos.listar_recursos(recursos)
  {:ok, lista_de_recursos}
  """
  def listar_recursos(recursos) do
    {:ok, recursos}
  end


 @doc """
  Funcion para buscar un recurso especifico mediante su codigo
  identificador.

  ## Parametros
  - Recursos: Lista de recursos registrados.
  - Codigo: Codigo identificador del recurso que se desea buscar.
  - Ubicacion: Ubicacion del recurso que se desea buscar.

  ## Ejemplo
  iex> Recursos.buscar_recurso(recursos, "REC-001", "Centro")
  {:ok, recurso_encontrado}
  """
  def buscar_recurso(recursos, codigo, ubicacion) do

    recurso = Enum.find(recursos, fn r ->
      r.codigo == codigo and r.ubicacion == ubicacion
    end)

    if recurso == nil do
      {:error, "El recurso no existe en esa ubicación"}
    else
      {:ok, recurso}
    end
  end

@doc """
  Funcion para consultar el inventario aplicando diferentes filtros.

  ## Parametros
  - Recursos: Lista de recursos registrados.
  - Filtros: Mapa que contiene los campos y valores que se desean
    utilizar para filtrar los recursos.

  ## Ejemplo
  iex> Recursos.consultar_inventario(recursos, %{ubicacion: "Centro"})
  {:ok, recursos_encontrados}
  """
  def consultar_inventario(recursos, filtros) do

    recursos_encontrados = Enum.filter(
      recursos,
      fn recurso ->

        Enum.all?(filtros, fn {campo, valor} ->

          Map.get(recurso, campo) == valor

        end)

      end
    )

    {:ok, recursos_encontrados}
  end

@doc """
Registra una entrada de recursos en una ubicación.
- Recursos: lista de recursos.
- Codigo: código identificador.
- Ubicacion: centro o albergue.
- Cantidad: unidades que ingresan.
- Descripcion: motivo de la entrada.
"""
def registrar_entrada(recursos, codigo, ubicacion, cantidad, descripcion) do
  case buscar_recurso(recursos, codigo, ubicacion) do
    {:error, motivo} ->
      {:error, motivo}

    {:ok, _recurso} ->
      cond do
        not is_integer(cantidad) or cantidad <= 0 ->
          {:error, "La cantidad debe ser mayor que cero"}

        not is_binary(descripcion) or descripcion == "" ->
          {:error, "La descripción no es válida"}

        true ->
          movimiento = %{
            tipo: :entrada,
            cantidad: cantidad,
            descripcion: descripcion,
            fecha: DateTime.utc_now()
          }

          recursos_actualizados = Enum.map(recursos, fn r ->
            if r.codigo == codigo and r.ubicacion == ubicacion do
              %{
                r |
                cantidad_disponible: r.cantidad_disponible + cantidad,
                historial: [movimiento | r.historial]
              }
            else
              r
            end
          end)

          {:ok, recursos_actualizados}
      end
  end
end

@doc """
Registra una salida de recursos de una ubicación.
- Recursos: lista de recursos.
- Codigo: código identificador.
- Ubicacion: centro o albergue.
- Cantidad: unidades que salen.
- Descripcion: motivo de la salida.
"""
def registrar_salida(recursos, codigo, ubicacion, cantidad, descripcion) do
  case buscar_recurso(recursos, codigo, ubicacion) do
    {:error, motivo} ->
      {:error, motivo}

    {:ok, recurso} ->
      cond do
        not is_integer(cantidad) or cantidad <= 0 ->
          {:error, "La cantidad debe ser mayor que cero"}

        not is_binary(descripcion) or descripcion == "" ->
          {:error, "La descripción no es válida"}

        cantidad > recurso.cantidad_disponible ->
          {:error, "No hay suficientes recursos disponibles"}

        true ->
          movimiento = %{
            tipo: :salida,
            cantidad: cantidad,
            descripcion: descripcion,
            fecha: DateTime.utc_now()
          }

          recursos_actualizados = Enum.map(recursos, fn r ->
            if r.codigo == codigo and r.ubicacion == ubicacion do
              %{
                r |
                cantidad_disponible: r.cantidad_disponible - cantidad,
                historial: [movimiento | r.historial]
              }
            else
              r
            end
          end)

          {:ok, recursos_actualizados}
      end
  end
end

  @doc """
  Función para transferir recursos entre dos centros de almacenamiento.

  ## Parametros
  - Recursos: Lista de recursos registrados.
  - Codigo: Codigo identificador del recurso que se transferira.
  - Origen: Nombre del centro desde donde salen los recursos.
  - Destino: Nombre del centro que recibe los recursos.
  - Cantidad: Cantidad de unidades que se desean transferir.

  ## Ejemplo
  iex> Recursos.transferir_recurso(recursos, "REC-001", "Centro", "Norte", 10)
  {:ok, recursos_actualizados}
  """
  def transferir_recurso(recursos, codigo, origen, destino, cantidad ) do

    recurso_origen = Enum.find(
      recursos,
      fn r ->
        r.codigo == codigo and r.ubicacion == origen
      end
    )

    recurso_destino = Enum.find(
      recursos,
      fn r ->
        r.codigo == codigo and r.ubicacion == destino
      end
    )

    cond do
      not is_binary(origen) or origen == "" ->
        {:error, "El centro de origen no es válido"}

      not is_binary(destino) or destino == "" ->
        {:error, "El centro de destino no es válido"}

      origen == destino ->
        {:error, "El origen y el destino deben ser diferentes"}

      not is_integer(cantidad) or cantidad <= 0 ->
        {:error, "La cantidad debe ser mayor que cero"}

      recurso_origen == nil ->
        {:error, "El recurso no existe en el centro de origen"}

      cantidad > recurso_origen.cantidad_disponible ->
        {:error, "No hay suficientes recursos para transferir"}

      true ->

        movimiento_salida = %{
          tipo: :transferencia_salida,
          cantidad: cantidad,
          destino: destino,
          fecha: DateTime.utc_now()
        }

        movimiento_entrada = %{
          tipo: :transferencia_entrada,
          cantidad: cantidad,
          origen: origen,
          fecha: DateTime.utc_now()
        }

        recursos_actualizados = Enum.map(
          recursos,
          fn r ->

            cond do
              r.codigo == codigo and r.ubicacion == origen ->
                %{
                  r |
                  cantidad_disponible:
                    r.cantidad_disponible - cantidad,
                  historial: [
                    movimiento_salida | r.historial
                  ]
                }

              r.codigo == codigo and r.ubicacion == destino ->
                %{
                  r |
                  cantidad_disponible:
                    r.cantidad_disponible + cantidad,
                  historial: [
                    movimiento_entrada | r.historial
                  ]
                }

              true ->
                r
            end

          end
        )

        if recurso_destino == nil do

          nuevo_recurso = %{
            codigo: codigo,
            nombre: recurso_origen.nombre,
            categoria: recurso_origen.categoria,
            cantidad_disponible: cantidad,
            unidad: recurso_origen.unidad,
            ubicacion: destino,
            historial: [movimiento_entrada]
          }

          {:ok, [nuevo_recurso | recursos_actualizados]}

        else
          {:ok, recursos_actualizados}
        end
    end
  end



  @doc """
Consulta los movimientos de un recurso en una ubicación.
- Recursos: lista de recursos.
- Codigo: código identificador.
- Ubicacion: centro o albergue.
"""
def consultar_historial(recursos, codigo, ubicacion) do
  case buscar_recurso(recursos, codigo, ubicacion) do
    {:ok, recurso} ->
      {:ok, recurso.historial}

    {:error, motivo} ->
      {:error, motivo}
  end
end

  @doc """
  Funcion para identificar los recursos que tienen una cantidad
  disponible menor o igual al limite establecido.

  ## Parametros
  - Recursos: Lista de recursos registrados.
  - Limite: Cantidad maxima utilizada como referencia para identificar inventarios bajos.

  ## Ejemplo
  iex> Recursos.recursos_bajos(recursos, 10)
  {:ok, recursos_con_inventario_bajo}
  """
  def recursos_bajos(recursos, limite) do

    if not is_integer(limite) or limite < 0 do
      {:error, "El límite no es válido"}
    else

      recursos_encontrados = Enum.filter(
        recursos,
        fn recurso ->
          recurso.cantidad_disponible <= limite
        end
      )

      {:ok, recursos_encontrados}
    end
  end

end
