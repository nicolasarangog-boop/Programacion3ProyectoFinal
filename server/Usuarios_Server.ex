defmodule UsuariosServer do
  @moduledoc """
  Gestiona los usuarios y sus sesiones mediante un proceso GenServer.
  Mantiene el estado de los usuarios conectados y registrados.

  - Autores: Briyith Sanchez Alonso y Nicolas Arango Gutierrez
  - Fecha: Noviembre del 2026
  - Licencia: GNU GPL V3
  """

  use GenServer

  @doc """
  Inicia el servidor con una lista inicial de usuarios.

  Parámetros:
  - usuarios: lista inicial de usuarios registrados.
  """
  def start_link(usuarios \\ []) do
    GenServer.start_link(__MODULE__, usuarios, name: __MODULE__)
  end

  @doc """
  Registra un nuevo usuario en el sistema.

  Parámetros:
  - datos: mapa con la información del usuario.
  """
  def registrar(datos) do
    GenServer.call(__MODULE__, {:registrar, datos})
  end

  @doc """
  Autentica un usuario mediante sus credenciales.

  Parámetros:
  - usuario: nombre de usuario.
  - contrasena: contraseña ingresada.
  """
  def autenticar(usuario, contrasena) do
    GenServer.call(__MODULE__, {:autenticar, usuario, contrasena})
  end

  @doc """
  Conecta un usuario utilizando su nombre como nombre completo.

  Parámetros:
  - usuario: nombre de usuario.
  - contrasena: contraseña.
  - tipo: rol del usuario.
  - zona_principal: zona asignada.
  """
  def conectar(usuario, contrasena, tipo, zona_principal) do
    GenServer.call(
      __MODULE__,
      {:conectar, usuario, contrasena, tipo, zona_principal}
    )
  end

  @doc """
  Conecta un usuario utilizando su nombre completo.

  Parámetros:
  - usuario: nombre de usuario.
  - contrasena: contraseña.
  - nombre_completo: nombre completo.
  - tipo: rol del usuario.
  - zona_principal: zona asignada.
  """
  def conectar(usuario, contrasena, nombre_completo, tipo, zona_principal) do
    GenServer.call(
      __MODULE__,
      {:conectar_completo, usuario, contrasena, nombre_completo, tipo, zona_principal}
    )
  end

  @doc """
  Desconecta un usuario del sistema.

  Parámetros:
  - usuario: nombre de usuario que desea desconectarse.
  """
  def desconectar(usuario) do
    GenServer.call(__MODULE__, {:desconectar, usuario})
  end

  @doc """
  Consulta todos los usuarios registrados sin mostrar sus contraseñas.

  Parámetros:
  - No recibe parámetros.
  """
  def listar do
    GenServer.call(__MODULE__, :listar)
  end

  @doc """
  Consulta la información de un usuario sin mostrar su contraseña.

  Parámetros:
  - usuario: nombre de usuario que se desea consultar.
  """
  def buscar(usuario) do
    GenServer.call(__MODULE__, {:buscar, usuario})
  end

  @doc """
  Consulta los usuarios que tienen una sesión activa.

  Parámetros:
  - No recibe parámetros.
  """
  def conectados do
    GenServer.call(__MODULE__, :conectados)
  end

  @doc """
  Registra una actividad en el historial de un usuario.

  Parámetros:
  - usuario: nombre de usuario.
  - actividad: descripción de la actividad realizada.
  """
  def registrar_actividad(usuario, actividad) do
    GenServer.call(
      __MODULE__,
      {:registrar_actividad, usuario, actividad}
    )
  end

  @doc """
  Verifica si un usuario conectado tiene permisos para una operación.

  Parámetros:
  - usuario: nombre de usuario.
  - tipos_permitidos: lista de roles autorizados.
  """
  def autorizar(usuario, tipos_permitidos) do
    GenServer.call(
      __MODULE__,
      {:autorizar, usuario, tipos_permitidos}
    )
  end

  @doc """
  Cambia el rol de un usuario registrado.

  Parámetros:
  - usuario: Nombre de usuario.
  - nuevo_tipo: Nuevo rol que se asignará.
  """
  def cambiar_tipo(usuario, nuevo_tipo) do
    GenServer.call(__MODULE__, {:cambiar_tipo, usuario, nuevo_tipo})
  end

  @impl true
  def init(_usuarios) do
    case Persistencia.cargar(:usuarios) do
      {:ok, usuarios} ->
        {:ok, usuarios}

      {:error, mensaje} ->
        {:stop, mensaje}
    end
  end

  @impl true
  def handle_call({:registrar, datos}, _from, usuarios) do
    resultado = Usuarios.registrar(usuarios, datos)
    responder(resultado, usuarios)
  end

  def handle_call({:autenticar, usuario, contrasena}, _from, usuarios) do
    resultado = Usuarios.autenticar(usuarios, usuario, contrasena)
    {:reply, resultado, usuarios}
  end

  def handle_call(
        {:conectar, usuario, contrasena, tipo, zona_principal},
        _from,
        usuarios
      ) do
    resultado =
      Usuarios.conectar(
        usuarios,
        usuario,
        contrasena,
        tipo,
        zona_principal
      )

    responder(resultado, usuarios)
  end

  def handle_call(
        {:conectar_completo, usuario, contrasena, nombre_completo, tipo, zona_principal},
        _from,
        usuarios
      ) do
    resultado =
      Usuarios.conectar(
        usuarios,
        usuario,
        contrasena,
        nombre_completo,
        tipo,
        zona_principal
      )

    responder(resultado, usuarios)
  end

  def handle_call({:desconectar, usuario}, _from, usuarios) do
    resultado = Usuarios.desconectar(usuarios, usuario)
    responder(resultado, usuarios)
  end

  def handle_call(:listar, _from, usuarios) do
    resultado = Usuarios.listar(usuarios)
    {:reply, resultado, usuarios}
  end

  def handle_call({:buscar, usuario}, _from, usuarios) do
    usuario_encontrado =
      Enum.find(usuarios, fn u ->
        Map.get(u, :usuario) == usuario
      end)

    resultado =
      case usuario_encontrado do
        nil ->
          {:error, "El usuario no existe"}

        encontrado ->
          {:ok, Map.drop(encontrado, [:contrasena])}
      end

    {:reply, resultado, usuarios}
  end

  def handle_call(:conectados, _from, usuarios) do
    lista =
      Enum.filter(usuarios, fn u ->
        Map.get(u, :conectado, false)
      end)

    resultado =
      Enum.map(lista, fn u ->
        Map.drop(u, [:contrasena])
      end)

    {:reply, {:ok, resultado}, usuarios}
  end

  def handle_call(
        {:registrar_actividad, usuario, actividad},
        _from,
        usuarios
      ) do
    resultado =
      Usuarios.registrar_actividad(
        usuarios,
        usuario,
        actividad
      )

    responder(resultado, usuarios)
  end

  def handle_call(
        {:autorizar, usuario, tipos_permitidos},
        _from,
        usuarios
      ) do
    usuario_encontrado =
      Enum.find(usuarios, fn u ->
        Map.get(u, :usuario) == usuario
      end)

    usuario_publico =
      case usuario_encontrado do
        nil -> nil
        encontrado -> Map.drop(encontrado, [:contrasena])
      end

    resultado =
      Usuarios.autorizar(
        usuario_publico,
        tipos_permitidos
      )

    {:reply, resultado, usuarios}
  end

  def handle_call({:cambiar_tipo, usuario, nuevo_tipo}, _from, usuarios) do
    resultado = Usuarios.cambiar_tipo(usuarios, usuario, nuevo_tipo)
    responder(resultado, usuarios)
  end

  # Actualiza el estado del servidor cuando una operación es exitosa.
  # Guarda los cambios antes de actualizar el estado.
  defp responder({:ok, nuevos_usuarios}, usuarios_anteriores) do
    case Persistencia.guardar(:usuarios, nuevos_usuarios) do
      {:ok, _mensaje} ->
        {:ok, usuarios_publicos} = Usuarios.listar(nuevos_usuarios)

        {:reply, {:ok, usuarios_publicos}, nuevos_usuarios}

      {:error, mensaje} ->
        {:reply, {:error, mensaje}, usuarios_anteriores}
    end
  end

  # Conserva el estado anterior cuando una operación falla.
  defp responder({:error, mensaje}, usuarios) do
    {:reply, {:error, mensaje}, usuarios}
  end
end
