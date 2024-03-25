defmodule Regbench do
  @moduledoc """
  A behaviour for a Process Registry benchmark.
  """

  @max_retrieve_waiting_time 60_000

  def start(benchmark_mod, process_count, nodes) do
    Regbench.Phases.Connect.run(nodes)
    Regbench.Phases.Init.run(benchmark_mod)

    {upper_key, pid_infos} = launch_processes(benchmark_mod, process_count)

    # Benchmark: register
    {time_register, _} = :timer.tc(__MODULE__, :register, [benchmark_mod, pid_infos])
    IO.puts("Registered processes in: #{time_register / 1_000_000} sec")
    IO.puts("Registered processes rate: #{process_count / time_register * 1_000_000}/sec")

    # Benchmark: registration propogation
    {retrieved_in_ms_1, retrieve_process_1} = retrieve(:pid, benchmark_mod, upper_key)
    IO.puts("Check that process with Key #{upper_key} was found:")
    IO.puts("#{inspect(retrieve_process_1)} in #{retrieved_in_ms_1} ms")

    # Benchmark: unregister
    {time_unregister, _} = :timer.tc(__MODULE__, :unregister, [benchmark_mod, pid_infos])
    IO.puts("Unregistered processes in: #{time_unregister / 1_000_000} sec")
    IO.puts("Unregistered processes rate: #{process_count / time_unregister * 1_000_000}/sec")

    # Benchmark: unregistration propogation
    {retrieved_in_ms_2, retrieve_process_2} = retrieve(:undefined, benchmark_mod, upper_key)
    IO.puts("Check that process with Key #{upper_key} was NOT found:")
    IO.puts("#{inspect(retrieve_process_2)} in #{retrieved_in_ms_2} ms")

    # Benchmark: re-registering
    {time_reregister, _} = :timer.tc(__MODULE__, :register, [benchmark_mod, pid_infos])
    IO.puts("Re-registered processes in: #{time_reregister / 1_000_000} sec")
    IO.puts("Re-registered processes rate: #{process_count / time_reregister * 1_000_000}/sec")

    # Benchmark: re-registration propogation
    {retrieved_in_ms_3, retrieve_process_3} = retrieve(:pid, benchmark_mod, upper_key)
    IO.puts("Check that process with Key #{upper_key} was found:")
    IO.puts("#{inspect(retrieve_process_3)} in #{retrieved_in_ms_3} ms")

    # Benchmark: monitoring
    IO.puts("Kill all processes")
    kill_processes(pid_infos)
    {retrieved_in_ms_4, retrieve_process_4} = retrieve(:undefined, benchmark_mod, upper_key)
    IO.puts("Check that process with Key #{upper_key} was NOT found:")
    IO.puts("#{inspect(retrieve_process_4)} in #{retrieved_in_ms_4} ms")
  end

  def launch_processes(benchmark_mod, process_count) do
    nodes = [node() | Node.list()]
    processes_per_node = round(process_count / length(nodes))
    upper_key = Integer.to_string(processes_per_node * length(nodes))

    node_procs =
      Enum.reduce(nodes, [], fn node, acc ->
        starting_key = length(acc) * processes_per_node
        pids = launch_processes_on_node(benchmark_mod, processes_per_node, starting_key, node)
        [{node, pids} | acc]
      end)

    {upper_key, node_procs}
  end

  def launch_processes_on_node(benchmark_mod, processes_per_node, starting_key, node) do
    (starting_key + 1)..(starting_key + processes_per_node)
    |> Enum.map(&Integer.to_string(&1))
    |> Enum.map(fn key -> {key, Node.spawn(node, benchmark_mod, :process_loop, [])} end)
  end

  def register(benchmark_mod, pid_infos) do
    Enum.reduce(pid_infos, [], fn {node, node_pid_infos}, acc ->
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

  def retrieve(expected, benchmark_mod, key) do
    start_time = epoch_time_ms()
    retrieve(expected, benchmark_mod, key, start_time)
  end

  def retrieve(:undefined, benchmark_mod, key, start_time) do
    case benchmark_mod.retrieve(key) do
      :undefined ->
        retrieved_in_ms = epoch_time_ms() - start_time
        {retrieved_in_ms, :undefined}

      {:error, error} ->
        {:error, error}

      _pid ->
        Process.sleep(50)

        if epoch_time_ms() > start_time + @max_retrieve_waiting_time do
          {:error, :timeout_during_retrieve}
        else
          retrieve(:undefined, benchmark_mod, key, start_time)
        end
    end
  end

  def retrieve(:pid, benchmark_mod, key, start_time) do
    case benchmark_mod.retrieve(key) do
      :undefined ->
        Process.sleep(50)

        if epoch_time_ms() > start_time + @max_retrieve_waiting_time do
          {:error, :timeout_during_retrieve}
        else
          retrieve(:pid, benchmark_mod, key, start_time)
        end

      {:error, error} ->
        {:error, error}

      pid ->
        retrieved_in_ms = epoch_time_ms() - start_time
        {retrieved_in_ms, pid}
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

  def epoch_time_ms() do
    {mega, sec, micro} = :os.timestamp()
    (mega * 1_000_000 + sec) * 1000 + round(micro / 1000)
  end
end
