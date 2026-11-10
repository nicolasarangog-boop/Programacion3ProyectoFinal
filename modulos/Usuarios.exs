defmodule Usuarios do
  @moduledoc """
  Modulo encargado de la gestion de usuarios dentro del sistema
  de coordinacion y gestion de emergencias.

  - Autores: Briyith Sanchez Alonso y Nicolas Arango Gutierrez
  - Fecha: Noviembre del 2026
  - Licencia: GNU GPL V3
  """
  # Tipos de usuarios permitidos en el sistema
  @tipos_permitidos [
    :ciudadano,
    :voluntario,
    :coordinador,
    :administrador
  ]

  @doc """
  Función para registrar un nuevo usuario en el sistema

  ## Parametros
  - Usuarios: Lista que contiene los usuarios registrados.
  - Datos: Mapa que contiene la informacion del usuario:
    - usuario: Nombre de usuario.
    - contrasena: Contrasena de acceso.
    - nombre_completo: Nombre completo del usuario.
    - tipo: Rol del usuario dentro del sistema.
    - zona_principal: Zona a la que pertenece el usuario.

  ## Ejemplo
  iex> datos = %{usuario: "liliana", contrasena: "1234", nombre_completo: "liliana Sanchez", tipo: :coordinador, zona_principal: "Centro"}
  iex> Usuarios.registrar([], datos)
  {:ok, [nuevo_usuario]}
  """
  def registrar(usuarios, datos) do
    usuario = Map.get(datos, :usuario)
    contrasena = Map.get(datos, :contrasena)
    nombre_completo = Map.get(datos, :nombre_completo)
    tipo = Map.get(datos, :tipo)
    zona_principal = Map.get(datos, :zona_principal)

    existe =
      Enum.any?(usuarios, fn u ->
        Map.get(u, :usuario) == usuario
      end)

    cond do
      existe ->
        {:error, "El usuario ya existe"}

      not is_binary(usuario) or usuario == "" ->
        {:error, "El nombre de usuario no es válido"}

      not is_binary(contrasena) or contrasena == "" ->
        {:error, "La contraseña no es válida"}

      not is_binary(nombre_completo) or nombre_completo == "" ->
        {:error, "El nombre completo no es válido"}

      tipo not in @tipos_permitidos ->
        {:error, "El tipo de usuario no es válido"}

      not is_binary(zona_principal) or zona_principal == "" ->
        {:error, "La zona principal no es válida"}

      true ->
        nuevo_usuario = %{
          usuario: usuario,
          contrasena: :crypto.hash(:sha256, contrasena) |> Base.encode16(),
          nombre_completo: nombre_completo,
          tipo: tipo,
          zona_principal: zona_principal,
          conectado: false,
          actividades: []
        }

        {:ok, [nuevo_usuario | usuarios]}
    end
  end

  @doc """
  Funcion para autenticar un usuario mediante su nombre de usuario
  y contraseña.

  ## Parametros
  - Usuarios: Lista de usuarios registrados.
  - Usuario: Nombre de usuario que desea autenticarse.
  - Contraseña: Contrasena ingresada para validar el acceso.

  ## Ejemplo
  iex> Usuarios.autenticar(usuarios, "liliana", "1234")
  {:ok, usuario_sin_contrasena}
  """
  def autenticar(usuarios, usuario, contrasena) do
    usuario_encontrado =
      Enum.find(usuarios, fn u ->
        Map.get(u, :usuario) == usuario
      end)

    cond do
      usuario_encontrado == nil ->
        {:error, "El usuario no existe"}

      not is_binary(contrasena) ->
        {:error, "La contraseña no es válida"}

      true ->
        contrasena_hash =
          :crypto.hash(:sha256, contrasena)
          |> Base.encode16()

        if usuario_encontrado.contrasena == contrasena_hash do
          {:ok, Map.drop(usuario_encontrado, [:contrasena])}
        else
          {:error, "Contraseña incorrecta"}
        end
    end
  end

  @doc """
  Función para conectar un usuario al sistema

  ## Parametros
  - Usuarios: Lista de usuarios registrados.
  - Usuario: Nombre de usuario.
  - Contrasena: Contrasena de acceso.
  - Tipo: Rol del usuario.
  - Zona_principal: Zona principal del usuario.

  ## Ejemplo
  iex> Usuarios.conectar([], "liliana", "1234", :coordinador, "Centro")
  {:ok, usuarios_actualizados}
  """
  def conectar(usuarios, usuario, contrasena, tipo, zona_principal) do
    conectar(usuarios, usuario, contrasena, usuario, tipo, zona_principal)
  end

  @doc """
  Función para conectar un usuario al sistema

  ## Parametros
  - Usuarios: Lista de usuarios registrados.
  - Usuario: Nombre de usuario.
  - Contrasena: Contrasena de acceso.
  - Nombre_completo: Nombre completo del usuario.
  - Tipo: Rol del usuario.
  - Zona_principal: Zona principal del usuario.

  ## Ejemplo
  iex> Usuarios.conectar([], "liliana", "1234", "liliana Sanchez", :coordinador, "Centro")
  {:ok, usuarios_actualizados}
  """
  def conectar(usuarios, usuario, contrasena, _nombre_completo, _tipo, _zona_principal) do
    usuario_encontrado =
      Enum.find(usuarios, fn u ->
        Map.get(u, :usuario) == usuario
      end)

    if usuario_encontrado == nil do
      {:error, "El usuario no existe. Regístrese primero."}
    else
      case autenticar(usuarios, usuario, contrasena) do
        {:ok, _usuario} ->
          usuarios_actualizados =
            Enum.map(usuarios, fn u ->
              if Map.get(u, :usuario) == usuario do
                %{u | conectado: true, actividades: ["Inicio de sesión" | u.actividades]}
              else
                u
              end
            end)

          {:ok, usuarios_actualizados}

        {:error, motivo} ->
          {:error, motivo}
      end
    end
  end

  @doc """
  Función para desconectar un usuario del sistema.

  ## Parametros
  - Usuarios: Lista de usuarios registrados.
  - Usuario: Nombre de usuario que desea desconectarse.

  ## Ejemplo
  iex> Usuarios.desconectar(usuarios, "liliana")
  {:ok, usuarios_actualizados}
  """
  def desconectar(usuarios, usuario) do
    existe =
      Enum.any?(usuarios, fn u ->
        Map.get(u, :usuario) == usuario
      end)

    if existe do
      usuarios_actualizados =
        Enum.map(usuarios, fn u ->
          if Map.get(u, :usuario) == usuario do
            %{u | conectado: false, actividades: ["Cierre de sesión" | u.actividades]}
          else
            u
          end
        end)

      {:ok, usuarios_actualizados}
    else
      {:error, "El usuario no existe"}
    end
  end

  @doc """
  Función para consultar todos los usuarios registrados en el sistema.

  ## Parametros
  - Usuarios: Lista de usuarios registrados.

  ## Ejemplo
  iex> Usuarios.listar(usuarios)
  {:ok, lista_de_usuarios_sin_contrasenas}
  """
  def listar(usuarios) do
    usuarios_sin_contrasenas =
      Enum.map(usuarios, fn u ->
        Map.drop(u, [:contrasena])
      end)

    {:ok, usuarios_sin_contrasenas}
  end

  @doc """
  Función para registrar una actividad en el historial de un usuario.

  ## Parametros
  - Usuarios: Lista de usuarios registrados.
  - Usuario: Nombre de usuario al que pertenece la actividad.
  - Actividad: Descripcion de la actividad realizada.

  ## Ejemplo
  iex> Usuarios.registrar_actividad(usuarios, "liliana", "Registro de una necesidad")
  {:ok, usuarios_actualizados}
  """
  def registrar_actividad(usuarios, usuario, actividad) do
    usuario_encontrado =
      Enum.any?(usuarios, fn u ->
        Map.get(u, :usuario) == usuario
      end)

    cond do
      not usuario_encontrado ->
        {:error, "El usuario no existe"}

      not is_binary(actividad) or actividad == "" ->
        {:error, "La actividad no es válida"}

      true ->
        usuarios_actualizados =
          Enum.map(usuarios, fn u ->
            if Map.get(u, :usuario) == usuario do
              %{u | actividades: [actividad | u.actividades]}
            else
              u
            end
          end)

        {:ok, usuarios_actualizados}
    end
  end

  @doc """
  Función para verificar si un usuario tiene permiso para realizar una operación dentro del sistema.

  ## Parametros
  - Usuario: Mapa con la informacion del usuario autenticado.
  - Tipos_permitidos: Lista de roles que pueden realizar la operacion.

  ## Ejemplo
  iex> Usuarios.autorizar(usuario, [:coordinador, :administrador])
  {:ok, :autorizado}
  """
  def autorizar(usuario, tipos_permitidos) do
    cond do
      usuario == nil ->
        {:error, "Debe iniciar sesión"}

      not Map.get(usuario, :conectado, false) ->
        {:error, "El usuario no está conectado"}

      Map.get(usuario, :tipo) in tipos_permitidos ->
        {:ok, :autorizado}

      true ->
        {:error, "No tiene permisos para realizar esta operación"}
    end
  end

  @doc """
  Cambia el rol de un usuario registrado en el sistema.

  ## Parámetros
  - Usuarios: Lista de usuarios registrados.
  - Usuario: Nombre de usuario al que se cambiará el rol.
  - Nuevo_tipo: Nuevo rol que tendrá el usuario.
  """
  def cambiar_tipo(usuarios, usuario, nuevo_tipo) do
    existe =
      Enum.any?(usuarios, fn u ->
        Map.get(u, :usuario) == usuario
      end)

    cond do
      not existe ->
        {:error, "El usuario no existe"}

      nuevo_tipo not in @tipos_permitidos ->
        {:error, "El tipo de usuario no es válido"}

      true ->
        usuarios_actualizados =
          Enum.map(usuarios, fn u ->
            if Map.get(u, :usuario) == usuario do
              Map.update(
                %{u | tipo: nuevo_tipo},
                :actividades,
                ["Cambio de rol a #{nuevo_tipo}"],
                fn actividades ->
                  ["Cambio de rol a #{nuevo_tipo}" | actividades]
                end
              )
            else
              u
            end
          end)

        {:ok, usuarios_actualizados}
    end
  end
end
