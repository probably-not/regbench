defmodule Regbench.Phases.PropagationRetrieval do
  @moduledoc ~S"""
  Regbench.Phases.Propagation is the phase used in the benchmark to determine the time it takes to propagate the registrations.
  This is used both to test the propagation of registrations, and to test the propagation of deregistrations.

  The implementation is very basic:
  Since we know the `upper_key` (the highest key created when generating keys to register processes with), and we register the keys in order
  on each node, we simply check to see that this key was propogated to our current node.
  Since we should have registered this upper key on the final node in the list, it means that we can measure the time it takes for this key
  to propagate to the node running the benchmark, which is the first node in the list.

  When checking for registrations, we ensure that the key returns a pid.
  When checking for deregistrations, we ensure that the key returns `:undefined` (as mandated by the Registration module spec in Erlang).
  """

  @max_retrieve_waiting_time 60_000
  @wait_time 50

  @type step :: :registration | :deregistration

  @doc false
  @spec run(state :: Regbench.State.t(), step :: step(), key :: atom()) :: Regbench.State.t()
  def run(%Regbench.State{} = state, step, key) when is_atom(step) and is_atom(key) do
    start_time = epoch_time_ms()

    case retrieval(state.upper_key, state.benchmark_mod, start_time, step) do
      {:error, :timeout_during_retrieve} ->
        timed = %Regbench.Result.Timed{timed_out: true}
        %Regbench.State{state | result: Map.put(state.result, key, timed)}

      {retrieved_in_ms, _retrieved_pid} ->
        timed = %Regbench.Result.Timed{milliseconds: retrieved_in_ms}
        %Regbench.State{state | result: Map.put(state.result, key, timed)}
    end
  end

  @spec retrieval(
          key :: Regbench.Types.registration_key(),
          benchmark_mod :: Regbench.Benchmark.t(),
          start_time :: non_neg_integer(),
          step :: step()
        ) :: {non_neg_integer(), pid()} | {:error, :timeout_during_retrieve | term()}
  defp retrieval(key, benchmark_mod, start_time, :registration) do
    case benchmark_mod.retrieve(key) do
      :undefined ->
        Process.sleep(@wait_time)

        if epoch_time_ms() > start_time + @max_retrieve_waiting_time do
          {:error, :timeout_during_retrieve}
        else
          retrieval(key, benchmark_mod, start_time, :registration)
        end

      pid ->
        retrieved_in_ms = epoch_time_ms() - start_time
        {retrieved_in_ms, pid}
    end
  end

  defp retrieval(key, benchmark_mod, start_time, :deregistration) do
    case benchmark_mod.retrieve(key) do
      :undefined ->
        retrieved_in_ms = epoch_time_ms() - start_time
        {retrieved_in_ms, :undefined}

      _pid ->
        Process.sleep(@wait_time)

        if epoch_time_ms() > start_time + @max_retrieve_waiting_time do
          {:error, :timeout_during_retrieve}
        else
          retrieval(key, benchmark_mod, start_time, :deregistration)
        end
    end
  end

  @spec epoch_time_ms() :: integer()
  defp epoch_time_ms() do
    {mega, sec, micro} = :os.timestamp()
    (mega * 1_000_000 + sec) * 1000 + round(micro / 1000)
  end
end
