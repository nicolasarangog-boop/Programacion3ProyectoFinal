defmodule Necesidades do

  @moduledoc """
  Módulo encargado de gestionar las necesidades registradas dentro del
  sistema de coordinación y gestión de emergencias.

  Autores:
  - Briyith Sanchez Alonso
  - Nicolás Arango Gutiérrez
  Fecha: Octubre de 2026
  Licencia: GNU GPL V3
  """
  @tipos_permitidos [
    :agua,
    :alimentos,
    :medicamentos,
    :primeros_auxilios,
    :refugio,
    :transporte,
    :rescate,
    :otra
  ]

  @prioridades_permitidas [:critica, :alta, :media, :baja]

  @estados_permitidos [
    :pendiente,
    :asignada,
    :en_atencion,
    :atendida,
    :cancelada
  ]

  @doc """
  Registra una nueva necesidad en el sistema.

  ## Parametros
  - necesidades: lista de necesidades registradas.
  - datos: mapa con la información de la nueva necesidad.

  ## Ejemplo

      datos = %{
        tipo: :agua,
        descripcion: "Agua potable para familias",
        cantidad: 100,
        zona: "Centro",
        prioridad: :critica,
        responsable: "Carlos"
      }

      Necesidades.registrar_necesidad([], datos)
  """
  def registrar_necesidad(necesidades, datos) do

    tipo = Map.get(datos, :tipo)
    descripcion = Map.get(datos, :descripcion)
    cantidad = Map.get(datos, :cantidad)
    zona = Map.get(datos, :zona)
    prioridad = Map.get(datos, :prioridad)
    responsable = Map.get(datos, :responsable)

    cond do
      tipo not in @tipos_permitidos ->
        {:error, "El tipo de necesidad no es válido"}

      not is_binary(descripcion) or descripcion == "" ->
        {:error, "La descripción no es válida"}

      not is_integer(cantidad) or cantidad <= 0 ->
        {:error, "La cantidad debe ser mayor que cero"}

      not is_binary(zona) or zona == "" ->
        {:error, "La zona no es válida"}

      prioridad not in @prioridades_permitidas ->
        {:error, "La prioridad no es válida"}

      not is_binary(responsable) or responsable == "" ->
        {:error, "El responsable no es válido"}

      true ->
        identificador = generar_identificador(necesidades)

        nueva_necesidad = %{
          id: identificador,
          tipo: tipo,
          descripcion: descripcion,
          cantidad: cantidad,
          zona: zona,
          prioridad: prioridad,
          responsable: responsable,
          estado: :pendiente,
          recursos_asignados: []
        }

        {:ok, [nueva_necesidad | necesidades]}
    end
  end


 @doc """
  Genera un identificador único consecutivo para una necesidad.

  ## Parametros
  - necesidades: lista de necesidades registradas.

  ## Ejemplo

      Necesidades.generar_identificador([])
  Resultado esperado:
      "NEC-001"
  """
  def generar_identificador(necesidades) do

    numero = length(necesidades) + 1

    "NEC-" <> String.pad_leading(
      Integer.to_string(numero),
      3,
      "0"
    )
  end

