defmodule ElxlispTest do
  use ExUnit.Case
  doctest Elxlisp

  test "read" do
    assert Read.is_upper_str("ABC") == true
    assert Read.is_upper_str("Abc") == false
    assert Read.is_integer_str("123") == true
    assert Read.is_integer_str("12e3") == false
    assert Read.is_float_str("123") == false
    assert Read.is_float_str("12.0e3") == true
    assert Read.is_float_str("12.0") == true
  end
end
