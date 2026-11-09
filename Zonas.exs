defmodule Zonas do
@moduledoc """
  Modulo encargado de la gestion de zonas afectadas dentro del sistema
  de coordinacion y gestion de emergencias.

  - Autores: Briyith Sanchez Alonso y Nicolas Arango Gutierrez
  - Fecha: Noviembre del 2026
  - Licencia: GNU GPL V3
  """

  @niveles_permitidos [:critico, :alto, :medio, :bajo]


  @doc """
  Función para registrar una nueva zona dentro del sistema

  ## Parametros
  - Zonas: Lista que contiene las zonas registradas.
  - Datos: Mapa que contiene la informacion de la nueva zona:

  ## Ejemplo
  iex> datos = %{nombre: "Centro", nivel: :critico, personas_afectadas: 100}
  iex> Zonas.registrar_zona([], datos)
  {:ok, [nueva_zona]}
  """
  def registrar_zona(zonas, datos) do

    nombre = Map.get(datos, :nombre)
    nivel = Map.get(datos, :nivel)
    personas = Map.get(datos, :personas_afectadas)

    existe = Enum.any?(zonas, fn zona ->
      zona.nombre == nombre
    end)

    cond do
      not is_binary(nombre) or nombre == "" ->
        {:error, "El nombre de la zona no es válido"}

      existe ->
        {:error, "La zona ya existe"}

      nivel not in @niveles_permitidos ->
        {:error, "El nivel de emergencia no es válido"}

      not is_integer(personas) or personas < 0 ->
        {:error, "La cantidad de personas no es válida"}

      true ->
        nueva_zona = %{
          nombre: nombre,
          nivel: nivel,
          personas_afectadas: personas,
          sectores: [],
          albergues: [],
          necesidades: [],
          recursos: [],
          reportes: []
        }

        {:ok, [nueva_zona | zonas]}
    end
  end



  @doc """
  Función para registrar un sector dentro de una zona existente.

  ## Parametros
  - Zonas: Lista de zonas registradas.
  - Nombre_zona: Nombre de la zona donde se agregara el sector.
  - Datos: Mapa con la informacion del sector:

  ## Ejemplo
  iex> datos = %{nombre: "Sector Norte", nivel: :alto, personas_afectadas: 40}
  iex> Zonas.registrar_sector(zonas, "Centro", datos)
  {:ok, zonas_actualizadas}
  """
  def registrar_sector(zonas, nombre_zona, datos) do

    nombre_sector = Map.get(datos, :nombre)
    nivel = Map.get(datos, :nivel)
    personas = Map.get(datos, :personas_afectadas)

    zona_existe = Enum.any?(zonas, fn zona ->
      zona.nombre == nombre_zona
    end)

    cond do
      not zona_existe ->
        {:error, "La zona no existe"}

      not is_binary(nombre_sector) or nombre_sector == "" ->
        {:error, "El nombre del sector no es válido"}

      nivel not in @niveles_permitidos ->
        {:error, "El nivel de emergencia no es válido"}

      not is_integer(personas) or personas < 0 ->
        {:error, "La cantidad de personas no es válida"}

      true ->
        zona = Enum.find(zonas, fn z ->
          z.nombre == nombre_zona
        end)

        sector_existe = Enum.any?(zona.sectores, fn sector ->
          sector.nombre == nombre_sector
        end)

        if sector_existe do
          {:error, "El sector ya existe en esta zona"}
        else

          nuevo_sector = %{
            nombre: nombre_sector,
            nivel: nivel,
            personas_afectadas: personas,
            puntos_atencion: []
          }

          zonas_actualizadas = Enum.map(zonas, fn z ->
            if z.nombre == nombre_zona do
              %{z | sectores: [nuevo_sector | z.sectores]}
            else
              z
            end
          end)

          {:ok, zonas_actualizadas}
        end
    end
  end


 @doc """
  Función para registrar un punto de atención dentro de un sectorperteneciente a una zona existente.

  ## Parametros
  - Zonas: Lista de zonas registradas.
  - Nombre_zona: Nombre de la zona donde se encuentra el sector.
  - Nombre_sector: Nombre del sector donde se agregara el punto.
  - Datos: Mapa con la informacion del punto:

  ## Ejemplo
  iex> datos = %{nombre: "Puesto de salud", personas_afectadas: 15}
  iex> Zonas.registrar_punto_atencion(zonas, "Centro", "Sector Norte", datos)
  {:ok, zonas_actualizadas}
  """
  def registrar_punto_atencion(zonas, nombre_zona, nombre_sector, datos) do

    nombre_punto = Map.get(datos, :nombre)
    personas = Map.get(datos, :personas_afectadas)

    zona = Enum.find(zonas, fn z ->
      z.nombre == nombre_zona
    end)

    cond do
      zona == nil ->
        {:error, "La zona no existe"}

      not is_binary(nombre_punto) or nombre_punto == "" ->
        {:error, "El nombre del punto no es válido"}

      not is_integer(personas) or personas < 0 ->
        {:error, "La cantidad de personas no es válida"}

      true ->
        sector = Enum.find(zona.sectores, fn s ->
          s.nombre == nombre_sector
        end)

        if sector == nil do
          {:error, "El sector no existe"}
        else

          punto_existe = Enum.any?(
            sector.puntos_atencion,
            fn punto -> punto.nombre == nombre_punto end
          )

          if punto_existe do
            {:error, "El punto de atención ya existe"}
          else

            nuevo_punto = %{
              nombre: nombre_punto,
              personas_afectadas: personas
            }

            zonas_actualizadas = Enum.map(zonas, fn z ->
              if z.nombre == nombre_zona do

                sectores_actualizados = Enum.map(
                  z.sectores,
                  fn s ->
                    if s.nombre == nombre_sector do
                      %{s |
                        puntos_atencion: [
                          nuevo_punto | s.puntos_atencion
                        ]
                      }
                    else
                      s
                    end
                  end
                )

                %{z | sectores: sectores_actualizados}
              else
                z
              end
            end)

            {:ok, zonas_actualizadas}
          end
        end
    end
  end

 @doc """
  Función para consultar la informacion de una zona especifica.

  ## Parametros
  - Zonas: Lista de zonas registradas.
  - Nombre: Nombre de la zona que se desea consultar.

  ## Ejemplo
  iex> Zonas.consultar_zona(zonas, "Centro")
  {:ok, zona_encontrada}
  """
  def consultar_zona(zonas, nombre) do

    zona = Enum.find(zonas, fn z ->
      z.nombre == nombre
    end)

    if zona == nil do
      {:error, "La zona no existe"}
    else
      {:ok, zona}
    end
  end

 @doc """
  Funcion para listar todas las zonas registradas en el sistema.

  ## Parametros
  - Zonas: Lista que contiene las zonas registradas.

  ## Ejemplo
  iex> Zonas.listar_zonas(zonas)
  {:ok, lista_de_zonas}
  """
  def listar_zonas(zonas) do
    {:ok, zonas}
  end


  @doc """
  Función para actualizar el nivel de emergencia de una zona.

  ## Parametros
  - Zonas: Lista de zonas registradas.
  - Nombre: Nombre de la zona que se desea modificar.
  - Nuevo_nivel: Nuevo nivel de emergencia que se asignara.

  ## Ejemplo
  iex> Zonas.actualizar_nivel(zonas, "Centro", :alto)
  {:ok, zonas_actualizadas}
  """
  def actualizar_nivel(zonas, nombre, nuevo_nivel) do

    existe = Enum.any?(zonas, fn zona ->
      zona.nombre == nombre
    end)

    cond do
      not existe ->
        {:error, "La zona no existe"}

      nuevo_nivel not in @niveles_permitidos ->
        {:error, "El nivel de emergencia no es válido"}

      true ->
        zonas_actualizadas = Enum.map(zonas, fn zona ->
          if zona.nombre == nombre do
            %{zona | nivel: nuevo_nivel}
          else
            zona
          end
        end)

        {:ok, zonas_actualizadas}
    end
  end


  @doc """
  Función para recorrer recursivamente la jerarquia de zonas, sectores y puntos de atencion.

  ## Parametros
  - Zonas: Lista de zonas que contienen sus sectores y puntos
    de atencion asociados.

  ## Ejemplo
  iex> Zonas.recorrer_jerarquia(zonas)
  ["Centro", "Sector Norte", "Puesto de salud"]
  """
  def recorrer_jerarquia(zonas) do
    recorrer_elementos(zonas, [])
  end

  defp recorrer_elementos([], acumulado) do
    Enum.reverse(acumulado)
  end

  defp recorrer_elementos([elemento | resto], acumulado) do

    nombre = Map.get(elemento, :nombre)

    sectores = Map.get(elemento, :sectores, [])
    puntos = Map.get(elemento, :puntos_atencion, [])

    elementos_hijos = sectores ++ puntos

    recorrer_elementos(
      elementos_hijos ++ resto,
      [nombre | acumulado]
    )
  end

 @doc """
  Función para calcular la cantidad total de personas afectadas dentro de todas las zonas registradas.

  ## Parametros
  - Zonas: Lista de zonas registradas con sus sectores y puntos
    de atencion.

  ## Ejemplo
  iex> Zonas.calcular_personas_afectadas(zonas)
  155
  """
  def calcular_personas_afectadas(zonas) do
    sumar_personas_zonas(zonas)
  end

  defp sumar_personas_zonas([]) do
    0
  end

  defp sumar_personas_zonas([zona | resto]) do
    calcular_personas_nodo(zona) +
      sumar_personas_zonas(resto)
  end

  defp calcular_personas_nodo(nodo) do

    sectores = Map.get(nodo, :sectores, [])
    puntos = Map.get(nodo, :puntos_atencion, [])

    cond do
      puntos != [] ->
        sumar_personas_puntos(puntos)

      sectores != [] ->
        sumar_personas_zonas(sectores)

      true ->
        Map.get(nodo, :personas_afectadas, 0)
    end
  end

  defp sumar_personas_puntos([]) do
    0
  end

  defp sumar_personas_puntos([punto | resto]) do
    Map.get(punto, :personas_afectadas, 0) +
      sumar_personas_puntos(resto)
  end

end
