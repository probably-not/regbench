defmodule Regbench.Registries.Syn do
  @behaviour Regbench.Benchmark

  def init() do
    nodes = [node() | Node.list()]

    nodes
    |> Enum.each(fn node ->
      ref = make_ref()
      pid = self()

      Node.spawn(node, fn ->
        :ok = :syn.start()
        :ok = :syn.add_node_to_scopes([:registry])
        send(pid, {:ok, ref})
      end)

      receive do
        {:ok, ^ref} ->
          IO.puts("Initialized #{__MODULE__} on #{inspect(node)}")
      end
    end)
  end

  def register(key, pid) do
    :ok = :syn.register(:registry, key, pid)
  end

  def unregister(key, _pid) do
    :syn.unregister(:registry, key)
  end

  def retrieve(key) do
    case :syn.lookup(:registry, key) do
      :undefined -> :undefined
      {pid, _} -> pid
    end
  end

  def process_loop() do
    receive do
      _ ->
        :ok
    end
  end
end
