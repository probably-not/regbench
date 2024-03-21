defmodule RegbenchTest do
  use ExUnit.Case
  doctest Regbench

  test "loaded" do
    assert Code.loaded?(Regbench)
  end
end
