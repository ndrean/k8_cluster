defmodule K8ClusterTest do
  use ExUnit.Case
  doctest K8Cluster

  test "greets the world" do
    assert K8Cluster.hello() == :world
  end
end
