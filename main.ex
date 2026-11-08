
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
        Process.put(:necesidades, [])
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

        ["register_need", tipo, cantidad, prioridad, zona, descripcion, responsable] ->
          registrar_necesidad(tipo, cantidad, prioridad, zona, descripcion, responsable)
          bucle()

        ["list_needs"] ->
          mostrar_resultado(
            Necesidades.listar_necesidades(Process.get(:necesidades, []))
          )
          bucle()

        ["list_needs" | filtros] ->
          consultar_necesidades(filtros)
          bucle()

        ["sort_needs"] ->
          mostrar_resultado(
            Necesidades.ordenar_prioridad(Process.get(:necesidades, []))
          )
          bucle()

        ["pending_needs"] ->
          mostrar_resultado(
            Necesidades.listar_pendientes(Process.get(:necesidades, []))
          )
          bucle()

        ["update_need_status", identificador, estado] ->
          actualizar_estado_necesidad(identificador, estado)
          bucle()

        ["needs_summary"] ->
          mostrar_resultado(
            Necesidades.contar_estado(Process.get(:necesidades, []))
          )
          bucle()

                  # Comandos de recursos
        ["register_resource", nombre, categoria, cantidad, unidad, ubicacion] ->
          registrar_recurso(nombre, categoria, cantidad, unidad, ubicacion)
          bucle()

        ["list_resources"] ->
          mostrar_resultado(RecursosServer.listar())
          bucle()

        ["assign_resource", id_necesidad, codigo, ubicacion, cantidad] ->
          asignar_recurso_necesidad(id_necesidad, codigo, ubicacion, cantidad)
          bucle()

        ["transfer_resource", codigo, origen, destino, cantidad] ->
          transferir_recurso(codigo, origen, destino, cantidad)
          bucle()

        ["resource_history", codigo, ubicacion] ->
          mostrar_resultado(RecursosServer.historial(codigo, ubicacion))
          bucle()

        ["critical_resources", limite] ->
          consultar_recursos_bajos(limite)
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

    # Registra una nueva necesidad.
  defp registrar_necesidad(tipo, cantidad, prioridad, zona, descripcion, responsable) do
    with {:ok, tipo_atom} <- convertir_tipo_necesidad(tipo),
         {:ok, prioridad_atom} <- convertir_prioridad(prioridad),
         {cantidad_numero, ""} <- Integer.parse(cantidad) do

      datos = %{
        tipo: tipo_atom,
        descripcion: descripcion,
        cantidad: cantidad_numero,
        zona: zona,
        prioridad: prioridad_atom,
        responsable: responsable
      }

      resultado = Necesidades.registrar_necesidad(
        Process.get(:necesidades, []),
        datos
      )

      guardar_necesidades(resultado)

    else
      :error ->
        IO.puts("Tipo o prioridad inválidos.")

      _ ->
        IO.puts("Verifica la cantidad ingresada. Debe ser un número entero.")
    end
  end

  # Convierte el tipo de necesidad en un átomo permitido.
  defp convertir_tipo_necesidad("agua"), do: {:ok, :agua}
  defp convertir_tipo_necesidad("alimentos"), do: {:ok, :alimentos}
  defp convertir_tipo_necesidad("medicamentos"), do: {:ok, :medicamentos}
  defp convertir_tipo_necesidad("primeros_auxilios"), do: {:ok, :primeros_auxilios}
  defp convertir_tipo_necesidad("refugio"), do: {:ok, :refugio}
  defp convertir_tipo_necesidad("transporte"), do: {:ok, :transporte}
  defp convertir_tipo_necesidad("rescate"), do: {:ok, :rescate}
  defp convertir_tipo_necesidad("otra"), do: {:ok, :otra}
  defp convertir_tipo_necesidad(_tipo), do: :error

  # Convierte la prioridad ingresada en un átomo permitido.
  defp convertir_prioridad("critica"), do: {:ok, :critica}
  defp convertir_prioridad("alta"), do: {:ok, :alta}
  defp convertir_prioridad("media"), do: {:ok, :media}
  defp convertir_prioridad("baja"), do: {:ok, :baja}
  defp convertir_prioridad(_prioridad), do: :error

  # Convierte el estado ingresado en un átomo permitido.
  defp convertir_estado_necesidad("pendiente"), do: {:ok, :pendiente}
  defp convertir_estado_necesidad("asignada"), do: {:ok, :asignada}
  defp convertir_estado_necesidad("en_atencion"), do: {:ok, :en_atencion}
  defp convertir_estado_necesidad("atendida"), do: {:ok, :atendida}
  defp convertir_estado_necesidad("cancelada"), do: {:ok, :cancelada}
  defp convertir_estado_necesidad(_estado), do: :error

  # Consulta necesidades utilizando los filtros ingresados.
  defp consultar_necesidades(argumentos) do
    with {:ok, filtros} <- convertir_filtros_necesidad(argumentos) do
      resultado = Necesidades.consultar_necesidades(
        Process.get(:necesidades, []),
        filtros
      )

      mostrar_resultado(resultado)
    else
      {:error, mensaje} ->
        IO.puts("Error: #{mensaje}")
    end
  end

  # Convierte los filtros de texto en un mapa de búsqueda.
  defp convertir_filtros_necesidad(argumentos) do
    Enum.reduce_while(argumentos, {:ok, %{}}, fn argumento, {:ok, filtros} ->
      case String.split(argumento, "=", parts: 2) do
        ["zona", valor] when valor != "" ->
          {:cont, {:ok, Map.put(filtros, :zona, valor)}}

        ["prioridad", valor] ->
          case convertir_prioridad(valor) do
            {:ok, prioridad} ->
              {:cont, {:ok, Map.put(filtros, :prioridad, prioridad)}}

            :error ->
              {:halt, {:error, "Prioridad inválida."}}
          end

        ["estado", valor] ->
          case convertir_estado_necesidad(valor) do
            {:ok, estado} ->
              {:cont, {:ok, Map.put(filtros, :estado, estado)}}

            :error ->
              {:halt, {:error, "Estado inválido."}}
          end

        ["tipo", valor] ->
          case convertir_tipo_necesidad(valor) do
            {:ok, tipo} ->
              {:cont, {:ok, Map.put(filtros, :tipo, tipo)}}

            :error ->
              {:halt, {:error, "Tipo de necesidad inválido."}}
          end

        _ ->
          {:halt, {:error, "Filtro incorrecto. Usa zona=, prioridad=, estado= o tipo=."}}
      end
    end)
  end

  # Actualiza el estado de una necesidad.
  defp actualizar_estado_necesidad(identificador, estado) do
    case convertir_estado_necesidad(estado) do
      {:ok, estado_atom} ->
        resultado = Necesidades.actualizar_estado(
          Process.get(:necesidades, []),
          identificador,
          estado_atom
        )

        guardar_necesidades(resultado)

      :error ->
        IO.puts("Estado inválido.")
        IO.puts("Estados: pendiente, asignada, en_atencion, atendida, cancelada.")
    end
  end

  # Actualiza la lista de necesidades cuando una operación tiene éxito.
  defp guardar_necesidades({:ok, necesidades}) do
    Process.put(:necesidades, necesidades)
    mostrar_resultado({:ok, necesidades})
  end

  defp guardar_necesidades({:error, mensaje}) do
    IO.puts("Error: #{mensaje}")
  end

    # Registra un recurso en el inventario.
  defp registrar_recurso(nombre, categoria, cantidad, unidad, ubicacion) do
    case Integer.parse(cantidad) do
      {cantidad_numero, ""} ->
        datos = %{
          nombre: nombre,
          categoria: categoria,
          cantidad: cantidad_numero,
          unidad: unidad,
          ubicacion: ubicacion
        }

        mostrar_resultado(RecursosServer.registrar(datos))

      _ ->
        IO.puts("La cantidad debe ser un número entero.")
    end
  end

  # Asigna un recurso disponible a una necesidad.
  defp asignar_recurso_necesidad(id_necesidad, codigo, ubicacion, cantidad) do
    with {cantidad_numero, ""} <- Integer.parse(cantidad),
         true <- cantidad_numero > 0,
         necesidades <- Process.get(:necesidades, []),
         {:ok, [necesidad]} <-
           Necesidades.consultar_necesidades(necesidades, %{id: id_necesidad}),
         true <- necesidad.estado not in [:atendida, :cancelada],
         {:ok, _recurso} <- RecursosServer.buscar(codigo, ubicacion),
         {:ok, _inventario_actualizado} <-
           RecursosServer.salida(
             codigo,
             ubicacion,
             cantidad_numero,
             "Asignación a necesidad #{id_necesidad}"
           ),
         {:ok, necesidades_actualizadas} <-
           Necesidades.asignar_recurso(
             necesidades,
             id_necesidad,
             codigo,
             cantidad_numero
           ) do

      Process.put(:necesidades, necesidades_actualizadas)

      IO.puts("Recurso asignado correctamente.")
      IO.puts("Necesidad: #{id_necesidad}")
      IO.puts("Recurso: #{codigo}")
      IO.puts("Cantidad asignada: #{cantidad_numero}")
      IO.puts("Ubicación de origen: #{ubicacion}")

    else
      :error ->
        IO.puts("La cantidad debe ser un número entero.")

      false ->
        IO.puts("La cantidad debe ser mayor que cero o la necesidad no puede recibir recursos.")

      {:ok, []} ->
        IO.puts("La necesidad indicada no existe.")

      {:ok, [_primera, _segunda | _resto]} ->
        IO.puts("Se encontró más de una necesidad con ese identificador.")

      {:error, mensaje} ->
        IO.puts("Error: #{mensaje}")

      _ ->
        IO.puts("No se pudo completar la asignación. Verifica la necesidad y el inventario.")
    end
  end

  # Transfiere recursos entre dos ubicaciones.
  defp transferir_recurso(codigo, origen, destino, cantidad) do
    case Integer.parse(cantidad) do
      {cantidad_numero, ""} ->
        resultado = RecursosServer.transferir(
          codigo,
          origen,
          destino,
          cantidad_numero
        )

        mostrar_resultado(resultado)

      _ ->
        IO.puts("La cantidad debe ser un número entero.")
    end
  end

  # Consulta los recursos con inventario bajo.
  defp consultar_recursos_bajos(limite) do
    case Integer.parse(limite) do
      {limite_numero, ""} ->
        mostrar_resultado(RecursosServer.recursos_bajos(limite_numero))

      _ ->
        IO.puts("El límite debe ser un número entero.")
    end
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

        IO.puts("\nComandos de necesidades:")
    IO.puts("  register_need tipo cantidad prioridad zona descripcion responsable")
    IO.puts("  list_needs")
    IO.puts("  list_needs zona=Centro")
    IO.puts("  list_needs prioridad=critica")
    IO.puts("  list_needs estado=pendiente")
    IO.puts("  list_needs tipo=agua")
    IO.puts("  sort_needs")
    IO.puts("  pending_needs")
    IO.puts("  update_need_status NEC-001 asignada")
    IO.puts("  needs_summary")

    IO.puts("\nTipos de necesidades:")
    IO.puts("  agua, alimentos, medicamentos, primeros_auxilios")
    IO.puts("  refugio, transporte, rescate, otra")

        IO.puts("\nComandos de recursos:")
    IO.puts("  register_resource nombre categoria cantidad unidad ubicacion")
    IO.puts("  list_resources")
    IO.puts("  assign_resource NEC-001 REC-001 Centro 20")
    IO.puts("  transfer_resource REC-001 Centro Norte 30")
    IO.puts("  resource_history REC-001 Centro")
    IO.puts("  critical_resources limite")

    IO.puts("\nPrioridades:")
    IO.puts("  critica, alta, media, baja")

    IO.puts("\nEstados:")
    IO.puts("  pendiente, asignada, en_atencion, atendida, cancelada")

    IO.puts("\nNiveles permitidos:")
    IO.puts("  critico, alto, medio, bajo")

    IO.puts("\nOtros comandos:")
    IO.puts("  help")
    IO.puts("  exit")

    IO.puts("\nUsa comillas dobles para nombres con espacios.")
  end

end

Main.iniciar()
