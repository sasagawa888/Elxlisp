defmodule ElxlispTest do
  use ExUnit.Case
  doctest Elxlisp

  test "read" do
    assert Read.is_upper_str("ABC") == true 
  end
end
