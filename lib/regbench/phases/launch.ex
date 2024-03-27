defmodule Regbench.Phases.Launch do
  @moduledoc ~S"""
  Regbench.Phases.Launch is the third stage of the benchmark, used to launch our processes across all nodes in our cluster.

  We first calculate the number of processes that should be run on each node by dividing the total number of processes
  (provided by the `process_count` variable) by the total number of connected nodes (found by concatenating `Node.list/0` with `node/1`).
  This also gives us our upper process key, which we use in one of the subsequent benchmark stages, for benchmarking
  the speed of retrieval for the final process registered.

  After calculating each of the above, we then spawn the necessary processes on each node,
  and delegate to the given benchmark's `Regbench.Benchmark.process_loop/0` function on that node.

  `Regbench.Benchmark.process_loop/0` by default (when using `use Regbench.Benchmark`) will run a simple function
  that waits for a message to be received. Since nobody is sending messages to any of the processes spawned, it will
  simply run forever. `Regbench.Benchmark.process_loop/0` can be overriden if one wants to simulate some sort of work,
  for example if you'd like to simulate how a Registry benchmarks when the node is doing a lot of CPU or IO work.
  However, keep in mind that our benchmark does not currently take into account processes going down, and will assume that
  all processes are started and alive.
  """

  @type node_pids :: {node(), list(pid())}

  @doc false
  @spec run(benchmark_mod :: Regbench.Benchmark.t(), process_count :: non_neg_integer()) ::
          {String.t(), list(node_pids())}
  def run(benchmark_mod, process_count) do
    nodes = [node() | Node.list()]
    processes_per_node = round(process_count / length(nodes))
    upper_key = Integer.to_string(processes_per_node * length(nodes))

    all_node_pids =
      Enum.reduce(nodes, [], fn node, acc ->
        starting_key = length(acc) * processes_per_node
        pids = launch_processes_on_node(node, benchmark_mod, processes_per_node, starting_key)
        [{node, pids} | acc]
      end)

    {upper_key, all_node_pids}
  end

  @doc false
  @spec launch_processes_on_node(
          node :: node(),
          benchmark_mod :: Regbench.Benchmark.t(),
          processes_per_node :: non_neg_integer(),
          starting_key :: non_neg_integer()
        ) :: list(pid())
  defp launch_processes_on_node(node, benchmark_mod, processes_per_node, starting_key) do
    (starting_key + 1)..(starting_key + processes_per_node)
    |> Enum.map(&Integer.to_string(&1))
    |> Enum.map(fn key -> {key, Node.spawn(node, benchmark_mod, :process_loop, [])} end)
  end
end
