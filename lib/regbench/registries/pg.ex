defmodule Regbench.Registries.PG do
  use Regbench.Benchmark

  def distributed?(), do: true

  def init(_nodes) do
    :pg.start_link()
  end

  def register(key, pid) do
    # Make sure the group membership is empty (no duplicates for now)
    [] = :pg.get_members(key)
    :ok = :pg.join(key, pid)
  end

  def deregister(key, pid) do
    :ok = :pg.leave(key, pid)
  end

  def retrieve(key) do
    case :pg.get_members(key) do
      [] -> :undefined
      [pid] -> pid
    end
  end
end
