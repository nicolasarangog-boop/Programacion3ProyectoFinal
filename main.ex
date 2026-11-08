
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

  # Muestra los comandos disponibles.
  defp mostrar_ayuda do
    IO.puts("\nComandos disponibles:")
    IO.puts("  register_user usuario contraseña nombre tipo zona")
    IO.puts("  connect usuario contraseña tipo zona")
    IO.puts("  disconnect")
    IO.puts("  list_users")
    IO.puts("  help")
    IO.puts("  exit")
    IO.puts("\nTipos de usuario:")
    IO.puts("  ciudadano, voluntario, coordinador, administrador")
    IO.puts("\nUsa comillas dobles para nombres con espacios.")
  end
end

Main.iniciar()
