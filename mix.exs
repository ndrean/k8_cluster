defmodule K8Cluster.MixProject do
  use Mix.Project

  def project do
    [
      app: :k8_cluster,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {K8Cluster.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:libcluster, "~> 3.3"}
    ]
  end

  defp releases do
    [
      myapp: [
        applications: [k8_cluster: :permanent]
      ]
    ]
  end
end
