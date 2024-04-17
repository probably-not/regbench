defmodule Regbench.Phases.Deregistration do
  @moduledoc ~S"""
  Regbench.Phases.Deregistration is the phase used in the benchmark to run deregistration of processes on each node.
  We use this to determine the speed of how long it takes to deregister processes, specifically, how long the deregistration
  function takes per deregistration. It should be noted that processes are not actually checked for deregistration propagation here,
  but the speed of the deregister function is checked. Registries that deregister and propogate asynchronously may have a fast deregistration
  speed, while a different phase (Regbench.Phases.PropagationRetrieval) actually checks them for how fast these deregistration changes
  propagate to the nodes.
  """

  @doc false
  @spec run(
          benchmark_mod :: Regbench.Benchmark.t(),
          node_pid_infos :: list(Regbench.Phases.Launch.node_pid_infos())
        ) :: Regbench.Types.seconds_taken()
  def run(benchmark_mod, nodes_pid_infos) do
    start_time = System.monotonic_time()

    nodes_pid_infos
    |> Task.async_stream(
      fn {node, node_pid_infos} ->
        ref = make_ref()
        tpid = self()

        Node.spawn(node, fn ->
          for {key, npid} <- node_pid_infos do
            benchmark_mod.deregister(key, npid)
          end

          send(tpid, {:deregistered, ref, length(node_pid_infos)})
        end)

        receive do
          {:deregistered, ^ref, count} ->
            IO.puts("Deregistered #{count} processes on node #{node}")
        end

        nil
      end,
      ordered: false
    )
    |> Stream.run()

    end_time = System.monotonic_time()
    nano = System.convert_time_unit(end_time - start_time, :native, :nanosecond)
    nano / 1_000_000_000
  end
end
