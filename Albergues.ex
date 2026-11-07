defmodule Albergues do
  @moduledoc """
  Gestiona los albergues, sus ocupantes, capacidad y asociaciones
  con recursos y necesidades.

  Autores: Briyith Sanchez Alonso y Nicolás Arango Gutiérrez
  Fecha: Noviembre 2026
  Licencia:GNU GPL V3
  """

  @doc """
  Registra un albergue nuevo.

  Parámetros:
  - albergues: lista actual de albergues.
  - datos: mapa con codigo, nombre, zona y capacidad.
  """
  def registrar(albergues, datos) when is_list(albergues) and is_map(datos) do
    codigo = Map.get(datos, :codigo)
    nombre = Map.get(datos, :nombre)
    zona = Map.get(datos, :zona)
    capacidad = Map.get(datos, :capacidad)

    cond do
      not texto_valido?(codigo) ->
        {:error, "Código inválido"}

      not texto_valido?(nombre) ->
        {:error, "Nombre inválido"}

      not texto_valido?(zona) ->
        {:error, "Zona inválida"}

      not is_integer(capacidad) or capacidad < 0 ->
        {:error, "Capacidad inválida"}

      Enum.any?(albergues, fn albergue -> albergue.codigo == codigo end) ->
        {:error, "Ya existe un albergue con ese código"}

      true ->
        albergue = %{
          codigo: codigo,
          nombre: nombre,
          zona: zona,
          capacidad: capacidad,
          ocupacion: 0,
          personas: [],
          recursos: [],
          necesidades: []
        }

        {:ok, albergues ++ [albergue]}
    end
  end

  def registrar(_albergues, _datos), do: {:error, "Datos inválidos"}

  @doc """
  Devuelve la lista de albergues registrados.

  Parámetros:
  - albergues: lista de albergues.
  """
  def listar(albergues) when is_list(albergues) do
    {:ok, albergues}
  end

  def listar(_albergues), do: {:error, "Lista de albergues inválida"}

  @doc """
  Busca un albergue por su código.

  Parámetros:
  - albergues: lista de albergues.
  - codigo: código del albergue que se desea consultar.
  """
  def buscar(albergues, codigo) when is_list(albergues) do
    case Enum.find(albergues, fn albergue -> albergue.codigo == codigo end) do
      nil -> {:error, "Albergue no encontrado"}
      albergue -> {:ok, albergue}
    end
  end

  def buscar(_albergues, _codigo), do: {:error, "Datos inválidos"}

  @doc """
  Registra el ingreso de una persona a un albergue.

  Parámetros:
  - albergues: lista actual de albergues.
  - codigo: código del albergue.
  - id_persona: identificador de la persona que ingresa.
  """
  def ingresar_persona(albergues, codigo, id_persona)
      when is_list(albergues) and is_binary(id_persona) do
    case buscar(albergues, codigo) do
      {:error, razon} ->
        {:error, razon}

      {:ok, albergue} ->
        cond do
          String.trim(id_persona) == "" ->
            {:error, "Identificador de persona inválido"}

          id_persona in albergue.personas ->
            {:error, "La persona ya se encuentra en este albergue"}

          albergue.ocupacion >= albergue.capacidad ->
            {:error, "El albergue no tiene cupos disponibles"}

          Enum.any?(albergues, fn otro_albergue ->
            otro_albergue.codigo != codigo and id_persona in otro_albergue.personas end) ->
            {:error, "La persona ya se encuentra en otro albergue"}

          true ->
            nuevo_albergue = %{
              albergue
              | personas: albergue.personas ++ [id_persona],
                ocupacion: albergue.ocupacion + 1
            }

            {:ok, actualizar_albergue(albergues, nuevo_albergue)}
        end
    end
  end

  def ingresar_persona(_albergues, _codigo, _id_persona),
    do: {:error, "Datos inválidos"}

  @doc """
  Registra la salida de una persona de un albergue.

  Parámetros:
  - albergues: lista actual de albergues.
  - codigo: código del albergue.
  - id_persona: identificador de la persona que sale.
  """
  def retirar_persona(albergues, codigo, id_persona)
      when is_list(albergues) and is_binary(id_persona) do
    case buscar(albergues, codigo) do
      {:error, razon} ->
        {:error, razon}

      {:ok, albergue} ->
        cond do
          String.trim(id_persona) == "" ->
            {:error, "Identificador de persona inválido"}

          id_persona in albergue.personas ->
            nuevas_personas = List.delete(albergue.personas, id_persona)

            nuevo_albergue = %{
              albergue
              | personas: nuevas_personas,
                ocupacion: length(nuevas_personas)
            }

            {:ok, actualizar_albergue(albergues, nuevo_albergue)}

          true ->
            {:error, "La persona no se encuentra en este albergue"}
        end
    end
  end

  def retirar_persona(_albergues, _codigo, _id_persona),
    do: {:error, "Datos inválidos"}

  @doc """
  Consulta la cantidad de cupos disponibles en un albergue.

  Parámetros:
  - albergues: lista de albergues.
  - codigo: código del albergue.
  """
  def cupos_disponibles(albergues, codigo) do
    case buscar(albergues, codigo) do
      {:ok, albergue} ->
        {:ok, albergue.capacidad - albergue.ocupacion}

      {:error, razon} ->
        {:error, razon}
    end
  end

  @doc """
  Consulta la ocupación y capacidad de un albergue.

  Parámetros:
  - albergues: lista de albergues.
  - codigo: código del albergue.
  """
  def ocupacion(albergues, codigo) do
    case buscar(albergues, codigo) do
      {:ok, albergue} ->
        porcentaje =
          if albergue.capacidad == 0 do
            0.0
          else
            albergue.ocupacion / albergue.capacidad * 100
          end

        {:ok,
         %{
           ocupadas: albergue.ocupacion,
           capacidad: albergue.capacidad,
           disponibles: albergue.capacidad - albergue.ocupacion,
           porcentaje: Float.round(porcentaje, 2)
         }}

      {:error, razon} ->
        {:error, razon}
    end
  end

  @doc """
  Identifica el albergue o los albergues con mayor ocupación porcentual.

  Parámetros:
  - albergues: lista de albergues registrados.
  """
  def mayor_ocupacion(albergues) when is_list(albergues) do
    case albergues do
      [] ->
        {:error, "No hay albergues registrados"}

      _ ->
        porcentajes =
          Enum.map(albergues, fn albergue ->
            if albergue.capacidad == 0 do
              0.0
            else
              albergue.ocupacion / albergue.capacidad * 100
            end
          end)

        mayor = Enum.max(porcentajes)

        resultado =
          Enum.filter(albergues, fn albergue ->
            porcentaje =
              if albergue.capacidad == 0 do
                0.0
              else
                albergue.ocupacion / albergue.capacidad * 100
              end

            porcentaje == mayor
          end)

        {:ok, resultado}
    end
  end

  def mayor_ocupacion(_albergues), do: {:error, "Lista inválida"}

  @doc """
  Asocia un recurso con un albergue.

  Parámetros:
  - albergues: lista actual de albergues.
  - codigo: código del albergue.
  - id_recurso: identificador del recurso que se asociará.
  """
  def asociar_recurso(albergues, codigo, id_recurso) do
    asociar_elemento(albergues, codigo, id_recurso, :recursos)
  end

  @doc """
  Asocia una necesidad con un albergue.

  Parámetros:
  - albergues: lista actual de albergues.
  - codigo: código del albergue.
  - id_necesidad: identificador de la necesidad que se asociará.
  """
  def asociar_necesidad(albergues, codigo, id_necesidad) do
    asociar_elemento(albergues, codigo, id_necesidad, :necesidades)
  end

  # Comprueba que un texto sea válido.
  defp texto_valido?(texto) when is_binary(texto) do
    String.trim(texto) != ""
  end

  defp texto_valido?(_texto), do: false

  # Reemplaza un albergue dentro de la lista.
  defp actualizar_albergue(albergues, nuevo_albergue) do
    Enum.map(albergues, fn albergue ->
      if albergue.codigo == nuevo_albergue.codigo do
        nuevo_albergue
      else
        albergue
      end
    end)
  end

  # Asocia un recurso o una necesidad con un albergue.
  defp asociar_elemento(albergues, codigo, identificador, campo)
       when is_list(albergues) and is_binary(identificador) do
    case buscar(albergues, codigo) do
      {:error, razon} ->
        {:error, razon}

      {:ok, albergue} ->
        if String.trim(identificador) == "" do
          {:error, "Identificador inválido"}
        else
          elementos = Map.get(albergue, campo)

          if identificador in elementos do
            {:error, "El elemento ya está asociado al albergue"}
          else
            nuevo_albergue =
              Map.put(albergue, campo, elementos ++ [identificador])

            {:ok, actualizar_albergue(albergues, nuevo_albergue)}
          end
        end
    end
  end

  defp asociar_elemento(_albergues, _codigo, _identificador, _campo),
    do: {:error, "Datos inválidos"}
end
