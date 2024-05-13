defmodule Regbench.Registries.Reginald do
  use Regbench.Benchmark

  def distributed?(), do: true

  def init(_nodes) do
    case Reginald.start_link(name: __MODULE__, keys: :unique) do
      {:ok, pid} when is_pid(pid) -> pid
      {:error, {:already_started, pid}} when is_pid(pid) -> pid
      anything_else -> throw("failed to start Reginald: #{inspect(anything_else)}")
    end
  end

  def register(key, pid) do
    ref = make_ref()
    send(pid, {:register, key, ref, self()})

    receive do
      {:registered, :yes, ^ref} -> :yes
    after
      5_000 -> throw("unexpected registration timeout")
    end
  end

  def deregister(key, pid) do
    ref = make_ref()
    send(pid, {:deregister, key, ref, self()})

    receive do
      {:deregistered, :ok, ^ref} -> :ok
    after
      5_000 -> throw("unexpected registration timeout")
    end
  end

  def retrieve(key) do
    Reginald.whereis_name({__MODULE__, key})
  end

  def process_loop() do
    receive do
      {:register, name, ref, origin} ->
        result = Reginald.register_name({__MODULE__, name}, self())
        send(origin, {:registered, result, ref})
        process_loop()

      {:deregister, name, ref, origin} ->
        result = Reginald.unregister_name({__MODULE__, name})
        send(origin, {:deregistered, result, ref})
        process_loop()

      _ ->
        :ok
    end
  end
end
