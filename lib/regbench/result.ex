defmodule Regbench.Result do
  # TODO: Create the full result struct.
  # The Regbench.start function should return a result so we can store and track details.
  # For example, we probably want to track different Elixir and OTP versions,
  # along with different versions of the registries we are benchmarking.
  defstruct [:registry, :node_count]
end
