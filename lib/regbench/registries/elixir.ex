defmodule Regbench.Registries.Elixir do
  use Regbench.Benchmark

  def distributed?(), do: false

  def init(_nodes) do
    Registry.start_link(keys: :unique, name: __MODULE__)
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
end
