
# Carga de los módulos funcionales
Code.require_file("Usuarios.exs", __DIR__)
Code.require_file("Zonas.exs", __DIR__)
Code.require_file("Necesidades.exs", __DIR__)
Code.require_file("Recursos.exs", __DIR__)

Code.require_file("Personas.ex", __DIR__)
Code.require_file("Mensajes.ex", __DIR__)
Code.require_file("Mascotas.ex", __DIR__)
Code.require_file("Albergues.ex", __DIR__)

# Carga de los servidores y el supervisor
Code.require_file("Recursos_Server.ex", __DIR__)
Code.require_file("Usuarios_Server.ex", __DIR__)
Code.require_file("Supervisor_Server.ex", __DIR__)

defmodule Main do
  @moduledoc """
  Punto de entrada e interfaz de comandos del sistema
  distribuido de coordinación y gestión de emergencias.
  """

  @doc """
  Inicia el sistema y muestra la interfaz de comandos.
  """
  def iniciar do
    IO.puts("\n==========================================")
    IO.puts(" SISTEMA DE GESTIÓN DE EMERGENCIAS")
    IO.puts("==========================================")

    case SistemaSupervisor.start_link() do
      {:ok, pid} ->
        IO.puts("Sistema iniciado correctamente.")
        Process.put(:zonas, [])
        IO.puts("Supervisor: #{inspect(pid)}")
        mostrar_ayuda()
        bucle()

      {:error, {:already_started, pid}} ->
        IO.puts("El sistema ya se encuentra iniciado.")
        IO.puts("Supervisor: #{inspect(pid)}")
        mostrar_ayuda()
        bucle()

      {:error, razon} ->
        IO.puts("Error al iniciar el sistema: #{inspect(razon)}")
    end
  end

  # Mantiene activa la interfaz y recibe comandos.
  defp bucle do
    entrada = IO.gets("\nEmergencias> ")

    case entrada do
      nil ->
        IO.puts("\nFin de la entrada.")

      entrada ->
        comando = String.trim(entrada)

        if comando == "" do
          bucle()
        else
          procesar_comando(comando)
        end
    end
  end

  # Interpreta y ejecuta los comandos ingresados.
  defp procesar_comando(comando) do
    try do
      argumentos = OptionParser.split(comando)

      case argumentos do
        ["exit"] ->
          IO.puts("Cerrando la interfaz del sistema...")

        ["help"] ->
          mostrar_ayuda()
          bucle()

        ["register_user", usuario, contrasena, nombre, tipo, zona] ->
          registrar_usuario(usuario, contrasena, nombre, tipo, zona)
          bucle()

        ["connect", usuario, contrasena, tipo, zona] ->
          conectar_usuario(usuario, contrasena, tipo, zona)
          bucle()

        ["disconnect"] ->
          desconectar_usuario()
          bucle()

        ["list_users"] ->
          mostrar_resultado(UsuariosServer.listar())
          bucle()


        ["register_zone", nombre, nivel, personas] ->
          registrar_zona(nombre, nivel, personas)
          bucle()

        ["list_zones"] ->
          mostrar_resultado(Zonas.listar_zonas(Process.get(:zonas, [])))
          bucle()

        ["register_sector", nombre_zona, nombre_sector, nivel, personas] ->
          registrar_sector(nombre_zona, nombre_sector, nivel, personas)
          bucle()

        ["register_attention_point", nombre_zona, nombre_sector, nombre_punto, personas] ->
          registrar_punto(nombre_zona, nombre_sector, nombre_punto, personas)
          bucle()

        ["show_zone", nombre] ->
          mostrar_resultado(
            Zonas.consultar_zona(Process.get(:zonas, []), nombre)
          )
          bucle()

        ["update_zone_level", nombre, nivel] ->
          actualizar_nivel_zona(nombre, nivel)
          bucle()

        ["zone_hierarchy"] ->
          IO.inspect(
            Zonas.recorrer_jerarquia(Process.get(:zonas, [])),
            pretty: true
          )
          bucle()

        ["affected_people"] ->
          IO.puts(
            "Personas afectadas: #{Zonas.calcular_personas_afectadas(Process.get(:zonas, []))}"
          )
          bucle()

        _ ->
          IO.puts("Comando incorrecto o todavía no implementado.")
          IO.puts("Escribe help para consultar los comandos.")
          bucle()
      end
    rescue
      error ->
        IO.puts("Error al ejecutar el comando: #{Exception.message(error)}")
        bucle()
    end
  end

  # Registra un usuario nuevo.
  defp registrar_usuario(usuario, contrasena, nombre, tipo, zona) do
    case convertir_tipo(tipo) do
      {:ok, tipo_atom} ->
        datos = %{
          usuario: usuario,
          contrasena: contrasena,
          nombre_completo: nombre,
          tipo: tipo_atom,
          zona_principal: zona
        }

        mostrar_resultado(UsuariosServer.registrar(datos))

      :error ->
        IO.puts("Tipo de usuario inválido.")
        IO.puts("Tipos permitidos: ciudadano, voluntario, coordinador, administrador.")
    end
  end

  # Inicia la sesión de un usuario.
  defp conectar_usuario(usuario, contrasena, tipo, zona) do
    case convertir_tipo(tipo) do
      {:ok, tipo_atom} ->
        resultado = UsuariosServer.conectar(usuario, contrasena, tipo_atom, zona)

        case resultado do
          {:ok, _usuarios} ->
            Process.put(:usuario_actual, usuario)
            IO.puts("Sesión iniciada correctamente.")
            mostrar_resultado(resultado)

          _ ->
            mostrar_resultado(resultado)
        end

      :error ->
        IO.puts("Tipo de usuario inválido.")
        IO.puts("Tipos permitidos: ciudadano, voluntario, coordinador, administrador.")
    end
  end

  # Cierra la sesión del usuario actual.
  defp desconectar_usuario do
    case Process.get(:usuario_actual) do
      nil ->
        IO.puts("No hay ningún usuario conectado en esta sesión.")

      usuario ->
        resultado = UsuariosServer.desconectar(usuario)

        case resultado do
          {:ok, _usuarios} ->
            Process.delete(:usuario_actual)
            IO.puts("Sesión cerrada correctamente.")
            mostrar_resultado(resultado)

          _ ->
            mostrar_resultado(resultado)
        end
    end
  end

  # Convierte el tipo de usuario ingresado en un átomo permitido.
  defp convertir_tipo("ciudadano"), do: {:ok, :ciudadano}
  defp convertir_tipo("voluntario"), do: {:ok, :voluntario}
  defp convertir_tipo("coordinador"), do: {:ok, :coordinador}
  defp convertir_tipo("administrador"), do: {:ok, :administrador}
  defp convertir_tipo(_tipo), do: :error

  # Muestra los resultados de las operaciones.
  defp mostrar_resultado(resultado) do
    IO.inspect(resultado, pretty: true, limit: :infinity)
  end


  # Registra una zona nueva.
  defp registrar_zona(nombre, nivel, personas) do
    with {:ok, nivel_atom} <- convertir_nivel(nivel),
         {cantidad, ""} <- Integer.parse(personas) do

      datos = %{
        nombre: nombre,
        nivel: nivel_atom,
        personas_afectadas: cantidad
      }

      resultado = Zonas.registrar_zona(
        Process.get(:zonas, []),
        datos
      )

      guardar_zonas(resultado)

    else
      :error ->
        IO.puts("Nivel inválido. Usa: critico, alto, medio o bajo.")

      :error_personas ->
        IO.puts("La cantidad de personas debe ser un número entero.")

      _ ->
        IO.puts("La cantidad de personas debe ser un número entero.")
    end
  end

  # Registra un sector dentro de una zona.
  defp registrar_sector(nombre_zona, nombre_sector, nivel, personas) do
    with {:ok, nivel_atom} <- convertir_nivel(nivel),
         {cantidad, ""} <- Integer.parse(personas) do

      datos = %{
        nombre: nombre_sector,
        nivel: nivel_atom,
        personas_afectadas: cantidad
      }

      resultado = Zonas.registrar_sector(
        Process.get(:zonas, []),
        nombre_zona,
        datos
      )

      guardar_zonas(resultado)

    else
      _ ->
        IO.puts("Verifica el nivel y la cantidad de personas.")
    end
  end

  # Registra un punto de atención dentro de un sector.
  defp registrar_punto(nombre_zona, nombre_sector, nombre_punto, personas) do
    case Integer.parse(personas) do
      {cantidad, ""} ->
        datos = %{
          nombre: nombre_punto,
          personas_afectadas: cantidad
        }

        resultado = Zonas.registrar_punto_atencion(
          Process.get(:zonas, []),
          nombre_zona,
          nombre_sector,
          datos
        )

        guardar_zonas(resultado)

      _ ->
        IO.puts("La cantidad de personas debe ser un número entero.")
    end
  end

  # Actualiza el nivel de emergencia de una zona.
  defp actualizar_nivel_zona(nombre, nivel) do
    case convertir_nivel(nivel) do
      {:ok, nivel_atom} ->
        resultado = Zonas.actualizar_nivel(
          Process.get(:zonas, []),
          nombre,
          nivel_atom
        )

        guardar_zonas(resultado)

      :error ->
        IO.puts("Nivel inválido. Usa: critico, alto, medio o bajo.")
    end
  end

  # Convierte el nivel ingresado en un átomo permitido.
  defp convertir_nivel("critico"), do: {:ok, :critico}
  defp convertir_nivel("alto"), do: {:ok, :alto}
  defp convertir_nivel("medio"), do: {:ok, :medio}
  defp convertir_nivel("bajo"), do: {:ok, :bajo}
  defp convertir_nivel(_nivel), do: :error

  # Actualiza el estado de las zonas cuando una operación tiene éxito.
  defp guardar_zonas({:ok, zonas}) do
    Process.put(:zonas, zonas)
    mostrar_resultado({:ok, zonas})
  end

  defp guardar_zonas({:error, mensaje}) do
    IO.puts("Error: #{mensaje}")
  end


  # Muestra los comandos disponibles.
  defp mostrar_ayuda do
    IO.puts("\nComandos de usuarios:")
    IO.puts("  register_user usuario contraseña nombre tipo zona")
    IO.puts("  connect usuario contraseña tipo zona")
    IO.puts("  disconnect")
    IO.puts("  list_users")

    IO.puts("\nComandos de zonas:")
    IO.puts("  register_zone nombre nivel personas")
    IO.puts("  list_zones")
    IO.puts("  register_sector zona sector nivel personas")
    IO.puts("  register_attention_point zona sector punto personas")
    IO.puts("  show_zone nombre")
    IO.puts("  update_zone_level nombre nivel")
    IO.puts("  zone_hierarchy")
    IO.puts("  affected_people")

    IO.puts("\nNiveles permitidos:")
    IO.puts("  critico, alto, medio, bajo")

    IO.puts("\nOtros comandos:")
    IO.puts("  help")
    IO.puts("  exit")

    IO.puts("\nUsa comillas dobles para nombres con espacios.")
  end

end

Main.iniciar()
