#----------------print------------
defmodule Print do
  def print(x) do
    print1(x)
    IO.puts("")
  end

  defp print1(x) when is_number(x) do
    IO.write(x)
  end
  defp print1(x) when is_atom(x) do
    cond do
      x == :t -> IO.write("T")
      x == nil -> IO.write("F")
      true -> IO.write(x)
    end
  end
  defp print1(x) when is_list(x) do
    print_list(x)
  end
  defp print1(x) when is_tuple(x) do
    if elem(x,0) == :func do
      IO.write("function")
    else
      :io.write(x)
    end
  end
  defp print1(x) when is_binary(x) do
    IO.write("\"")
    IO.write(x)
    IO.write("\"")
  end

  defp print_list([]) do
    IO.write("nil")
  end
  defp print_list([x|xs]) do
    IO.write("(")
    print1(x)
    if xs != [] and xs != nil do
      IO.write(" ")
    end
    print_list1(xs)
  end

  defp print_list1(x) when is_atom(x) do
    if x != nil do
      IO.write(". ")
      IO.write(x)
      IO.write(")")
    else
      IO.write(")")
    end
  end
  defp print_list1(x) when is_number(x) do
    IO.write(". ")
    IO.write(x)
    IO.write(")")
  end
  defp print_list1([]) do
    IO.write(")")
  end
  defp print_list1([x|xs]) do
    :io.write(x)
    if xs != [] and xs != nil do
      IO.write(" ")
    end
    print_list1(xs)
  end
end
