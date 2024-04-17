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
            benchmark_mod.register(key, npid)
          end

          send(tpid, {:registered, ref, length(node_pid_infos)})
        end)

        receive do
          {:registered, ^ref, count} ->
            IO.puts("Registered #{count} processes on node #{node}")
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
