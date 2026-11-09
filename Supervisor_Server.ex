defmodule SistemaSupervisor do
  @moduledoc """
  Supervisa los servidores principales del sistema de gestión
  de emergencias y controla su reinicio cuando ocurre un fallo.

  - Autores: Briyith Sanchez Alonso y Nicolas Arango Gutierrez
  - Fecha: Noviembre del 2026
  - Licencia: GNU GPL V3
  """

  use Supervisor

  @doc """
  Inicia el supervisor del sistema.

  Parámetros:
  - opts: opciones de configuración del supervisor.
  """
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Procesos que serán administrados por el supervisor.
    hijos = [
      {RecursosServer, []},
      {UsuariosServer, []}
    ]

    # Reinicia únicamente el proceso que presente un fallo.
    Supervisor.init(hijos, strategy: :one_for_one)
  end
end
