defmodule Regbench.Types do
  @type seconds_taken :: float()
  @type registration_key :: String.t()
  @type pid_info :: {registration_key(), pid()}
  @type node_pid_infos :: {node(), list(pid_info())}
end
