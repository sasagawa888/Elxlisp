defmodule Elxlisp do
  @moduledoc """
  Simple Lisp interpreter
  To invoke interpreter repl()
  """

  @doc """
  REPL(read eval print loop)
  """
  def repl(arg) do
    IO.write("Lisp 1.5 in Elixir ")
    message(arg)

    cond do
      Enum.member?(arg, "para") and Enum.member?(arg, "mexp") -> repl1([], [], :para, :mexp)
      Enum.member?(arg, "seq") and Enum.member?(arg, "mexp") -> repl1([], [], :seq, :mexp)
      Enum.member?(arg, "para") and Enum.member?(arg, "sexp") -> repl1([], [], :para, :sexp)
      Enum.member?(arg, "seq") and Enum.member?(arg, "sexp") -> repl1([], [], :seq, :sexp)
      Enum.member?(arg, "para") -> repl1([], [], :para, :mexp)
      Enum.member?(arg, "seq") -> repl1([], [], :seq, :mexp)
      Enum.member?(arg, "sexp") -> repl1([], [], :seq, :sexp)
      Enum.member?(arg, "mexp") -> repl1([], [], :seq, :mexp)
      true -> repl1([], [], :seq, :mexp)
    end
  end

  # repl1 is helper function for repl
  # It has environment and buffer
  # The environment is association list. e.g. [[:a,1],[;b,2]]
  # the buffer is list. Each elements are string

  defp repl1(env, buf, mode, exp) do
    try do
      if exp == :mexp do
        IO.write("? ")
        {s, buf1} = Read.read(buf, :stdin)
        {s1, env1} = Eval.eval(s, env, mode)
        Print.print(s1)
        repl1(env1, buf1, mode, exp)
      else if exp == :sexp do
        IO.write("S? ")
        {s, buf1} = Read.sread(buf, :stdin)
        {s1, env1} = Eval.eval(s, env, mode)
        Print.print(s1)
        repl1(env1, buf1, mode, exp)
      end
      end
    catch
      x ->
        IO.inspect(x)

        if x != "goodbye" do
          repl1(env, buf, mode, exp)
        else
          true
        end
    end
  end

  def message([]) do
    IO.puts("M-expression in sequential")
  end
  def message(l) do
    message1(l)
  end
  def message1([]) do IO.puts("") end
  def message1([l|ls]) do
    cond do
      l == "mexp" -> IO.write("M-expression ")
      l == "sexp" -> IO.write("S-expression ")
      l == "para" -> IO.write("in parallel ")
      l == "seq"  -> IO.write("in sequential ")
    end
    message1(ls)
  end

  def error(msg, dt) do
    IO.write("Error ")
    IO.write(msg)
    IO.write(" ")
    throw(dt)
  end
  # for test M-expression
  def foo(x) do
    {s, _} = x |> Read.tokenize() |> Read.read(:stdin)
    {s1, _} = Eval.eval(s, [], :seq)
    s1
  end

  # for test S-expression
  def bar(x) do
    {s, _} = x |> Read.stokenize() |> Read.sread(:stdin)
    {s1, _} = Eval.eval(s, [], :seq)
    s1
  end

  def stop() do
    raise("stop")
  end
end
