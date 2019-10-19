defmodule ElxlispTest do
  use ExUnit.Case
  doctest Elxlisp

  test "read" do
    assert Read.is_integer_str("123") == true
    assert Read.is_integer_str("12e3") == false
    assert Read.is_float_str("123") == false
    assert Read.is_float_str("12.0e3") == true
    assert Read.is_float_str("12.0") == true
  end

  test "eval" do
    assert Eval.is_upper_atom(:ABC) == true
    assert Eval.is_upper_atom(:Abc) == false
  end

end
