defmodule ElxlispTest do
  use ExUnit.Case
  doctest Elxlisp

  test "read" do
    assert Read.is_integer_str("123") == true
    assert Read.is_integer_str("12e3") == false
    assert Read.is_float_str("123") == false
    assert Read.is_float_str("12.0e3") == true
    assert Read.is_float_str("12.0") == true
    assert Read.is_float_str("12.0E3") == true
    assert Read.is_float_str("12.E3") == false
  end

  test "eval" do
    assert Eval.is_upper_atom(:ABC) == true
    assert Eval.is_upper_atom(:Abc) == false
  end

  test "function" do
    assert Elxlisp.foo("add1[1]\n") == 2
    assert Elxlisp.foo("sub1[1]\n") == 0
    assert Elxlisp.foo("plus[1;2]\n") == 3
    assert Elxlisp.foo("difference[1;2]\n") == -1
    assert Elxlisp.foo("times[1;2;3]\n") == 6
    
  end

end
