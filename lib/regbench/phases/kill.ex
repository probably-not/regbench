defmodule Regbench.Phases.Kill do
  @moduledoc ~S"""
  Regbench.Phases.Kill is the phase used in the benchmark to kill the created processes on each node.
  This phase is used in order to later benchmark the propagation of a registry's ability to monitor and deregister processes that have exited.
  This essentially simply runs `Process.kill/2` on each pid that we have generated, which sends an exit signal to the pid.
  """

  @doc false
  @spec run(node_pid_infos :: list(Regbench.Phases.Launch.node_pid_infos())) :: :ok
  def run(nodes_pid_infos) do
    nodes_pid_infos
    |> Enum.flat_map(fn {_node, node_pid_infos} -> node_pid_infos end)
    |> Enum.each(fn {_key, pid} -> Process.exit(pid, :kill) end)
  end
end
