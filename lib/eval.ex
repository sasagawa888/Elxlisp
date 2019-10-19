
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
  def eval(:T,env) do
    {:t,env}
  end
  def eval(nil,env) do
    {nil,env}
  end
  def eval(:NIL,env) do
    {nil,env}
  end
  def eval([],env) do
    {nil,env}
  end
  def eval(x,env) when is_atom(x) do
    if is_upper_atom(x) do
      {x,env}
    else
      s = env[x]
      {s,env}
    end
  end
  def eval(x,env) when is_number(x) do
    {x,env}
  end
  def eval([:quote,x],env) do
    {x,env}
  end
  def eval([:define,left,right],env) do
    [name|arg] = left
    env1 = [{name,{:func,arg,right}}|env]
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
  def eval([:cond,arg],env) do
    evcond(arg,env)
  end
  def eval([:prog,arg|body],env) do
    env1 = bindenv(arg,make_nil(arg),env)
    evprog(body,env1)
  end
  def eval(x,env) when is_list(x) do
    {funcall(x,env),env}
  end

  defp evcond([],_) do nil end
  defp evcond([[p,e]|rest],env) do
    {s,_} = eval(p,env)
    if s != nil do
      eval(e,env)
    else
      evcond(rest,env)
    end
  end

  defp evprog([x],env) do
    eval(x,env)
  end
  defp evprog([x|xs],env) do
    {_,env1} = eval(x,env)
    evprog(xs,env1)
  end

  defp make_nil([]) do [] end
  defp make_nil([_|xs]) do
    [nil|make_nil(xs)]
  end


  defp evlis([],_) do [] end
  defp evlis([x|xs],env) do
    {s,env} = eval(x,env)
    [s|evlis(xs,env)]
  end

  defp bindenv([],[],env) do env end
  defp bindenv([x|xs],[y|ys],env) do
    {y1,_} = eval(y,env)
    [{x,y1}|bindenv(xs,ys,env)]
  end

  def is_upper_atom(x) do
    Enum.all?(Atom.to_charlist(x),fn(y) -> y >= 65 && y <= 90 end)
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
    args |> evlis(env) |> plus
  end
  defp funcall([:-|args],env) do
    args |> evlis(env) |> minus
  end
  defp funcall([:*|args],env) do
    args |> evlis(env) |> mult
  end
  defp funcall([:/|args],env) do
    args |> evlis(env) |> divide
  end
  defp funcall([:null,arg],env) do
    {s,_} = eval(arg,env)
    if s == nil do
      :t
    else
      nil
    end
  end
  defp funcall([:operate,op,x,y],env) do
    {x1,_} = eval(x,env)
    {y1,_} = eval(y,env)
    cond do
      op == :+ -> x1+y1
      op == :- -> x1-y1
      op == :x -> x1*y1
      op == :/ -> x1/y1
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
  defp funcall([:greaterp,x,y],env) do
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
  defp funcall([:lessp,x,y],env) do
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
  defp funcall([:max|arg],env) do
    arg1 = evlis(arg,env)
    if !Enum.all?(arg1,fn(x) -> is_number(x) end) do
      throw "Error: Not number max"
    else
      Enum.max(arg1)
    end
  end
  defp funcall([:min|arg],env) do
    arg1 = evlis(arg,env)
    if !Enum.all?(arg1,fn(x) -> is_number(x) end) do
      throw "Error: Not number max"
    else
      Enum.min(arg1)
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
  defp funcall([:floatp,arg],env) do
    {s,_} = eval(arg,env)
    if is_float(s) do
      :t
    else
      nil
    end
  end
  defp funcall([:zerop,arg],env) do
    {s,_} = eval(arg,env)
    if s == 0 do
      :t
    else
      nil
    end
  end
  defp funcall([:minusp,arg],env) do
    {s,_} = eval(arg,env)
    if s < 0 do
      :t
    else
      nil
    end
  end
  defp funcall([:onep,arg],env) do
    {s,_} = eval(arg,env)
    if s == 1 do
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
  defp funcall([:eval,x,y],_) do
    {s,_} = eval(x,y)
    s
  end
  defp funcall([:print,x],env) do
    {x1,_} = eval(x,env)
    Print.print(x1)
  end
  defp funcall([:quit],_) do
    throw "goodbye"
  end
  defp funcall([:lambda,args,body],_) do
    {:func,args,body}
  end
  defp funcall([:reverse,[:quote,x]],_) do
    Enum.reverse(x)
  end
  defp funcall([:pairlis,x,y,a],_) do
    Enum.zip(x,y)++a
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
