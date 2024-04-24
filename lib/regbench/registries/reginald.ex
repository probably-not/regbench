defmodule Regbench.Registries.Reginald do
  use Regbench.Benchmark

  def distributed?(), do: true

  def init(_nodes) do
    case Reginald.start_link(name: __MODULE__) do
      {:ok, pid} when is_pid(pid) -> pid
      {:error, {:already_started, pid}} when is_pid(pid) -> pid
      anything_else -> throw("failed to start Reginald: #{inspect(anything_else)}")
    end
  end

  def register(key, pid) do
    Reginald.register_name({__MODULE__, key}, pid)
  end

  def deregister(key, _pid) do
    :ok = Reginald.unregister_name({__MODULE__, key})
  end

  def retrieve(key) do
    Reginald.whereis_name({__MODULE__, key})
  end
end
