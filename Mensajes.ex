
defmodule Mensajes do
  @moduledoc """
  Gestiona el registro, consulta y actualización de mensajes entre personas afectadas y sus familiares.
  """

  @estados [
    "pendiente",
    "enviado",
    "entregado",
    "leido"
  ]

  @doc """
  Registra un mensaje y verifica que sus participantes existan.

  Parámetros:
  - mensajes: lista de mensajes registrados.
  - personas: lista de personas registradas.
  - datos: mapa con la información del mensaje.
  """
  def registrar(mensajes, personas, datos) do
    id = Map.get(datos, :id)
    remitente = Map.get(datos, :remitente)
    destinatario = Map.get(datos, :destinatario)
    contenido = Map.get(datos, :contenido)
    estado = Map.get(datos, :estado, "pendiente")

    cond do
      not is_binary(id) or String.trim(id) == "" ->
        {:error, "ID inválido"}

      Enum.any?(mensajes, fn m -> m.id == id end) ->
        {:error, "El ID del mensaje ya existe"}

      not persona_existe?(personas, remitente) ->
        {:error, "El remitente no está registrado"}

      not persona_existe?(personas, destinatario) ->
        {:error, "El destinatario no está registrado"}

      not is_binary(contenido) or String.trim(contenido) == "" ->
        {:error, "El contenido del mensaje no puede estar vacío"}

      estado not in @estados ->
        {:error, "Estado del mensaje inválido"}

      true ->
        mensaje = %{
          id: id,
          remitente: remitente,
          destinatario: destinatario,
          contenido: contenido,
          fecha: DateTime.utc_now(),
          estado: estado
        }

        {:ok, mensajes ++ [mensaje]}
    end
  end

  @doc """
  Consulta todos los mensajes registrados.

  Parámetros:
  - mensajes: lista de mensajes registrados.
  """
  def listar(mensajes) do
    mensajes
  end

  @doc """
  Busca un mensaje mediante su identificador.

  Parámetros:
  - mensajes: lista de mensajes registrados.
  - id: identificador del mensaje.
  """
  def buscar(mensajes, id) do
    case Enum.find(mensajes, fn m -> m.id == id end) do
      nil -> {:error, "Mensaje no encontrado"}
      mensaje -> {:ok, mensaje}
    end
  end

  @doc """
  Consulta los mensajes relacionados con una persona.

  Parámetros:
  - mensajes: lista de mensajes registrados.
  - persona_id: identificador de la persona.
  """
  def mensajes_por_persona(mensajes, persona_id) do
    Enum.filter(mensajes, fn mensaje ->
      mensaje.remitente == persona_id or
        mensaje.destinatario == persona_id
    end)
  end

  @doc """
  Actualiza el estado de un mensaje.

  Parámetros:
  - mensajes: lista de mensajes registrados.
  - id: identificador del mensaje.
  - nuevo_estado: nuevo estado del mensaje.
  """
  def actualizar_estado(mensajes, id, nuevo_estado) do
    if nuevo_estado not in @estados do
      {:error, "Estado del mensaje inválido"}
    else
      case Enum.find_index(mensajes, fn m -> m.id == id end) do
        nil ->
          {:error, "Mensaje no encontrado"}

        indice ->
          mensaje = Enum.at(mensajes, indice)

          if mensaje.estado == nuevo_estado do
            {:error, "El mensaje ya tiene ese estado"}
          else
            actualizado = %{mensaje | estado: nuevo_estado}

            nuevos_mensajes =
              List.replace_at(mensajes, indice, actualizado)

            {:ok, nuevos_mensajes}
          end
      end
    end
  end

  # Comprueba si existe una persona con el identificador indicado.
  defp persona_existe?(personas, id) when is_binary(id) do
    case Personas.buscar(personas, id) do
      {:ok, _persona} -> true
      {:error, _razon} -> false
    end
  end

  defp persona_existe?(_personas, _id), do: false
end
