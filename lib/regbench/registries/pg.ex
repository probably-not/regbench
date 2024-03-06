defmodule Regbench.Registries.PG do
  @behaviour Regbench.Benchmark

  def init() do
    [node() | Node.list()]
    |> Enum.each(fn node ->
      Node.spawn(node, fn ->
        {:ok, _} = :pg.start_link()
      end)
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
