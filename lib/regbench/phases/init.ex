defmodule Regbench.Phases.Init do
  @moduledoc ~S"""
  Regbench.Phases.Init is the second stage of the benchmark, used to run any sort of initialization
  that the benchmark module might need to run.

  This spawns a process on each connected node (found by concatenating `Node.list/0` with `node/1`),
  and delegates to the given benchmark's `Regbench.Benchmark.init/1` function on that node.
  Based on the return value, it will then trigger `Process.unlink/1` to ensure that the started process
  is not linked to the spawned process on the node - this tends to happen in cases where a Registry's API
  only exposes a `start_link` function (automatically linking to the parent) as opposed to both `start_link` and `start`.
  When this is the case, we make sure to unlink from the spawned function on the node, and instead link it to the Regbench process.
  """

  @doc false
  @spec run(benchmark_mod :: Regbench.Benchmark.t()) :: :ok
  def run(benchmark_mod) do
    nodes = [node() | Node.list()]

    if not benchmark_mod.distributed?() and length(nodes) > 1,
      do: raise("The #{benchmark_mod} Registry is a local only registry")

    nodes
    |> Enum.each(fn node ->
      ref = make_ref()
      pid = self()

      Node.spawn(node, fn ->
        case benchmark_mod.init(nodes) do
          :ok ->
            send(pid, {:ok, ref})

          {:ok, bpid} when is_pid(bpid) ->
            Process.unlink(bpid)
            send(pid, {:ok, ref, bpid})

          bpid when is_pid(bpid) ->
            Process.unlink(bpid)
            send(pid, {:ok, ref, bpid})
        end
      end)

      receive do
        {:ok, ^ref} ->
          :ok

        {:ok, ^ref, bpid} ->
          Process.link(bpid)
      end

      IO.puts("Initialized #{benchmark_mod} on #{inspect(node)}")
    end)
  end
end
