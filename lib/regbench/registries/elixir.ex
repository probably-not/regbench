defmodule Regbench.Registries.Elixir do
  @behaviour Regbench.Benchmark

  def init() do
    [node() | Node.list()]
    |> Enum.each(fn node ->
      Node.spawn(node, fn ->
        {:ok, _} = Registry.start_link(keys: :unique, name: __MODULE__)
      end)
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
