defmodule Mix.Tasks.Elxlisp do
  use Mix.Task

  def run(arg) do
    Elxlisp.repl(arg)
  end
end
