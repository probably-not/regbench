defmodule Regbench.Phases.Connect do
  @moduledoc ~S"""
  Regbench.Phases.Connect is the first stage of the benchmark, used to connect all of the given nodes to run the benchmark on.

  This currently runs a very simple `Node.connect/1` call for each node given in the list, expecting the output of `true` to make sure
  that the nodes all properly connect.

  A future iteration may use a better clustering methodology, such as delegating to the Libcluster or DNSCluster packages.
  """

  @doc false
  @spec run(state :: Regbench.State.t()) :: Regbench.State.t()
  def run(%Regbench.State{} = state) do
    Enum.each(state.nodes_to_connect, fn node ->
      true = Node.connect(node)
    end)

    %Regbench.State{state | nodes: [node() | Node.list()]}
  end
end
