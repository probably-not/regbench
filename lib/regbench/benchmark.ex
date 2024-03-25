defmodule Regbench.Benchmark do
  @moduledoc """
  A behaviour for a Process Registry benchmark.
  """

  @typedoc "A module implementing the Regbench.Benchmark behaviour."
  @type t() :: module()

  @callback distributed?() :: boolean()
  @callback init(nodes :: list(node())) :: :ok | {:ok, pid()} | pid()
  @callback register(key :: String.t(), pid()) :: term()
  @callback unregister(key :: String.t(), pid()) :: term()
  @callback retrieve(key :: String.t()) :: pid() | :undefined
  @callback process_loop() :: any()

  @doc false
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Regbench.Benchmark

      @doc false
      def process_loop() do
        receive do
          _ ->
            :ok
        end
      end

      defoverridable process_loop: 0
    end
  end
end
