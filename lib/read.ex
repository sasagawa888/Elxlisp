defmodule Read do
  @moduledoc """
  Read M expression and translate to list of Elixir
  The M expression is already tokenized to list/ e.g. ["+","1","2"]
  """
  def read([], :stdin) do
    buf = IO.gets("") |> tokenize
    read(buf, :stdin)
  end

  def read([], :filein) do
    []
  end

  def read(["(" | xs], stream) do
    {s, rest} = read_list(xs, [], stream)
    {[:quote, s], rest}
  end

  def read(["lambda", "[" | xs], stream) do
    {s, rest} = read_bracket(xs, [], stream)
    {s1, rest1} = read(rest, stream)
    {[:lambda, s, s1], rest1}
  end

  def read([x, "[" | xs], stream) do
    {s, rest} = read_bracket(xs, [], stream)

    if Enum.at(rest, 0) != "=" do
      {[String.to_atom(x) | s], rest}
    else
      {s1, rest1} = read(Enum.drop(rest, 1), stream)
      {[:defun, String.to_atom(x), s, s1], rest1}
    end
  end

  def read(["[" | xs], stream) do
    {s, rest} = read_bracket(xs, [], stream)

    if rem(length(s), 2) != 0 do
      Elxlisp.error("illegal cond clause", s)
    end

    {[:cond | Enum.chunk_every(s, 2)], rest}
  end

  def read([x | xs], _) do
    cond do
      is_integer_str(x) -> {String.to_integer(x), xs}
      is_float_str(x) -> {String.to_float(x), xs}
      is_string_str(x) -> {string_str_to_string(x), xs}
      x == "nil" -> {[], xs}
      x == "NIL" -> {[], xs}
      x == "F" -> {nil, xs}
      true -> {String.to_atom(x), xs}
    end
  end

  defp read_list([], ls, :stdin) do
    buf = IO.gets("") |> tokenize
    read_list(buf, ls, :stdin)
  end

  defp read_list([], _, :filein) do
    Elxlisp.error("illegal list form", nil)
  end

  defp read_list([")" | xs], ls, _) do
    {ls, xs}
  end

  defp read_list(["(" | xs], ls, stream) do
    {s, rest} = read_list(xs, [], stream)
    read_list(rest, ls ++ [s], stream)
  end

  defp read_list(["." | xs], ls, stream) do
    {s, rest} = read_list(xs, [], stream)

    if length(s) == 1 do
      {[hd(ls) | hd(s)], rest}
    else
      {ls ++ s, rest}
    end
  end

  defp read_list(x, ls, stream) do
    {s, rest} = read(x, stream)
    read_list(rest, ls ++ [s], stream)
  end

  defp read_bracket([], ls, :stdin) do
    buf = IO.gets("") |> tokenize
    read_bracket(buf, ls, :stdin)
  end

  defp read_bracket([], _, :filein) do
    Elxlisp.error("illegal bracket form", nil)
  end

  defp read_bracket(["]" | xs], ls, _) do
    {ls, xs}
  end

  defp read_bracket(["," | _], _, _) do
    Elxlisp.error("illegal bracket form , change to ;", nil)
  end

  defp read_bracket(x, ls, stream) do
    {s, rest} = read(x, stream)
    read_bracket(rest, ls ++ [s], stream)
  end

  # read for S-exp
  def sread([], :stdin) do
    buf = IO.gets("") |> stokenize
    sread(buf, :stdin)
  end

  def sread([], :filein) do
    []
  end

  def sread(["(" | xs], stream) do
    {s, rest} = sread_list(xs, [], stream)
    {s, rest}
  end

  def sread(["'" | xs], stream) do
    {s, rest} = sread(xs, stream)
    {[:quote, s], rest}
  end

  def sread([x | xs], _) do
    cond do
      is_integer_str(x) -> {String.to_integer(x), xs}
      is_float_str(x) -> {String.to_float(x), xs}
      is_string_str(x) -> {string_str_to_string(x), xs}
      x == "nil" -> {[], xs}
      x == "NIL" -> {[], xs}
      x == "F" -> {nil, xs}
      true -> {String.to_atom(x), xs}
    end
  end

  defp sread_list([], ls, :stdin) do
    buf = IO.gets("") |> stokenize
    sread_list(buf, ls, :stdin)
  end

  defp sread_list([], _, :filein) do
    Elxlisp.error("illegal list form", nil)
  end

  defp sread_list([")" | xs], ls, _) do
    {ls, xs}
  end

  defp sread_list(["(" | xs], ls, stream) do
    {s, rest} = sread_list(xs, [], stream)
    sread_list(rest, ls ++ [s], stream)
  end

  defp sread_list(["." | xs], ls, stream) do
    {s, rest} = sread_list(xs, [], stream)

    if length(s) == 1 do
      {[hd(ls) | hd(s)], rest}
    else
      {ls ++ s, rest}
    end
  end

  defp sread_list(x, ls, stream) do
    {s, rest} = sread(x, stream)
    sread_list(rest, ls ++ [s], stream)
  end

  @doc """
  ## example
  iex>Read.tokenize("(+ 1 2)")
  ["(","+","1","2",")"]
  """
  def tokenize(str) do
    str
    |> String.replace("(", " ( ")
    |> String.replace(")", " ) ")
    |> String.replace("[", " [ ")
    |> String.replace("]", " ] ")
    |> String.replace(";", " ")
    |> String.replace("->", " ")
    |> String.replace("=", " = ")
    |> String.replace("\n", " ")
    |> String.replace(",", " , ")
    |> String.split()
  end

  # tokenizer for S-exp
  def stokenize(str) do
    str
    |> String.replace("(", " ( ")
    |> String.replace(")", " ) ")
    |> String.replace("'", " ' ")
    |> String.replace("\n", " ")
    |> String.split()
  end

  def is_integer_str(x) do
    cond do
      x == "" ->
        false

      # 123
      Enum.all?(x |> String.to_charlist(), fn y -> y >= 48 and y <= 57 end) ->
        true

      # +123
      # +
      String.length(x) >= 2 and
        x |> String.to_charlist() |> hd == 43 and
          Enum.all?(x |> String.to_charlist() |> tl, fn y -> y >= 48 and y <= 57 end) ->
        true

      # -123
      # -
      String.length(x) >= 2 and
        x |> String.to_charlist() |> hd == 45 and
          Enum.all?(x |> String.to_charlist() |> tl, fn y -> y >= 48 and y <= 57 end) ->
        true

      true ->
        false
    end
  end

  def is_float_str(x) do
    y = String.split(x, ".")
    z = String.split(x, "e")
    z1 = String.split(x, "E")

    cond do
      length(y) == 1 and length(z) == 1 -> false
      length(y) == 2 and is_integer_str(hd(y)) and is_integer_str(hd(tl(y))) -> true
      length(z) == 2 and is_float_str(hd(z)) and is_integer_str(hd(tl(z))) -> true
      length(z1) == 2 and is_float_str(hd(z1)) and is_integer_str(hd(tl(z1))) -> true
      true -> false
    end
  end

  def is_string_str(x) do
    String.first(x) == "\"" and String.last(x) == "\""
  end

  def string_str_to_string(x) do
    String.slice(x, 1..(String.length(x) - 2))
  end
end
