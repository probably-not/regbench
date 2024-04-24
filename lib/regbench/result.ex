defmodule Regbench.Result do
  defmodule Timed do
    @type t :: %Timed{
            nanoseconds: non_neg_integer() | nil,
            milliseconds: non_neg_integer() | nil,
            timed_out: boolean() | nil
          }

    defstruct [
      :nanoseconds,
      :milliseconds,
      :timed_out
    ]
  end

  @type t :: %Regbench.Result{
          registration: Regbench.Result.Timed.t() | nil,
          registration_propagation: Regbench.Result.Timed.t() | nil,
          deregistration: Regbench.Result.Timed.t() | nil,
          deregistration_propagation: Regbench.Result.Timed.t() | nil,
          reregistration: Regbench.Result.Timed.t() | nil,
          reregistration_propagation: Regbench.Result.Timed.t() | nil,
          killed_propagation: Regbench.Result.Timed.t() | nil
        }

  # TODO: Create the full result struct.
  # The Regbench.start function should return a result so we can store and track details.
  # For example, we probably want to track different Elixir and OTP versions,
  # along with different versions of the registries we are benchmarking.
  defstruct [
    :registration,
    :registration_propagation,
    :deregistration,
    :deregistration_propagation,
    :reregistration,
    :reregistration_propagation,
    :killed_propagation
  ]
end
