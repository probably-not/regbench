defmodule Regbench.Registries.Syn do
  use Regbench.Benchmark

  def distributed?(), do: true

  def init(_nodes) do
    :ok = :syn.start()
    :ok = :syn.add_node_to_scopes([:registry])
    :ok
  end

  def register(key, pid) do
    :ok = :syn.register(:registry, key, pid)
  end

  def deregister(key, _pid) do
    :syn.unregister(:registry, key)
  end

  def retrieve(key) do
    case :syn.lookup(:registry, key) do
      :undefined -> :undefined
      {pid, _} -> pid
    end
  end
end
