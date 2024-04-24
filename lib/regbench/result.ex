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
