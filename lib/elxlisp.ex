defmodule Elxlisp do
  @moduledoc """
  Simple Lisp interpreter
  To invoke interpreter repl()
  """

  @doc """
  REPL(read eval print loop)
  """
  def repl() do
    IO.puts("Lisp 1.5 in Elixir")
    repl1([], [])
  end

  # repl1 is helper function for repl
  # It has environment and buffer
  # The environment is association list. e.g. [[:a,1],[;b,2]]
  # the buffer is list. Each elements are string

  defp repl1(env, buf) do
    try do
      IO.write("? ")
      {s, buf1} = Read.read(buf, :stdin)
      {s1, env1} = Eval.eval(s, env, :para)
      Print.print(s1)
      repl1(env1, buf1)
    catch
      x ->
        IO.inspect(x)

        if x != "goodbye" do
          repl1(env, buf)
        else
          true
        end
    end
  end

  def error(msg, dt) do
    IO.write("Error ")
    IO.write(msg)
    IO.write(" ")
    throw(dt)
  end

  def foo(x) do
    {s, _} = x |> Read.tokenize() |> Read.read(:stdin)
    {s1, _} = Eval.eval(s, [], :seq)
    s1
  end

  def stop() do
    raise("stop")
  end
end
