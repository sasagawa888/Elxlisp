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
    if x != nil do
      IO.write(x)
    else
      IO.write("nil")
    end
  end
  defp print1(x) when is_list(x) do
    print_list(x)
  end
  defp print1(x) when is_tuple(x) do
    IO.write("function")
  end

  defp print_list([]) do
    IO.write("nil")
  end
  defp print_list([x|xs]) do
    IO.write("(")
    print1(x)
    if xs != [] do
      IO.write(" ")
    end
    print_list1(xs)
  end

  defp print_list1(x) when is_atom(x)do
    IO.write(". ")
    IO.write(x)
    IO.write(")")
  end
  defp print_list1(x) when is_number(x)do
    IO.write(". ")
    IO.write(x)
    IO.write(")")
  end
  defp print_list1([]) do
    IO.write(")")
  end
  defp print_list1([x|xs]) do
    IO.write(x)
    if xs != [] do
      IO.write(" ")
    end
    print_list1(xs)
  end
end
