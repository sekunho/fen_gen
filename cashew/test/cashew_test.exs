defmodule CashewTest do
  use ExUnit.Case
  doctest Cashew

  test "greets the world" do
    assert Cashew.hello() == :world
  end
end
