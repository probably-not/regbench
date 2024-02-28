defmodule RegbenchTest do
  use ExUnit.Case
  doctest Regbench

  test "greets the world" do
    assert Regbench.hello() == :world
  end
end
