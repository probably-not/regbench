defmodule Regbench.Phases.Registration do
  @moduledoc ~S"""
  Regbench.Phases.Registration is the phase used in the benchmark to run registration of processes on each node.
  We use this to determine the speed of how long it takes to register processes, specifically, how long the registration
  function takes per registration. It should be noted that processes are not actually checked for registration propagation here,
  but the speed of the register function is checked. Registries that register and propogate asynchronously may have a fast registration
  speed, while a different phase (Regbench.Phases.PropagationRetrieval) actually checks them for how fast these registration changes
  propagate to the nodes.
  """

  @doc false
  @spec run(
          benchmark_mod :: Regbench.Benchmark.t(),
          node_pid_infos :: Regbench.Phases.Launch.node_pid_infos()
        ) :: :ok
  def run(benchmark_mod, nodes_pid_infos) do
    Enum.reduce(nodes_pid_infos, [], fn {node, node_pid_infos}, acc ->
      rpc_key =
        :rpc.async_call(node, __MODULE__, :register_on_node, [benchmark_mod, node_pid_infos])

      [{node, rpc_key} | acc]
    end)
    |> Enum.each(fn {node, rpc_key} ->
      registered = :rpc.yield(rpc_key)
      IO.puts("Registered #{registered} processes on node #{node}")
    end)
  end

  def register_on_node(benchmark_mod, node_pid_infos) do
    node_pid_infos
    |> Enum.each(fn {key, pid} ->
      benchmark_mod.register(key, pid)
    end)

    length(node_pid_infos)
  end
end
