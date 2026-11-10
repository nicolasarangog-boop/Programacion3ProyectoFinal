defmodule Persistencia do
  @moduledoc """
  Gestiona la persistencia de información del sistema de emergencias
  mediante archivos de texto plano.

  - Autores: Briyith Sanchez Alonso y Nicolás Arango Gutiérrez
  - Fecha: Noviembre de 2026
  - Licencia: GNU GPL V3
  """

  @directorio Path.join(__DIR__, "../datos")

  @archivos %{
    usuarios: "usuarios.txt",
    zonas: "zonas.txt",
    necesidades: "necesidades.txt",
    recursos: "recursos.txt",
    personas: "personas.txt",
    mensajes: "mensajes.txt",
    mascotas: "mascotas.txt",
    albergues: "albergues.txt"
  }

  @doc """
  Guarda la información de un módulo en un archivo de texto plano.

  ## Parámetros
  - modulo: átomo que identifica el módulo.
  - datos: información que se desea almacenar.

  ## Ejemplo
      Persistencia.guardar(:zonas, zonas)
  """
  def guardar(modulo, datos) when is_atom(modulo) do
    case Map.fetch(@archivos, modulo) do
      {:ok, archivo} ->
        ruta = Path.join(@directorio, archivo)

        # Convierte los datos a una representación de texto.
        contenido = :io_lib.format("~tp.~n", [datos])
        texto = IO.iodata_to_binary(contenido)

        case File.mkdir_p(@directorio) do
          :ok ->
            case File.write(ruta, texto) do
              :ok ->
                {:ok, "Información guardada correctamente"}

              {:error, motivo} ->
                {:error, "No se pudo guardar la información: #{inspect(motivo)}"}
            end

          {:error, motivo} ->
            {:error, "No se pudo crear el directorio: #{inspect(motivo)}"}
        end

      :error ->
        {:error, "El módulo no está registrado en persistencia"}
    end
  end

  def guardar(_modulo, _datos) do
    {:error, "Parámetros inválidos"}
  end

    @doc """
  Recupera la información almacenada de un módulo.

  ## Parámetros
  - modulo: átomo que identifica el módulo.

  ## Ejemplo
      Persistencia.cargar(:usuarios)
  """
  def cargar(modulo) when is_atom(modulo) do
  case Map.fetch(@archivos, modulo) do
    {:ok, archivo} ->
      ruta = Path.join(@directorio, archivo)

      case File.read(ruta) do
        {:ok, contenido} ->
          interpretar_contenido(contenido)

        {:error, :enoent} ->
          {:ok, []}

        {:error, motivo} ->
          {:error, "No se pudo leer el archivo: #{inspect(motivo)}"}
      end

    :error ->
      {:error, "El módulo no está registrado en persistencia"}
  end
end

def cargar(_modulo), do: {:error, "Parámetro inválido"}

  @doc """
  Guarda la información de varios módulos.

  ## Parámetros
  - datos: mapa con los módulos y sus respectivas informaciones.

  ## Ejemplo
      Persistencia.guardar_todo(%{
        zonas: zonas,
        necesidades: necesidades
      })
  """
  def guardar_todo(datos) when is_map(datos) do
    Enum.reduce_while(datos, {:ok, []}, fn {modulo, informacion}, {:ok, guardados} ->
      case guardar(modulo, informacion) do
        {:ok, _mensaje} ->
          {:cont, {:ok, [modulo | guardados]}}

        {:error, motivo} ->
          {:halt, {:error, motivo}}
      end
    end)
  end

  def guardar_todo(_datos) do
    {:error, "Se esperaba un mapa con la información"}
  end

  @doc """
  Recupera la información almacenada de todos los módulos.

  ## Ejemplo
      Persistencia.cargar_todo()
  """
  def cargar_todo do
    Enum.reduce(@archivos, %{}, fn {modulo, _archivo}, acumulado ->
      case cargar(modulo) do
        {:ok, datos} ->
          Map.put(acumulado, modulo, datos)

        {:error, motivo} ->
          Map.put(acumulado, modulo, {:error, motivo})
      end
    end)
  end

  @doc """
  Recupera la información de un módulo.
  Si el archivo todavía no existe, devuelve una lista vacía.

  ## Parámetros
  - modulo: átomo que identifica el módulo.

  ## Ejemplo
      Persistencia.cargar_o_vacio(:usuarios)
  """
  def cargar_o_vacio(modulo) do
    case cargar(modulo) do
      {:ok, datos} ->
        datos

      {:error, motivo} ->
        raise "Error al recuperar #{modulo}: #{motivo}"
    end
  end

  # Convierte archivos con codificación Latin-1 a UTF-8 cuando sea necesario.
  defp normalizar_codificacion(contenido) do
    if String.valid?(contenido) do
      contenido
    else
      :unicode.characters_to_binary(contenido, :latin1, :utf8)
    end
  end

  # Interpreta información almacenada en texto plano.
defp interpretar_contenido(contenido) do
  texto = normalizar_codificacion(contenido)

  if String.trim(texto) == "" do
    {:ok, []}
  else
    case :erl_scan.string(String.to_charlist(texto)) do
      {:ok, tokens, _linea} ->
        case :erl_parse.parse_term(tokens) do
          {:ok, datos} when is_list(datos) ->
            {:ok, datos}

          {:ok, _datos} ->
            {:error, "El archivo no contiene una lista"}

          {:error, motivo} ->
            {:error, "Formato de archivo inválido: #{inspect(motivo)}"}
        end

      {:error, motivo, _linea} ->
        {:error, "No se pudo interpretar el archivo: #{inspect(motivo)}"}
    end
  end
end
end
