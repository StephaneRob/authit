defmodule AuthitTest do
  use ExUnit.Case
  doctest Authit

  test "greets the world" do
    assert Authit.hello() == :world
  end
end
