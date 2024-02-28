defmodule Regbench.Registries.PG do
  @behaviour Regbench.Benchmark

  def init() do
    [node() | Node.list()]
    |> Enum.each(fn node ->
      :rpc.call(node, :pg, :start_link, [])
    end)
  end

  def register(key, pid) do
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