defmodule Regbench.Registries.Global do
  @behaviour Regbench.Benchmark

  def distributed?(), do: true

  def init(_nodes) do
    :ok
  end

  def register(key, pid) do
    :yes = :global.register_name(key, pid)
  end

  def unregister(key, _pid) do
    :global.unregister_name(key)
  end

  def retrieve(key) do
    :global.whereis_name(key)
  end

  def process_loop() do
    receive do
      _ ->
        :ok
    end
  end
end