@doc """
  Devuelve la lista completa de necesidades registradas.

  ## Parametros
  - necesidades: lista de necesidades registradas.

  ## Ejemplo
      Necesidades.listar_necesidades([])
  """
  def listar_necesidades(necesidades) do
    {:ok, necesidades}
  end

  @doc """
  Consulta las necesidades aplicando uno o varios filtros.

  ## Parametros

  - necesidades: lista de necesidades registradas.
  - filtros: mapa con los campos y valores que se desean buscar.

  ## Ejemplo
      filtros = %{zona: "Centro", estado: :pendiente}
      Necesidades.consultar_necesidades([], filtros)
  """
  def consultar_necesidades(necesidades, filtros) do

    necesidades_encontradas = Enum.filter(
      necesidades,
      fn necesidad ->

        Enum.all?(filtros, fn {campo, valor} ->

          Map.get(necesidad, campo) == valor

        end)

      end
    )

    {:ok, necesidades_encontradas}
  end

 @doc """
  Ordena las necesidades según su nivel de prioridad.

  ## Parametros

  - necesidades: lista de necesidades que se desean ordenar.

  ## Ejemplo
      Necesidades.ordenar_prioridad([])
  """
  def ordenar_prioridad(necesidades) do

    orden_prioridades = [
      critica: 1,
      alta: 2,
      media: 3,
      baja: 4
    ]

    necesidades_ordenadas = Enum.sort_by(
      necesidades,
      fn necesidad ->
        Keyword.get(
          orden_prioridades,
          necesidad.prioridad,
          5
        )
      end
    )

    {:ok, necesidades_ordenadas}
  end



  @doc """
  Asigna un recurso a una necesidad registrada.

  ## Parametros

  - necesidades: lista de necesidades registradas.
  - identificador: código que identifica la necesidad.
  - codigo_recurso: código del recurso que se desea asignar.
  - cantidad: cantidad del recurso que se asignará.

  ## Ejemplo

      Necesidades.asignar_recurso(
        necesidades,
        "NEC-001",
        "REC-001",
        20
      )
  """
  def asignar_recurso(necesidades, identificador, codigo_recurso, cantidad) do

    necesidad = Enum.find(necesidades, fn n ->
      n.id == identificador
    end)

    cond do
      necesidad == nil ->
        {:error, "La necesidad no existe"}

      necesidad.estado in [:atendida, :cancelada] ->
        {:error, "La necesidad ya no puede recibir recursos"}

      not is_binary(codigo_recurso) or codigo_recurso == "" ->
        {:error, "El código del recurso no es válido"}

      not is_integer(cantidad) or cantidad <= 0 ->
        {:error, "La cantidad debe ser mayor que cero"}

      true ->

        recurso = %{
          codigo: codigo_recurso,
          cantidad: cantidad
        }

        necesidades_actualizadas = Enum.map(
          necesidades,
          fn n ->

            if n.id == identificador do

              %{
                n |
                estado: :asignada,
                recursos_asignados: [
                  recurso | n.recursos_asignados
                ]
              }

            else
              n
            end

          end
        )

        {:ok, necesidades_actualizadas}
    end
  end

 @doc """
  Actualiza el estado de una necesidad registrada.

  ## Parametros

  - necesidades: lista de necesidades registradas.
  - identificador: código que identifica la necesidad.
  - nuevo_estado: estado al que se desea cambiar la necesidad.

  ## Ejemplo

      Necesidades.actualizar_estado(
        necesidades,
        "NEC-001",
        :en_atencion
      )
  """

  def actualizar_estado(necesidades, identificador, nuevo_estado) do

    necesidad = Enum.find(necesidades, fn n ->
      n.id == identificador
    end)

    cond do
      necesidad == nil ->
        {:error, "La necesidad no existe"}

      nuevo_estado not in @estados_permitidos ->
        {:error, "El estado no es válido"}

      not transicion_valida?(necesidad.estado, nuevo_estado) ->
        {:error, "La transición de estado no está permitida"}

      true ->

        necesidades_actualizadas = Enum.map(
          necesidades,
          fn n ->

            if n.id == identificador do
              %{n | estado: nuevo_estado}
            else
              n
            end

          end
        )

        {:ok, necesidades_actualizadas}
    end
  end


 @doc """
  Comprueba si es válido cambiar una necesidad de un estado a otro.

  ## Parametros

  - estado_actual: estado en el que se encuentra la necesidad.
  - nuevo_estado: estado al que se desea cambiar.

  ## Ejemplo
      Necesidades.transicion_valida?(:pendiente, :asignada)
      true
  """
  def transicion_valida?(estado_actual, nuevo_estado) do

    transiciones = %{
      pendiente: [:asignada, :cancelada],
      asignada: [:en_atencion, :cancelada],
      en_atencion: [:atendida, :cancelada],
      atendida: [],
      cancelada: []
    }

    Map.get(transiciones, estado_actual, [])
    |> Enum.member?(nuevo_estado)
  end

  @doc """
  Obtiene únicamente las necesidades que están pendientes.

  ## Parametros

  - necesidades: lista de necesidades registradas.

  ## Ejemplo
      Necesidades.listar_pendientes(necesidades)
  """

  def listar_pendientes(necesidades) do

    pendientes = Enum.filter(
      necesidades,
      fn necesidad ->
        necesidad.estado == :pendiente
      end
    )

    {:ok, pendientes}
  end


  @doc """
  Cuenta cuántas necesidades existen en cada estado.

  ## Parametros

  - necesidades: lista de necesidades registradas.

  ## Ejemplo
      Necesidades.contar_estado(necesidades)
  """

  def contar_estado(necesidades) do

    conteo = Enum.frequencies_by(
      necesidades,
      fn necesidad ->
        necesidad.estado
      end
    )

    {:ok, conteo}
  end

end
