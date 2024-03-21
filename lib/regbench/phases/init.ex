defmodule Regbench.Phases.Init do
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
