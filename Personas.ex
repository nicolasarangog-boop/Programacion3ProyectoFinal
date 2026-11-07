defmodule Personas do
  @moduledoc """
  Gestiona el registro, consulta y actualización de personas afectadas.
  """
  @estados [
    "sin información",
    "reportada",
    "localizada",
    "trasladada",
    "en albergue",
    "reunificada"
  ]

  @doc """
  Registra una persona afectada.

  Parámetros:
  - personas: lista de personas registradas.
  - datos: mapa con la información de la persona.
  """
  def registrar(personas, datos) do
    id = Map.get(datos, :id)
    nombre = Map.get(datos, :nombre)
    documento = Map.get(datos, :documento)
    edad = Map.get(datos, :edad)
    zona = Map.get(datos, :zona)
    estado = Map.get(datos, :estado, "sin información")

    cond do
      Enum.any?(personas, fn p -> p.id == id end) ->
        {:error, "El ID ya existe"}

      not is_binary(id) or String.trim(id) == "" ->
        {:error, "ID inválido"}

      not is_binary(nombre) or String.trim(nombre) == "" ->
        {:error, "Nombre inválido"}

      not is_binary(documento) or String.trim(documento) == "" ->
        {:error, "Documento inválido"}

      not is_integer(edad) or edad < 0 ->
        {:error, "Edad inválida"}

      not is_binary(zona) or String.trim(zona) == "" ->
        {:error, "Zona inválida"}

      estado not in @estados ->
        {:error, "Estado inválido"}

      true ->
        persona = %{
          id: id,
          nombre: nombre,
          documento: documento,
          edad: edad,
          zona: zona,
          estado: estado,
          historial: [{estado, DateTime.utc_now()}]
        }

        {:ok, personas ++ [persona]}
    end
  end

  @doc """
  Consulta todas las personas registradas.

  Parámetros:
  - personas: lista de personas registradas.
  """
  def listar(personas) do
    personas
  end

  @doc """
  Busca una persona mediante su ID.

  Parámetros:
  - personas: lista de personas registradas.
  - id: identificador de la persona.
  """
  def buscar(personas, id) do
    case Enum.find(personas, fn p -> p.id == id end) do
      nil -> {:error, "Persona no encontrada"}
      persona -> {:ok, persona}
    end
  end

  @doc """
  Actualiza el estado de una persona afectada.

  Parámetros:
  - personas: lista de personas registradas.
  - id: identificador de la persona.
  - nuevo_estado: nuevo estado que tendrá la persona.
  """
  def actualizar_estado(personas, id, nuevo_estado) do
    if nuevo_estado not in @estados do
      {:error, "Estado inválido"}
    else
      case Enum.find_index(personas, fn p -> p.id == id end) do
        nil ->
          {:error, "Persona no encontrada"}

        indice ->
          persona = Enum.at(personas, indice)

          if persona.estado == nuevo_estado do
            {:error, "La persona ya tiene ese estado"}
          else
            actualizado = %{
              persona
              | estado: nuevo_estado,
                historial:
                  persona.historial ++
                    [
                      {nuevo_estado, DateTime.utc_now()}
                    ]
            }

            nuevas_personas =
              List.replace_at(personas, indice, actualizado)

            {:ok, nuevas_personas}
          end
      end
    end
  end

  @doc """
  Consulta el historial de estados de una persona.

  Parámetros:
  - personas: lista de personas registradas.
  - id: identificador de la persona.
  """
  def consultar_historial(personas, id) do
    case buscar(personas, id) do
      {:ok, persona} -> {:ok, persona.historial}
      error -> error
    end
  end
end
