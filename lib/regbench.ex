defmodule Regbench do
  @moduledoc """
  A behaviour for a Process Registry benchmark.
  """

  alias Regbench.Phases

  def start(benchmark_mod, process_count, nodes) do
    %Regbench.State{
      benchmark_mod: benchmark_mod,
      nodes_to_connect: nodes,
      process_count: process_count,
      result: %Regbench.Result{}
    }
    |> Phases.Connect.run()
    |> Phases.Init.run()
    |> Phases.Launch.run()
    |> Phases.Registration.run(:registration)
    |> tap(fn state ->
      seconds = state.result.registration.nanoseconds / 1_000_000_000
      IO.puts("Registered processes in: #{seconds} sec")
      IO.puts("Registered processes rate: #{state.process_count / seconds}/sec")
    end)
    |> Phases.PropagationRetrieval.run(:registration, :registration_propagation)
    |> tap(fn state ->
      if state.result.registration_propagation.timed_out do
        IO.puts("Timed out waiting for registration propagation for #{state.upper_key}")
      else
        IO.puts(
          "Process registration with key #{state.upper_key} propagated in #{state.result.registration_propagation.milliseconds} ms"
        )
      end
    end)
    |> Phases.Deregistration.run()
    |> tap(fn state ->
      seconds = state.result.deregistration.nanoseconds / 1_000_000_000
      IO.puts("Deregistered processes in: #{seconds} sec")
      IO.puts("Deregistered processes rate: #{state.process_count / seconds}/sec")
    end)
    |> Phases.PropagationRetrieval.run(:deregistration, :deregistration_propagation)
    |> tap(fn state ->
      if state.result.deregistration_propagation.timed_out do
        IO.puts("Timed out waiting for deregistration propagation for #{state.upper_key}")
      else
        IO.puts(
          "Process deregistration with key #{state.upper_key} propagated in #{state.result.deregistration_propagation.milliseconds} ms"
        )
      end
    end)
    |> Phases.Registration.run(:reregistration)
    |> tap(fn state ->
      seconds = state.result.reregistration.nanoseconds / 1_000_000_000
      IO.puts("Re-registered processes in: #{seconds} sec")
      IO.puts("Re-registered processes rate: #{state.process_count / seconds}/sec")
    end)
    |> Phases.PropagationRetrieval.run(:registration, :reregistration_propagation)
    |> tap(fn state ->
      if state.result.reregistration_propagation.timed_out do
        IO.puts("Timed out waiting for registration propagation for #{state.upper_key}")
      else
        IO.puts(
          "Process registration with key #{state.upper_key} propagated in #{state.result.reregistration_propagation.milliseconds} ms"
        )
      end
    end)
    |> tap(fn _state -> IO.puts("Kill all processes") end)
    |> Phases.Kill.run()
    |> Phases.PropagationRetrieval.run(:deregistration, :killed_propagation)
    |> tap(fn state ->
      if state.result.killed_propagation.timed_out do
        IO.puts("Timed out waiting for registration propagation for #{state.upper_key}")
      else
        IO.puts(
          "Process deregistration with key #{state.upper_key} propagated in #{state.result.killed_propagation.milliseconds} ms"
        )
      end
    end)
  end
end
