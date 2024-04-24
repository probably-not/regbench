defmodule Regbench.State do
  @type t :: %Regbench.State{
          benchmark_mod: Regbench.Benchmark.t(),
          nodes_to_connect: list(node()),
          nodes: list(node()) | nil,
          process_count: non_neg_integer(),
          nodes_pid_infos: list(Regbench.Types.node_pid_infos()) | nil,
          upper_key: Regbench.Types.registration_key() | nil,
          result: Regbench.Result.t()
        }

  defstruct [
    :benchmark_mod,
    :nodes_to_connect,
    :nodes,
    :process_count,
    :nodes_pid_infos,
    :upper_key,
    :result
  ]
end
