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
  @spec run(state :: Regbench.State.t(), key :: atom()) :: Regbench.State.t()
  def run(%Regbench.State{} = state, key) when is_atom(key) do
    start_time = System.monotonic_time()

    state.nodes_pid_infos
    |> Task.async_stream(
      fn {node, node_pid_infos} ->
        ref = make_ref()
        tpid = self()

        Node.spawn(node, fn ->
          for {key, npid} <- node_pid_infos do
            state.benchmark_mod.register(key, npid)
          end

          send(tpid, {:registered, ref, length(node_pid_infos)})
        end)

        receive do
          {:registered, ^ref, count} ->
            IO.puts("Registered #{count} processes on node #{node}")
        end

        nil
      end,
      ordered: false,
      timeout: 60_000
    )
    |> Stream.run()

    end_time = System.monotonic_time()
    nano = System.convert_time_unit(end_time - start_time, :native, :nanosecond)

    timed = %Regbench.Result.Timed{nanoseconds: nano}
    %Regbench.State{state | result: Map.put(state.result, key, timed)}
  end
end
