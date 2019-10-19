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
    repl1([],[])
  end

  #repl1 is helper function for repl
  #It has environment and buffer
  #The environment is association list. e.g. [[:a,1],[;b,2]]
  #the buffer is list. Each elements are string

  defp repl1(env,buf) do
    try do
      IO.write("? ")
      {s,buf1} = Read.read(buf)
      {s1,env1} = Eval.eval(s,env)
      Print.print(s1)
      repl1(env1,buf1)
    catch
      x -> IO.puts(x)
      if x != "goodbye" do
        repl1(env,buf)
      else
        true
      end
    end
  end


  def stop() do
    raise("stop")
  end
end
