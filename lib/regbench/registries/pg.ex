defmodule Regbench.Registries.PG do
  @behaviour Regbench.Benchmark

  def init() do
    nodes = [node() | Node.list()]

    nodes
    |> Enum.each(fn node ->
      ref = make_ref()
      pid = self()

      Node.spawn(node, fn ->
        {:ok, pgpid} = :pg.start_link()
        Process.unlink(pgpid)
        send(pid, {:ok, ref, pgpid})
      end)

      receive do
        {:ok, ^ref, pgpid} ->
          IO.puts("Initialized #{__MODULE__} on #{inspect(node)}")
          Process.link(pgpid)
      end
    end)
  end

  def register(key, pid) do
    # Make sure the group membership is empty (no duplicates for now)
    [] = :pg.get_members(key)
    :ok = :pg.join(key, pid)
  end

  def unregister(key, pid) do
    :ok = :pg.leave(key, pid)
  end

  def retrieve(key) do
    case :pg.get_members(key) do
      [] -> :undefined
      [pid] -> pid
    end
  end

  def process_loop() do
    receive do
      _ ->
        :ok
    end
  end
end
