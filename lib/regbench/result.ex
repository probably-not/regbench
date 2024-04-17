defmodule Regbench.Result do
  defmodule Timed do
    @type t :: %Timed{
            nanoseconds: non_neg_integer()
          }

    defstruct [
      :nanoseconds
    ]
  end

  @type t :: %Regbench.Result{
          registration: Regbench.Result.Timed.t(),
          registration_propagation: Regbench.Result.Timed.t(),
          deregistration: Regbench.Result.Timed.t(),
          reregistration: Regbench.Result.Timed.t(),
          reregistration_propagation: Regbench.Result.Timed.t(),
          killed_propagation: Regbench.Result.Timed.t()
        }

  # TODO: Create the full result struct.
  # The Regbench.start function should return a result so we can store and track details.
  # For example, we probably want to track different Elixir and OTP versions,
  # along with different versions of the registries we are benchmarking.
  defstruct [
    :registration,
    :registration_propagation,
    :deregistration,
    :reregistration,
    :reregistration_propagation,
    :killed_propagation
  ]
end
