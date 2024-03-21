defmodule Regbench.Benchmark do
  @moduledoc """
  A behaviour for a Process Registry benchmark.
  """

  @callback distributed?() :: boolean()
  @callback init(nodes :: list(node())) :: :ok | {:ok, pid()} | pid()
  @callback register(key :: String.t(), pid()) :: term()
  @callback unregister(key :: String.t(), pid()) :: term()
  @callback retrieve(key :: String.t()) :: pid() | :undefined
  @callback process_loop() :: any()
end
