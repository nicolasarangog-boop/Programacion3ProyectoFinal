defmodule RecursosServer do
  @moduledoc """
  Servidor encargado de administrar concurrentemente
  el inventario de recursos del sistema.

  - Autores: Briyith Sanchez Alonso y Nicolas Arango Gutierrez
  - Fecha: Octubre del 2026
  - Licencia: GNU GPL V3
  """

  use GenServer

  @doc """
  Inicia el servidor con una lista de recursos.
  - recursos: inventario inicial.
  """
  def start_link(recursos \\ []) do
    GenServer.start_link(__MODULE__, recursos, name: __MODULE__)
  end

  @doc """
  Registra un nuevo recurso.
  - datos: información del recurso.
  """
  def registrar(datos) do
    GenServer.call(__MODULE__, {:registrar, datos})
  end

  @doc """
  Consulta todos los recursos.
  """
  def listar do
    GenServer.call(__MODULE__, :listar)
  end

  @doc """
  Busca un recurso por código y ubicación.
  - codigo: código del recurso.
  - ubicacion: centro o albergue.
  """
  def buscar(codigo, ubicacion) do
    GenServer.call(__MODULE__, {:buscar, codigo, ubicacion})
  end

  @doc """
  Registra una entrada de recursos.
  - codigo: código del recurso.
  - ubicacion: centro o albergue.
  - cantidad: unidades que ingresan.
  - descripcion: motivo de la entrada.
  """
  def entrada(codigo, ubicacion, cantidad, descripcion) do
    GenServer.call(
      __MODULE__,
      {:entrada, codigo, ubicacion, cantidad, descripcion}
    )
  end

  @doc """
  Registra una salida de recursos.
  - codigo: código del recurso.
  - ubicacion: centro o albergue.
  - cantidad: unidades que salen.
  - descripcion: motivo de la salida.
  """
  def salida(codigo, ubicacion, cantidad, descripcion) do
    GenServer.call(
      __MODULE__,
      {:salida, codigo, ubicacion, cantidad, descripcion}
    )
  end

  @doc """
  Transfiere recursos entre ubicaciones.
  - codigo: código del recurso.
  - origen: ubicación de origen.
  - destino: ubicación de destino.
  - cantidad: unidades que se transfieren.
  """
  def transferir(codigo, origen, destino, cantidad) do
    GenServer.call(
      __MODULE__,
      {:transferir, codigo, origen, destino, cantidad}
    )
  end

  @doc """
  Consulta el historial de un recurso.
  - codigo: código del recurso.
  - ubicacion: centro o albergue.
  """
  def historial(codigo, ubicacion) do
    GenServer.call(__MODULE__, {:historial, codigo, ubicacion})
  end

  @doc """
  Consulta los recursos con inventario bajo.
  - limite: cantidad máxima de referencia.
  """
  def recursos_bajos(limite) do
    GenServer.call(__MODULE__, {:recursos_bajos, limite})
  end

  # Inicializa el estado interno del servidor.
  @impl true
  def init(recursos) do
    {:ok, recursos}
  end

  # Registra un recurso y actualiza el inventario.
  @impl true
  def handle_call({:registrar, datos}, _from, recursos) do
    case Recursos.registrar_recurso(recursos, datos) do
      {:ok, nuevos_recursos} ->
        {:reply, {:ok, nuevos_recursos}, nuevos_recursos}

      {:error, motivo} ->
        {:reply, {:error, motivo}, recursos}
    end
  end

  # Devuelve el inventario actual.
  @impl true
  def handle_call(:listar, _from, recursos) do
    {:reply, Recursos.listar_recursos(recursos), recursos}
  end

  # Busca un recurso en una ubicación.
  @impl true
  def handle_call({:buscar, codigo, ubicacion}, _from, recursos) do
    {:reply, Recursos.buscar_recurso(recursos, codigo, ubicacion), recursos}
  end

  # Registra una entrada de inventario.
  @impl true
  def handle_call(
        {:entrada, codigo, ubicacion, cantidad, descripcion},
        _from,
        recursos
      ) do
    case Recursos.registrar_entrada(
           recursos,
           codigo,
           ubicacion,
           cantidad,
           descripcion
         ) do
      {:ok, nuevos_recursos} ->
        {:reply, {:ok, nuevos_recursos}, nuevos_recursos}

      {:error, motivo} ->
        {:reply, {:error, motivo}, recursos}
    end
  end

  # Registra una salida de inventario.
  @impl true
  def handle_call(
        {:salida, codigo, ubicacion, cantidad, descripcion},
        _from,
        recursos
      ) do
    case Recursos.registrar_salida(
           recursos,
           codigo,
           ubicacion,
           cantidad,
           descripcion
         ) do
      {:ok, nuevos_recursos} ->
        {:reply, {:ok, nuevos_recursos}, nuevos_recursos}

      {:error, motivo} ->
        {:reply, {:error, motivo}, recursos}
    end
  end

  # Transfiere recursos entre centros.
  @impl true
  def handle_call(
        {:transferir, codigo, origen, destino, cantidad},
        _from,
        recursos
      ) do
    case Recursos.transferir_recurso(
           recursos,
           codigo,
           origen,
           destino,
           cantidad
         ) do
      {:ok, nuevos_recursos} ->
        {:reply, {:ok, nuevos_recursos}, nuevos_recursos}

      {:error, motivo} ->
        {:reply, {:error, motivo}, recursos}
    end
  end

  # Consulta los movimientos de un recurso.
  @impl true
  def handle_call({:historial, codigo, ubicacion}, _from, recursos) do
    {:reply, Recursos.consultar_historial(recursos, codigo, ubicacion), recursos}
  end

  # Identifica los recursos con pocas existencias.
  @impl true
  def handle_call({:recursos_bajos, limite}, _from, recursos) do
    {:reply, Recursos.recursos_bajos(recursos, limite), recursos}
  end
end
