defmodule Regbench.Phases.Connect do
  # TODO: Right now we are manually connecting, but I think it may be better to just delegate this to Libcluster.
  # Libcluster can give us different strategies, so that in different environments we can cluster in different ways.
  # For example, locally, we can cluster based on gossip, or by a static list of nodes, and when we run a full benchmark,
  # we can cluster based on DNS based strategies.
  @spec run(nodes :: list(node())) :: :ok
  def run(nodes) do
    Enum.each(nodes, fn node ->
      true = Node.connect(node)
    end)
  end
end
