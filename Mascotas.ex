defmodule Mascotas do
  @moduledoc """
  Gestiona los reportes de mascotas perdidas y encontradas mediante un algoritmo de coincidencias.

  Autores: Briyith Sanchez Alonso y Nicolás Arango Gutiérrez
  Fecha: Noviembre 2026
  Licencia:GNU GPL V3
  """

  @estados [
    "activa",
    "posible coincidencia",
    "resuelta"
  ]

  @tipos [
    "perdida",
    "encontrada"
  ]

  @doc """
  Registra un nuevo reporte de mascota.

  Parámetros:
  - reportes: lista de reportes registrados.
  - datos: mapa con la información de la mascota.
  """
  def registrar(reportes, datos) do
    id = Map.get(datos, :id)
    tipo = Map.get(datos, :tipo)
    especie = Map.get(datos, :especie)
    nombre = Map.get(datos, :nombre, "")
    caracteristicas = Map.get(datos, :caracteristicas)
    color = Map.get(datos, :color)
    tamanio = Map.get(datos, :tamanio)
    zona = Map.get(datos, :zona)
    contacto = Map.get(datos, :contacto)
    estado = "activa"

    cond do
      not is_binary(id) or String.trim(id) == "" ->
        {:error, "ID inválido"}

      Enum.any?(reportes, fn r -> r.id == id end) ->
        {:error, "El ID del reporte ya existe"}

      tipo not in @tipos ->
        {:error, "Tipo de reporte inválido"}

      not campo_valido?(especie) ->
        {:error, "Especie inválida"}

      not is_binary(nombre) ->
        {:error, "Nombre inválido"}

      not campo_valido?(caracteristicas) ->
        {:error, "Características inválidas"}

      not campo_valido?(color) ->
        {:error, "Color inválido"}

      not campo_valido?(tamanio) ->
        {:error, "Tamaño inválido"}

      not campo_valido?(zona) ->
        {:error, "Zona inválida"}

      not campo_valido?(contacto) ->
        {:error, "Contacto inválido"}

      estado not in @estados ->
        {:error, "Estado inválido"}

      true ->
        reporte = %{
          id: id,
          tipo: tipo,
          especie: String.trim(especie),
          nombre: String.trim(nombre),
          caracteristicas: String.trim(caracteristicas),
          color: String.trim(color),
          tamanio: String.trim(tamanio),
          zona: String.trim(zona),
          contacto: String.trim(contacto),
          estado: "activa",
          coincidencia: nil,
          fecha: DateTime.utc_now()
        }

        {:ok, reportes ++ [reporte]}
    end
  end

  @doc """
  Consulta todos los reportes registrados.

  Parámetros:
  - reportes: lista de reportes registrados.
  """
  def listar(reportes) do
    reportes
  end

  @doc """
  Busca un reporte mediante su identificador.

  Parámetros:
  - reportes: lista de reportes registrados.
  - id: identificador del reporte.
  """
  def buscar(reportes, id) do
    case Enum.find(reportes, fn r -> r.id == id end) do
      nil -> {:error, "Reporte no encontrado"}
      reporte -> {:ok, reporte}
    end
  end

  @doc """
  Identifica posibles coincidencias para un reporte de mascota.

  Parámetros:
  - reportes: lista de reportes registrados.
  - id: identificador del reporte que se desea comparar.
  """
  def buscar_coincidencias(reportes, id) do
    case buscar(reportes, id) do
      {:error, razon} ->
        {:error, razon}

      {:ok, reporte} ->
        if reporte.estado == "resuelta" do
          {:error, "El reporte ya fue resuelto"}
        else
          coincidencias =
            reportes
            |> Enum.filter(fn candidato ->
              candidato.id != reporte.id and
                candidato.tipo != reporte.tipo and
                candidato.estado != "resuelta"
            end)
            |> Enum.map(fn candidato ->
              %{
                reporte: candidato,
                puntaje: calcular_similitud(reporte, candidato)
              }
            end)
            |> Enum.filter(fn resultado ->
              resultado.puntaje >= 50
            end)
            |> Enum.sort_by(
              fn resultado ->
                resultado.puntaje
              end,
              :desc
            )

          if coincidencias == [] do
            {:ok, reportes, []}
          else
            ids_coincidentes =
              Enum.map(coincidencias, fn resultado ->
                resultado.reporte.id
              end)

            nuevos_reportes =
              Enum.map(reportes, fn actual ->
                if actual.id == id or actual.id in ids_coincidentes do
                  %{actual | estado: "posible coincidencia"}
                else
                  actual
                end
              end)

            {:ok, nuevos_reportes, coincidencias}
          end
        end
    end
  end

  @doc """
  Confirma una coincidencia y resuelve los dos reportes relacionados.

  Parámetros:
  - reportes: lista de reportes registrados.
  - id1: identificador del primer reporte.
  - id2: identificador del segundo reporte.
  """
  def confirmar_coincidencia(reportes, id1, id2) do
    with {:ok, reporte1} <- buscar(reportes, id1),
         {:ok, reporte2} <- buscar(reportes, id2) do
      cond do
        id1 == id2 ->
          {:error, "No se puede relacionar un reporte consigo mismo"}

        reporte1.tipo == reporte2.tipo ->
          {:error, "Los reportes deben ser de tipos diferentes"}

        reporte1.estado == "resuelta" or reporte2.estado == "resuelta" ->
          {:error, "Uno de los reportes ya fue resuelto"}

        calcular_similitud(reporte1, reporte2) < 50 ->
          {:error, "Los reportes no tienen suficiente similitud"}

        true ->
          nuevos_reportes =
            Enum.map(reportes, fn reporte ->
              cond do
                reporte.id == id1 ->
                  %{reporte | estado: "resuelta", coincidencia: id2}

                reporte.id == id2 ->
                  %{reporte | estado: "resuelta", coincidencia: id1}

                true ->
                  reporte
              end
            end)

          {:ok, nuevos_reportes}
      end
    end
  end

  # Comprueba que un campo de texto no esté vacío.
  defp campo_valido?(valor) do
    is_binary(valor) and String.trim(valor) != ""
  end

  # Calcula el porcentaje de similitud entre dos reportes.
  defp calcular_similitud(reporte1, reporte2) do
    atributos = [
      {reporte1.especie, reporte2.especie, 30, :exacto},
      {reporte1.color, reporte2.color, 20, :exacto},
      {reporte1.tamanio, reporte2.tamanio, 15, :exacto},
      {reporte1.nombre, reporte2.nombre, 15, :aproximado},
      {reporte1.caracteristicas, reporte2.caracteristicas, 20, :aproximado}
    ]

    disponibles =
      Enum.filter(atributos, fn {valor1, valor2, _peso, _tipo} ->
        campo_valido?(valor1) and campo_valido?(valor2)
      end)

    peso_total =
      Enum.reduce(disponibles, 0, fn {_v1, _v2, peso, _tipo}, total ->
        total + peso
      end)

    puntos =
      Enum.reduce(disponibles, 0, fn {valor1, valor2, peso, tipo}, total ->
        if atributos_coinciden?(valor1, valor2, tipo) do
          total + peso
        else
          total
        end
      end)

    if peso_total == 0 do
      0.0
    else
      puntos / peso_total * 100
    end
  end

  # Compara dos atributos mediante igualdad exacta o similitud aproximada.
  defp atributos_coinciden?(valor1, valor2, :exacto) do
    normalizar(valor1) == normalizar(valor2)
  end

  defp atributos_coinciden?(valor1, valor2, :aproximado) do
    String.jaro_distance(normalizar(valor1), normalizar(valor2)) >= 0.80
  end

  # Normaliza un texto para facilitar su comparación.
  defp normalizar(texto) do
    texto
    |> String.trim()
    |> String.downcase()
  end
end
