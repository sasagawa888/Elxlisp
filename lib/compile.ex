defmodule Elxfunc do
  def is_compiled(_) do
    nil
  end

  def primitive(_) do
    nil
  end
end

defmodule Compile do
  def is_compiled(mode, buf) do
    "def is_compiled(x) do\n" <>
      "Enum.member?([" <>
      is_compiled1(mode, buf, "") <>
      "],x)\n" <>
      "end\n"
  end

  defp is_compiled1(_, [], str) do
    butlaststr(str)
  end

  defp is_compiled1(:mexp, buf, str) do
    {s, buf1} = Read.read(buf, :filein)
    is_compiled1(:mexp, buf1, str <> to_elixir_compiled(s))
  end

  defp is_compiled1(:sexp, buf, str) do
    {s, buf1} = Read.sread(buf, :filein)
    is_compiled1(:sexp, buf1, str <> to_elixir_compiled(s))
  end

  defp to_elixir_compiled([:defun, name, _, _]) do
    ":" <> Atom.to_string(name) <> ","
  end

  defp to_elixir_compiled(_) do
    ""
  end

  defp butlaststr(str) do
    {str1, _} = String.split_at(str, String.length(str) - 1)
    str1
  end

  def caller(_, [], str) do
    str
  end

  def caller(:mexp, buf, str) do
    {s, buf1} = Read.read(buf, :filein)
    caller(:mexp, buf1, str <> to_elixir_caller(s))
  end

  def caller(:sexp, buf, str) do
    {s, buf1} = Read.sread(buf, :filein)
    caller(:sexp, buf1, str <> to_elixir_caller(s))
  end

  defp to_elixir_caller([:defun, name, arg, _]) do
    "def primitive(" <>
      namearg_to_liststr(name, arg) <> ") do " <> namearg_to_funstr(name, arg) <> " end\n"
  end

  defp to_elixir_caller(_) do
    ""
  end

  defp namearg_to_liststr(name, arg) do
    "[:" <> Atom.to_string(name) <> "," <> arg_to_str(arg) <> "]"
  end

  defp namearg_to_funstr(name, arg) do
    Atom.to_string(name) <> "(" <> arg_to_str(arg) <> ")"
  end

  defp arg_to_str([l]) do
    to_elixir(l)
  end

  defp arg_to_str([l | ls]) do
    to_elixir(l) <> "," <> arg_to_str(ls)
  end

  def compile(_, [], str) do
    str
  end

  def compile(:mexp, buf, str) do
    {s, buf1} = Read.read(buf, :filein)
    compile(:mexp, buf1, str <> to_elixir(s))
  end

  def compile(:sexp, buf, str) do
    {s, buf1} = Read.sread(buf, :filein)
    to_elixir(s)
    compile(:sexp, buf1, str <> to_elixir(s))
  end

  defp to_elixir([]) do
    "\n"
  end

  defp to_elixir(:t) do
    "true"
  end

  defp to_elixir(x) when is_atom(x) do
    Atom.to_string(x)
  end

  defp to_elixir(x) when is_integer(x) do
    Integer.to_string(x)
  end

  defp to_elixir(x) when is_float(x) do
    Float.to_string(x)
  end

  defp to_elixir([:defun, name, arg, body]) do
    "def " <>
      Atom.to_string(name) <>
      "(" <>
      arg_to_str(arg) <>
      ") do\n" <>
      to_elixir(body) <>
      "\n" <>
      "end\n"
  end

  defp to_elixir([:cond | ls]) do
    "cond do\n" <>
      cond_to_str(ls) <>
      "end"
  end

  defp to_elixir([:car,x]) do
    "hd(" <> to_elixir(x) <> ")"
  end

  defp to_elixir([:cdr,x]) do
    "tl(" <> to_elixir(x) <> ")"
  end

  defp to_elixir([:cons,x,y]) do
    "[" <> to_elixir(x) <> "|" <> to_elixir(y) <> "]"
  end


  defp to_elixir([:plus, x]) do
    to_elixir(x)
  end

  defp to_elixir([:plus, x | xs]) do
    to_elixir(x) <> "+" <> to_elixir([:plus | xs])
  end

  defp to_elixir([:differnce, x, y]) do
    to_elixir(x) <> "-" <> to_elixir(y)
  end

  defp to_elixir([:times, x]) do
    to_elixir(x)
  end

  defp to_elixir([:times, x | xs]) do
    to_elixir(x) <> "*" <> to_elixir([:times | xs])
  end

  defp to_elixir([:quotient,x,y]) do
    "div(" <> to_elixir(x) <> "," <> to_elixir(y) <> ")"
  end

  defp to_elixir([:recip,x]) do
    "1 / " <> to_elixir(x)
  end

  defp to_elixir([:remainder,x,y]) do
    "rem(" <> to_elixir(x) <> "," <> to_elixir(y) <> ")"
  end

  defp to_elixir([:divide,x,y]) do
    x1 = to_elixir(x)
    y1 = to_elixir(y)
    "[div(" <> x1 <> "," <> y1 <> "),rem(" <> x1 <> "," <> y1 <> ")]"
  end

  defp to_elixir([:expt,x,y]) do
    ":math.pow(" <> to_elixir(x) <> "," <> to_elixir(y) <> ")"
  end

  defp to_elixir([:eq, x, y]) do
    to_elixir(x) <> "==" <> to_elixir(y)
  end

  defp to_elixir([:eqlessp, x, y]) do
    to_elixir(x) <> "<=" <> to_elixir(y)
  end

  defp to_elixir([:add1, x]) do
    to_elixir(x) <> "+ 1"
  end

  defp to_elixir([:sub1, x]) do
    to_elixir(x) <> "- 1"
  end

  defp to_elixir([:null,x]) do
    to_elixir(x) <> "== nil or " <> to_elixir(x) <> "== []"
  end

  defp to_elixir([:length,x]) do
    "length(" <> to_elixir(x) <> ")"
  end

  defp to_elixir(x) when is_list(x) do
    [name | arg] = x
    Atom.to_string(name) <> "(" <> arg_to_str(arg) <> ")"
  end

  defp cond_to_str([]) do
    ""
  end

  defp cond_to_str([[l1, l2] | ls]) do
    to_elixir(l1) <> " -> " <> to_elixir(l2) <> "\n" <> cond_to_str(ls)
  end
end
