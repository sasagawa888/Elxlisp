defmodule Mix.Tasks.Elxlisp do
  use Mix.Task

  def run(_) do
    Elxlisp.repl()
  end
end
