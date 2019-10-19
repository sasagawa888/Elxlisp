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
end

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
    {[String.to_atom(x)|s],rest}
  end
  def read([x|xs]) do
    cond do
      is_integer_str(x) -> {String.to_integer(x),xs}
      is_float_str(x) -> {String.to_float(x),xs}
      x == "nil" -> {nil,xs}
      is_upper_str(x) -> {[:quote,String.to_atom(x)],xs}
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

  def is_upper_str(x) do
    Enum.all?(String.to_charlist(x),fn(y)-> y >= 65 && y <= 90 end)
  end

end

  #----------------eval-------------
defmodule Eval do
  @moduledoc """
  Evaluate S expression
  Return value is tuple. {val,env}
  ## example
  iex>Eval.eval(:t,[])
  {:t,[]}
  iex>Eval.eval(nil,[])
  {nil,[]}
  iex>Eval.eval(1,[])
  {1,[]}
  iex>Eval.eval(:a,[{:a,1}])
  {1,[{:a,1}]}
  """
  def eval(:t,env) do
    {:t,env}
  end
  def eval(nil,env) do
    {nil,env}
  end
  def eval([],env) do
    {nil,env}
  end
  def eval(x,env) when is_atom(x) do
    s = env[x]
    {s,env}
  end
  def eval(x,env) when is_number(x) do
    {x,env}
  end
  def eval([:quote,x],env) do
    {x,env}
  end
  def eval([:defun,name,arg,body],env) do
    env1 = [{name,{:func,arg,body}}|env]
    {name,env1}
  end
  def eval([:setq,name,arg],env) do
    {s,_} = eval(arg,env)
    env1 = [{name,s}|env]
    {s,env1}
  end
  def eval([:if,x,y,z],env) do
    {x1,_} = eval(x,env)
    if x1 != nil do
      eval(y,env)
    else
      eval(z,env)
    end
  end
  def eval(x,env) when is_list(x) do
    {funcall(x,env),env}
  end

  defp funcall([:car,arg],env) do
    {[s|_],_} = eval(arg,env)
    s
  end
  defp funcall([:cdr,arg],env) do
    {[_|s],_} = eval(arg,env)
    s
  end
  defp funcall([:cons,x,y],env) do
    {s1,_} = eval(x,env)
    {s2,_} = eval(y,env)
    [s1|s2]
  end
  defp funcall([:+|args],env) do
    args |> funarg(env) |> plus
  end
  defp funcall([:-|args],env) do
    args |> funarg(env) |> minus
  end
  defp funcall([:*|args],env) do
    args |> funarg(env) |> mult
  end
  defp funcall([:/|args],env) do
    args |> funarg(env) |> divide
  end
  defp funcall([:null,arg],env) do
    {s,_} = eval(arg,env)
    if s == nil do
      :t
    else
      nil
    end
  end
  defp funcall([:atom,arg],env) do
    {s,_} = eval(arg,env)
    if is_atom(s) || is_number(s) do
      :t
    else
      nil
    end
  end
  defp funcall([:eq,x,y],env) do
    {x1,_} = eval(x,env)
    {y1,_} = eval(y,env)
    if x1 == y1 do
      :t
    else
      nil
    end
  end
  defp funcall([:=,x,y],env) do
    {x1,_} = eval(x,env)
    {y1,_} = eval(y,env)
    if !is_number(x1) || !is_number(y1) do
      throw "Error: Not number ="
    end
    if x1 == y1 do
      :t
    else
      nil
    end
  end
  defp funcall([:>,x,y],env) do
    {x1,_} = eval(x,env)
    {y1,_} = eval(y,env)
    if !is_number(x1) || !is_number(y1) do
      throw "Error: Not number >"
    end
    if x1 > y1 do
      :t
    else
      nil
    end
  end
  defp funcall([:<,x,y],env) do
    {x1,_} = eval(x,env)
    {y1,_} = eval(y,env)
    if !is_number(x1) || !is_number(y1) do
      throw "Error: Not number <"
    end
    if x1 < y1 do
      :t
    else
      nil
    end
  end
  defp funcall([:<=,x,y],env) do
    {x1,_} = eval(x,env)
    {y1,_} = eval(y,env)
    if !is_number(x1) || !is_number(y1) do
      throw "Error: Not number <="
    end
    if x1 <= y1 do
      :t
    else
      nil
    end
  end
  defp funcall([:>=,x,y],env) do
    {x1,_} = eval(x,env)
    {y1,_} = eval(y,env)
    if !is_number(x1) || !is_number(y1) do
      throw "Error: Not number >="
    end
    if x1 >= y1 do
      :t
    else
      nil
    end
  end
  defp funcall([:numberp,arg],env) do
    {s,_} = eval(arg,env)
    if is_number(s) do
      :t
    else
      nil
    end
  end
  defp funcall([:listp,arg],env) do
    {s,_} = eval(arg,env)
    if is_list(s) do
      :t
    else
      nil
    end
  end
  defp funcall([:symbolp,arg],env) do
    {s,_} = eval(arg,env)
    if is_atom(s) do
      :t
    else
      nil
    end
  end
  defp funcall([:read],_) do
    {s,_} = Read.read([])
    s
  end
  defp funcall([:eval,x],env) do
    {s,_} = eval(x,env)
    s
  end
  defp funcall([:print,x],env) do
    {x1,_} = eval(x,env)
    Print.print(x1)
  end
  defp funcall([:quit],_) do
    throw "goodbye"
  end
  defp funcall([name|args],env) do
    try do
      {:func,args1,body} = env[name]
      env1 = bindenv(args1,args,env)
      {s,_} = eval(body,env1)
      s
    rescue
      _ -> throw "Error: Not exist function #{name}"
    end
  end


  defp funarg([],_) do [] end
  defp funarg([x|xs],env) do
    {s,env} = eval(x,env)
    [s|funarg(xs,env)]
  end

  defp bindenv([],[],env) do env end
  defp bindenv([x|xs],[y|ys],env) do
    {y1,_} = eval(y,env)
    [{x,y1}|bindenv(xs,ys,env)]
  end

  #----------subr---------------
  defp plus([]) do 0 end
  defp plus([x|xs]) do
    if !is_number(x) do
      throw "Error: Not number +"
    end
    x + plus(xs)
  end

  defp minus([x|xs]) do
    if !is_number(x) do
      throw "Error: Not number -"
    end
    x - plus(xs)
  end

  defp mult([]) do 1 end
  defp mult([x|xs]) do
    if !is_number(x) do
      throw "Error: Not number *"
    end
    x * mult(xs)
  end

  defp divide([x|xs]) do
    if !is_number(x) do
      throw "Error: Not number /"
    end
    y = mult(xs)
    if y == 0 do
      throw "Error: Divide by zero /"
    end
    x / y
  end
end

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
