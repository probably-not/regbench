defmodule Regbench.State do
  @type t :: %Regbench.State{
          benchmark_module: Regbench.Benchmark.t(),
          nodes: list(node()),
          process_count: non_neg_integer(),
          nodes_pid_infos: list(Regbench.Phases.Launch.node_pid_infos()),
          upper_key: Regbench.Phases.Launch.registration_key(),
          result: Regbench.Result.t()
        }

  defstruct [
    :benchmark_module,
    :nodes,
    :process_count,
    :nodes_pid_infos,
    :upper_key,
    :result
  ]
end
