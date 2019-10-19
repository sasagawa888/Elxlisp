defmodule Read do
  @moduledoc """
  Read S expression and translate to list of Elixir
  The S expression is already tokenized to list/ e.g. ["+","1","2"]
  """
  def read([]) do
    buf = IO.gets("") |> comment_line |> drop_eol |> tokenize
    read(buf)
  end
  def read(["("|xs]) do
    {s,rest} = read_list(xs,[])
    {[:quote,s],rest}
  end
  def read(["'"|xs]) do
    {s,rest} = read(xs)
    {[:quote,s],rest}
  end
  def read([x,"["|xs]) do
    {s,rest} = read_bracket(xs,[])
    if Enum.at(rest,0) != "=" do
      {[String.to_atom(x)|s],rest}
    else
      {s1,rest1} = read(Enum.drop(rest,1))
      {[:define,[String.to_atom(x)|s],s1],rest1}
    end
  end
  def read(["["|xs]) do
    {s,rest} = read_bracket(xs,[])
    {[:cond,Enum.chunk_every(s,2)],rest}
  end
  def read([x|xs]) do
    cond do
      is_integer_str(x) -> {String.to_integer(x),xs}
      is_float_str(x) -> {String.to_float(x),xs}
      x == "nil" -> {nil,xs}
      true -> {String.to_atom(x),xs}
    end
  end

  defp read_list([],ls) do
    buf = IO.gets("") |> comment_line |> drop_eol |> tokenize
    read_list(buf,ls)
  end
  defp read_list([")"|xs],ls) do
    {ls,xs}
  end
  defp read_list(["("|xs],ls) do
    {s,rest} = read_list(xs,[])
    read_list(rest,ls++[s])
  end
  defp read_list(["."|xs],ls) do
    {s,rest} = read_list(xs,[])
    if length(s) == 1 do
      {[hd(ls)|hd(s)],rest}
    else
      {ls++s,rest}
    end
  end
  defp read_list(x,ls) do
    {s,rest} = read(x)
    read_list(rest,ls++[s])
  end

  defp read_bracket(["]"|xs],ls) do
    {ls,xs}
  end
  defp read_bracket(x,ls) do
    {s,rest} = read(x)
    read_bracket(rest,ls++[s])
  end


  @doc """
  ## example
  iex>Read.tokenize("(+ 1 2)")
  ["(","+","1","2",")"]
  """
  def tokenize(str) do
    str |> String.replace("(","( ")
    |> String.replace(")"," )")
    |> String.replace("'","' ")
    |> String.replace("["," [ ")
    |> String.replace("]"," ] ")
    |> String.replace(";"," ")
    |> String.replace("->"," ")
    |> String.replace("="," = ")
    |> String.split()
  end

  defp comment_line(x) do
    if String.slice(x,0,1) == ";" do
      IO.gets("? ")
    else
      x
    end
  end

  defp drop_eol(x) do
    String.split(x,"\n") |> hd
  end

  def is_integer_str(x) do
    cond do
      x == "" -> false
      # 123
      Enum.all?(x |> String.to_charlist, fn(y) -> y >= 48 and y <= 57 end) -> true
      # +123
      String.length(x) >= 2 and
      x |> String.to_charlist |> hd == 43 and # +
      Enum.all?(x |> String.to_charlist |> tl, fn(y) -> y >= 48 and y <= 57 end) -> true
      # -123
      String.length(x) >= 2 and
      x |> String.to_charlist |> hd == 45 and # -
      Enum.all?(x |> String.to_charlist |> tl, fn(y) -> y >= 48 and y <= 57 end) -> true
      true -> false
    end
  end

  def is_float_str(x) do
    y = String.split(x,".")
    z = String.split(x,"e")
    cond do
      length(y) == 1 and length(z) == 1 -> false
      length(y) == 2 and is_integer_str(hd(y)) and is_integer_str(hd(tl(y))) -> true
      length(z) == 2 and is_float_str(hd(z)) and is_integer_str(hd(tl(z))) -> true
      true -> false
    end
  end

end
