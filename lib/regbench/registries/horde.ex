defmodule Regbench.Registries.Horde do
  @behaviour Regbench.Benchmark

  def init() do
    nodes = [node() | Node.list()]

    nodes
    |> Enum.each(fn node ->
      ref = make_ref()
      pid = self()

      Node.spawn(node, fn ->
        {:ok, hpid} = Horde.Registry.start_link(keys: :unique, name: __MODULE__, members: nodes)
        Process.unlink(hpid)
        send(pid, {:ok, ref, hpid})
      end)

      receive do
        {:ok, ^ref, hpid} ->
          IO.puts("Initialized #{__MODULE__} on #{inspect(node)}")
          Process.link(hpid)
      end
    end)
  end

  def register(key, pid) do
    {:ok, _} = Horde.Registry.register(__MODULE__, key, pid)
  end

  def unregister(key, _pid) do
    :ok = Horde.Registry.unregister(__MODULE__, key)
  end

  def retrieve(key) do
    pids = Horde.Registry.lookup(__MODULE__, key)

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
