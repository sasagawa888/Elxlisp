defmodule ElxlispTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
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
    assert Eval.assoc(:a,[[:a|1],[:b|2]]) == 1
    assert Eval.assoc(:b,[[:a|1],[:b|2]]) == 2
    assert Eval.assoc(:c,[[:a|1],[:b|2]]) == nil
    assert Eval.pairlis([:a,:b],[1,2],[]) == [[:a|1],[:b|2]]
  end

  test "print" do
    assert capture_io(fn -> Print.print([1, 2]) end) == "(1 2)\n"
    assert capture_io(fn -> Print.print([[1, 2], [3, 4]]) end) == "((1 2) (3 4))\n"
    assert capture_io(fn -> Print.print([[1 | 2], [3 | 4]]) end) == "((1 . 2) (3 . 4))\n"
  end

  test "function" do
    assert Elxlisp.foo("car[(A B)]\n") == :A
    assert Elxlisp.foo("caar[((A B) C)]\n") == :A
    assert Elxlisp.foo("cdr[(A B)]\n") == [:B]
    assert Elxlisp.foo("cons[A;B]\n") == [:A | :B]
    assert Elxlisp.foo("add1[1]\n") == 2
    assert Elxlisp.foo("sub1[1]\n") == 0
    assert Elxlisp.foo("plus[1;2]\n") == 3
    assert Elxlisp.foo("plus[1;2;3]\n") == 6
    assert Elxlisp.foo("difference[1;2]\n") == -1
    assert Elxlisp.foo("times[1;2;3]\n") == 6
    assert Elxlisp.foo("quotient[1;2]\n") == 0
    assert Elxlisp.foo("quotient[5;2]\n") == 2
    assert Elxlisp.foo("recip[2]\n") == 0.5
    assert Elxlisp.foo("remainder[5;2]\n") == 1
    assert Elxlisp.foo("divide[5;2]\n") == [2, 1]
    assert Elxlisp.foo("expt[2;3]\n") == 8
    assert Elxlisp.foo("add1[1]\n") == 2
    assert Elxlisp.foo("sub1[1]\n") == 0
    assert Elxlisp.foo("null[1]\n") == nil
    assert Elxlisp.foo("null[()]\n") == :t
    assert Elxlisp.foo("numberp[1]\n") == :t
    assert Elxlisp.foo("numberp[1.2]\n") == :t
    assert Elxlisp.foo("numberp[A]\n") == nil
    assert Elxlisp.foo("symbolp[A]\n") == :t
    assert Elxlisp.foo("symbolp[1]\n") == nil
    assert Elxlisp.foo("floatp[2.2]\n") == :t
    assert Elxlisp.foo("floatp[2]\n") == nil
    assert Elxlisp.foo("floatp[a]\n") == nil
    assert Elxlisp.foo("min[1;3;2]\n") == 1
    assert Elxlisp.foo("max[1;3;2]\n") == 3
    assert Elxlisp.foo("length[(1 2 3)]\n") == 3
    #assert Elxlisp.foo("operate[+;2;3]\n") == 5
    #assert Elxlisp.foo("operate[-;2;3]\n") == -1
    #assert Elxlisp.foo("operate[x;2;3]\n") == 6
    #assert Elxlisp.foo("operate[/;6;3]\n") == 2
    assert Elxlisp.foo("atom[x]\n") == :t
    assert Elxlisp.foo("atom[X]\n") == :t
    assert Elxlisp.foo("atom[1]\n") == :t
    assert Elxlisp.foo("atom[1.23]\n") == :t
    assert Elxlisp.foo("eq[1;1]\n") == :t
    assert Elxlisp.foo("eq[1;2]\n") == nil
    assert Elxlisp.foo("eq[A;A]\n") == :t
    assert Elxlisp.foo("eq[A;B]\n") == nil
    assert Elxlisp.foo("equal[1;1]\n") == :t
    assert Elxlisp.foo("equal[1;1]\n") == :t
    assert Elxlisp.foo("equal[1;\"a\"]\n") == nil
    assert Elxlisp.foo("greaterp[1;1]\n") == nil
    assert Elxlisp.foo("greaterp[1.2;1]\n") == :t
    assert Elxlisp.foo("lessp[1;1]\n") == nil
    assert Elxlisp.foo("lessp[0;1]\n") == :t
  end
end
