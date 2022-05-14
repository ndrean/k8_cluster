defmodule K8Cluster.Supervisor do
  use Supervisor

  def start_link(init_args) do
    Supervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @impl true
  def init(_init_args) do
    []
    |> Supervisor.init(strategy: :one_for_one)
  end
end
