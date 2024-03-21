defmodule Regbench.Registries.Elixir do
  @behaviour Regbench.Benchmark

  def init() do
    if length(Node.list()) > 0 do
      raise "The Elixir Registry is a local only registry"
    end

    nodes = [node()]

    nodes
    |> Enum.each(fn node ->
      ref = make_ref()
      pid = self()

      Node.spawn(node, fn ->
        {:ok, rpid} = Registry.start_link(keys: :unique, name: __MODULE__)
        Process.unlink(rpid)
        send(pid, {:ok, ref, rpid})
      end)

      receive do
        {:ok, ^ref, rpid} ->
          IO.puts("Initialized #{__MODULE__} on #{inspect(node)}")
          Process.link(rpid)
      end
    end)
  end

  def register(key, pid) do
    {:ok, _} = Registry.register(__MODULE__, key, pid)
  end

  def unregister(key, _pid) do
    :ok = Registry.unregister(__MODULE__, key)
  end

  def retrieve(key) do
    pids = Registry.lookup(__MODULE__, key)

    if length(pids) == 0 do
      :undefined
    else
      {pid, _} = Enum.at(pids, 0)
      pid
    end
  end

  def process_loop() do
    receive do
      _ ->
        :ok
    end
  end
end
