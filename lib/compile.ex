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
    to_elixir(l, [])
  end

  defp arg_to_str([l | ls]) do
    to_elixir(l, []) <> "," <> arg_to_str(ls)
  end

  def compile(_, [], str) do
    str
  end

  def compile(:mexp, buf, str) do
    {s, buf1} = Read.read(buf, :filein)
    compile(:mexp, buf1, str <> to_elixir(s, []))
  end

  def compile(:sexp, buf, str) do
    {s, buf1} = Read.sread(buf, :filein)
    compile(:sexp, buf1, str <> to_elixir(s, []))
  end

  defp to_elixir(:t, _) do
    "true"
  end

  defp to_elixir([], _) do
    "[]"
  end

  defp to_elixir(nil, _) do
    "nil"
  end

  defp to_elixir(x, _) when is_atom(x) do
    Atom.to_string(x)
  end

  defp to_elixir(x, _) when is_integer(x) do
    Integer.to_string(x)
  end

  defp to_elixir(x, _) when is_float(x) do
    Float.to_string(x)
  end

  defp to_elixir([:defun, name, arg, body], _) do
    "def " <>
      Atom.to_string(name) <>
      "(" <>
      arg_to_str(arg) <>
      ") do\n" <>
      to_elixir(body, arg) <>
      "\n" <>
      "end\n"
  end

  defp to_elixir([:cond | ls], arg) do
    "cond do\n" <>
      cond_to_str(ls, arg) <>
      "end"
  end

  defp to_elixir([:car, x], arg) do
    "hd(" <> to_elixir(x, arg) <> ")"
  end

  defp to_elixir([:cdr, x], arg) do
    "tl(" <> to_elixir(x, arg) <> ")"
  end

  defp to_elixir([:cons, x, y], arg) do
    "[" <> to_elixir(x, arg) <> "|" <> to_elixir(y, arg) <> "]"
  end

  defp to_elixir([:plus, x], arg) do
    to_elixir(x, arg)
  end

  defp to_elixir([:plus, x | xs], arg) do
    to_elixir(x, arg) <> "+" <> to_elixir([:plus | xs], arg)
  end

  defp to_elixir([:difference, x, y], arg) do
    to_elixir(x, arg) <> "-" <> to_elixir(y, arg)
  end

  defp to_elixir([:times, x], arg) do
    to_elixir(x, arg)
  end

  defp to_elixir([:times, x | xs], arg) do
    to_elixir(x, arg) <> "*" <> to_elixir([:times | xs], arg)
  end

  defp to_elixir([:quotient, x, y], arg) do
    "div(" <> to_elixir(x, arg) <> "," <> to_elixir(y, arg) <> ")"
  end

  defp to_elixir([:recip, x], arg) do
    "1 / " <> to_elixir(x, arg)
  end

  defp to_elixir([:remainder, x, y], arg) do
    "rem(" <> to_elixir(x, arg) <> "," <> to_elixir(y, arg) <> ")"
  end

  defp to_elixir([:divide, x, y], arg) do
    x1 = to_elixir(x, arg)
    y1 = to_elixir(y, arg)
    "[div(" <> x1 <> "," <> y1 <> "),rem(" <> x1 <> "," <> y1 <> ")]"
  end

  defp to_elixir([:expt, x, y], arg) do
    ":math.pow(" <> to_elixir(x, arg) <> "," <> to_elixir(y, arg) <> ")"
  end

  defp to_elixir([:atom, x], arg) do
    "is_atom(" <> to_elixir(x, arg) <> ") or is_number(" <> to_elixir(x, arg) <> ")"
  end

  defp to_elixir([:numberp, x], arg) do
    "is_number(" <> to_elixir(x, arg) <> ")"
  end

  defp to_elixir([:floatp, x], arg) do
    "is_float(" <> to_elixir(x, arg) <> ")"
  end

  defp to_elixir([:zerop, x], arg) do
    to_elixir(x, arg) <> "== 0"
  end

  defp to_elixir([:minusp, x], arg) do
    to_elixir(x, arg) <> "< 0"
  end

  defp to_elixir([:onep, x], arg) do
    to_elixir(x, arg) <> "== 1"
  end

  defp to_elixir([:listp, x], arg) do
    "is_list(" <> to_elixir(x, arg) <> ")"
  end

  defp to_elixir([:symbolp, x], arg) do
    "is_atom(" <> to_elixir(x, arg) <> ")"
  end

  defp to_elixir([:eq, x, y], arg) do
    to_elixir(x, arg) <> "==" <> to_elixir(y, arg)
  end

  defp to_elixir([:equall, x, y], arg) do
    to_elixir(x, arg) <> "==" <> to_elixir(y, arg)
  end

  defp to_elixir([:greaterp, x, y], arg) do
    to_elixir(x, arg) <> ">" <> to_elixir(y, arg)
  end

  defp to_elixir([:eqgreaterp, x, y], arg) do
    to_elixir(x, arg) <> ">=" <> to_elixir(y, arg)
  end

  defp to_elixir([:lessp, x, y], arg) do
    to_elixir(x, arg) <> "<" <> to_elixir(y, arg)
  end

  defp to_elixir([:eqlessp, x, y], arg) do
    to_elixir(x, arg) <> "<=" <> to_elixir(y, arg)
  end

  defp to_elixir([:max | x], arg) do
    x1 = Enum.map(x, fn y -> to_elixir(y, arg) end)
    "Enum.max(" <> List.to_string(x1) <> ")"
  end

  defp to_elixir([:min | x], arg) do
    x1 = Enum.map(x, fn y -> to_elixir(y, arg) end)
    "Enum.min(" <> List.to_string(x1) <> ")"
  end

  defp to_elixir([:logor | x], arg) do
    x1 = Enum.map(x, fn y -> to_elixir(y, arg) end)
    List.to_string(x1) <> "|> Eval.logor"
  end

  defp to_elixir([:logand | x], arg) do
    x1 = Enum.map(x, fn y -> to_elixir(y, arg) end)
    List.to_string(x1) <> "|> Eval.logand"
  end

  defp to_elixir([:logxor | x], arg) do
    x1 = Enum.map(x, fn y -> to_elixir(y, arg) end)
    List.to_string(x1) <> "|> Eval.logxor"
  end

  defp to_elixir([:leftshift, x, y], arg) do
    "leftshift(" <> to_elixir(x, arg) <> "," <> to_elixir(y, arg) <> ")"
  end

  defp to_elixir([:add1, x], arg) do
    to_elixir(x, arg) <> "+ 1"
  end

  defp to_elixir([:sub1, x], arg) do
    to_elixir(x, arg) <> "- 1"
  end

  defp to_elixir([:null, x], arg) do
    to_elixir(x, arg) <> "== nil or " <> to_elixir(x, arg) <> "== []"
  end

  defp to_elixir([:length, x], arg) do
    "length(" <> to_elixir(x, arg) <> ")"
  end

  defp to_elixir([:read], _) do
    "{s, _} = Read.read([], :stdin)\n" <>
      "s\n"
  end

  defp to_elixir([:print, x], arg) do
    "Print.print(" <> to_elixir(x, arg) <> ")"
  end

  defp to_elixir([:reverse, x], arg) do
    "Enum.reverse(" <> to_elixir(x, arg) <> ")"
  end

  defp to_elixir([:member, x, y], arg) do
    "Enum.member?(" <> to_elixir(y, arg) <> "," <> to_elixir(x, arg) <> ")"
  end

  defp to_elixir([:and | x], arg) do
    x1 = Enum.map(x, fn y -> to_elixir(y, arg) end)
    List.to_string(x1) <> "|> Enum.all?(fn x -> x != nil end)"
  end

  defp to_elixir([:or | x], arg) do
    x1 = Enum.map(x, fn y -> to_elixir(y, arg) end)
    List.to_string(x1) <> "|> Enum.any?(fn x -> x != nil end)"
  end

  defp to_elixir(x, arg) when is_list(x) do
    [name | arg1] = x

    if Enum.member?(arg, name) do
      Atom.to_string(name) <> ".(" <> arg_to_str(arg1) <> ")"
    else
      Atom.to_string(name) <> "(" <> arg_to_str(arg1) <> ")"
    end
  end

  defp cond_to_str([], _) do
    ""
  end

  defp cond_to_str([[l1, l2] | ls], arg) do
    to_elixir(l1, arg) <> " -> " <> to_elixir(l2, arg) <> "\n" <> cond_to_str(ls, arg)
  end
end
