defmodule Regbench do
  @moduledoc """
  A behaviour for a Process Registry benchmark.
  """

  alias Regbench.Phases

  def start(benchmark_mod, process_count, nodes) do
    :ok = Phases.Connect.run(nodes)
    :ok = Phases.Init.run(benchmark_mod)

    {upper_key, pid_infos} = Phases.Launch.run(benchmark_mod, process_count)

    # Benchmark: register
    time_register = Phases.Registration.run(benchmark_mod, pid_infos)
    IO.puts("Registered processes in: #{time_register} sec")
    IO.puts("Registered processes rate: #{process_count / time_register}/sec")

    # Benchmark: registration propogation
    case Phases.PropagationRetrieval.run(upper_key, benchmark_mod, :registration) do
      {:error, :timeout_during_retrieve} ->
        IO.puts("Timed out waiting for registration propagation for #{upper_key}")

      {:error, error} ->
        IO.puts(
          "Error #{inspect(error)} while waiting for registration propagation for #{upper_key}"
        )

      {retrieved_in_ms, retrieved_pid} ->
        IO.puts("Check that process with Key #{upper_key} was found:")
        IO.puts("#{inspect(retrieved_pid)} in #{retrieved_in_ms} ms")
    end

    # Benchmark: unregister
    {time_unregister, _} = :timer.tc(__MODULE__, :unregister, [benchmark_mod, pid_infos])
    IO.puts("Unregistered processes in: #{time_unregister / 1_000_000} sec")
    IO.puts("Unregistered processes rate: #{process_count / time_unregister * 1_000_000}/sec")

    # Benchmark: deregistration propogation
    case Phases.PropagationRetrieval.run(upper_key, benchmark_mod, :deregistration) do
      {:error, :timeout_during_retrieve} ->
        IO.puts("Timed out waiting for deregistration propagation for #{upper_key}")

      {:error, error} ->
        IO.puts(
          "Error #{inspect(error)} while waiting for deregistration propagation for #{upper_key}"
        )

      {retrieved_in_ms, retrieved_pid} ->
        IO.puts("Check that process with Key #{upper_key} was NOT found:")
        IO.puts("#{inspect(retrieved_pid)} in #{retrieved_in_ms} ms")
    end

    # Benchmark: re-registering
    time_reregister = Phases.Registration.run(benchmark_mod, pid_infos)
    IO.puts("Re-registered processes in: #{time_reregister} sec")
    IO.puts("Re-registered processes rate: #{process_count / time_reregister}/sec")

    # Benchmark: re-registration propogation
    case Phases.PropagationRetrieval.run(upper_key, benchmark_mod, :registration) do
      {:error, :timeout_during_retrieve} ->
        IO.puts("Timed out waiting for registration propagation for #{upper_key}")

      {:error, error} ->
        IO.puts(
          "Error #{inspect(error)} while waiting for registration propagation for #{upper_key}"
        )

      {retrieved_in_ms, retrieved_pid} ->
        IO.puts("Check that process with Key #{upper_key} was found:")
        IO.puts("#{inspect(retrieved_pid)} in #{retrieved_in_ms} ms")
    end

    # Benchmark: monitoring
    IO.puts("Kill all processes")
    kill_processes(pid_infos)

    # Benchmark: deregistration after re-registration propogation
    case Phases.PropagationRetrieval.run(upper_key, benchmark_mod, :deregistration) do
      {:error, :timeout_during_retrieve} ->
        IO.puts("Timed out waiting for deregistration propagation for #{upper_key}")

      {:error, error} ->
        IO.puts(
          "Error #{inspect(error)} while waiting for deregistration propagation for #{upper_key}"
        )

      {retrieved_in_ms, retrieved_pid} ->
        IO.puts("Check that process with Key #{upper_key} was NOT found:")
        IO.puts("#{inspect(retrieved_pid)} in #{retrieved_in_ms} ms")
    end
  end

  def unregister(benchmark_mod, pid_infos) do
    Enum.reduce(pid_infos, [], fn {node, node_pid_infos}, acc ->
      rpc_key =
        :rpc.async_call(node, __MODULE__, :unregister_on_node, [benchmark_mod, node_pid_infos])

      [{node, rpc_key} | acc]
    end)
    |> Enum.each(fn {node, rpc_key} ->
      unregistered = :rpc.yield(rpc_key)
      IO.puts("Unregistered #{unregistered} processes on node #{node}")
    end)
  end

  def unregister_on_node(benchmark_mod, node_pid_infos) do
    node_pid_infos
    |> Enum.each(fn {key, pid} -> benchmark_mod.unregister(key, pid) end)

    length(node_pid_infos)
  end

  def kill_processes(pid_infos) do
    pid_infos
    |> Enum.flat_map(fn {_node, node_pid_infos} -> node_pid_infos end)
    |> Enum.each(fn {_key, pid} -> Process.exit(pid, :kill) end)
  end
end
