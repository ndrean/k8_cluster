defmodule K8Cluster.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  require Logger

  use Application

  @impl true
  def start(_type, _args) do
    topologies = [
      k8: [
        strategy: Cluster.Strategy.Kubernetes,
        config: [
          mode: :ip,
          kubernetes_namespace: "default",
          polling_interval: 10_000,
          kubernetes_selector: "app=myapp",
          kubernetes_node_basename: "k8_cluster",
          kubernetes_ip_lookup_mode: :pods
        ]
      ]
    ]

    cookie = Application.get_env(:k8_cluster, :cookie) |> String.to_atom()
    unless node() == :nonode@nohost, do: Node.set_cookie(node(), cookie)

    Logger.debug("#{K8Cluster.hello()} from #{inspect(node())}", ansi_color: :green)

    children = [
      {Cluster.Supervisor, [topologies, [name: K8Cluster.ClusterSupervisor]]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: K8Cluster.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # defp topologies() do
  #   env = Application.get_env(:k8_cluster, :env)
  #   # case Application.compile_env(:k8_cluster, :env) do

  #   case env do
  #     "prod" ->
  #       [
  #         k8: [
  #           strategy: Cluster.Strategy.Kubernetes,
  #           config: [
  #             mode: :dns,
  #             kubernetes_namespace: "default",
  #             polling_interval: 10_000,
  #             kubernetes_selector: "app=myapp",
  #             kubernetes_node_basename: "mypp"
  #           ]
  #         ]
  #       ]
  #   end
  # end
end
