
  #----------------eval-------------
defmodule Eval do
  use Bitwise
  @moduledoc """
  Evaluate M expression
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
    {[],env}
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
  def eval(x,env) when is_binary(x) do
    {x,env}
  end
  def eval(x,env) when is_tuple(x) do
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
  def eval([:set,name,arg],env) do
    {name1,_} = eval(name,env)
    {s,_} = eval(arg,env)
    env1 = [{name1,s}|env]
    {s,env1}
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
  def eval([:lambda,args,body],_) do
    {:func,args,body}
  end
  def eval([:function,[:lambda,args,body]],env) do
    {:funarg,args,body,env}
  end
  def eval([:load,x],env) do
    {x1,_} = eval(x,env)
    {status,string} = File.read(x1)
    if status == :error do
      throw "Error load"
    end
    env1 = load(env,Read.tokenize(string))
    {:t,env1}
  end
  def eval(x,env) when is_list(x) do
    {funcall(x,env),env}
  end

  #-----------apply--------------------------
  defp funcall([name|args],env) when is_atom(name) do
    if is_subr(name) do
      primitive([name|args],env)
    else
      expr = env[name]
      if expr == nil do
        Elxlisp.error("Not exist function error",name)
      end
      {:func,args1,body} = env[name]
      env1 = bindenv(args1,args,env)
      {s,_} = eval(body,env1)
      s
    end
  end
  defp funcall([f|args],env) when is_list(f) do
    if Enum.at(f,0) == :lambda do
        {:func,args1,body} = eval(f,env)
        env1 = bindenv(args1,args,env)
        {s,_} = eval(body,env1)
        s
    else if Enum.at(f,0) == :function do
        {:funarg,args1,body,env2} = eval(f,env)
        env1 = bindenv(args1,args,env)
        {s,_} = eval(body,env1++env2)
        s
    end
    end
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

  # environment is keyword-list e.g. [{x 1}{y 2}]
  defp bindenv([],[],env) do env end
  defp bindenv([x|xs],[y|ys],env) do
    {y1,_} = eval(y,env)
    [{x,y1}|bindenv(xs,ys,env)]
  end

  def is_upper_atom(x) do
    Enum.all?(Atom.to_charlist(x),fn(y) -> y >= 65 && y <= 90 end)
  end

  #---------SUBR==================
  defp primitive([:car,arg],env) do
    {s,_} = eval(arg,env)
    if !is_list(s) do
      Elxlisp.error("car not list",s)
    end
    [s1|_] = s
    s1
  end
  defp primitive([:car|arg],_) do
    Elxlisp.error("car argument error",arg)
  end
  defp primitive([:caar,arg],env) do
    {s,_} = eval(arg,env)
    if !is_list(s) or !is_list(hd(s)) do
      Elxlisp.error("caar not list",s)
    end
    [[s1|_]|_] = s
    s1
  end
  defp primitive([:caar|arg],_) do
    Elxlisp.error("caar argument error",arg)
  end
  defp primitive([:cdr,arg],env) do
    {s,_} = eval(arg,env)
    if !is_list(s) do
      Elxlisp.error("cdr not list",s)
    end
    [_|s1] = s
    s1
  end
  defp primitive([:cdr|arg],_) do
    Elxlisp.error("cdr argument error",arg)
  end
  defp primitive([:cons,x,y],env) do
    {s1,_} = eval(x,env)
    {s2,_} = eval(y,env)
    [s1|s2]
  end
  defp primitive([:cons|arg],_) do
    Elxlisp.error("cons argument error",arg)
  end
  defp primitive([:plus|args],env) do
    args1 = args |> evlis(env)
    if Enum.any?(args1,fn(x) -> !is_number(x) end) do
      Elxlisp.error("plus not number",args1)
    end
    args1 |> plus()
  end
  defp primitive([:difference,x,y],env) do
    {x1,_} = eval(x,env)
    {y1,_} = eval(y,env)
    if !is_number(x1) do
      Elxlisp.error("difference not number",x1)
    end
    if !is_number(y1) do
      Elxlisp.error("difference not number",y1)
    end
    x1 - y1
  end
  defp primitive([:difference|arg],_) do
    Elxlisp.error("difference argument error",arg)
  end
  defp primitive([:times|args],env) do
    args1 = args |> evlis(env)
    if Enum.any?(args1,fn(x) -> !is_number(x) end) do
      Elxlisp.error("times not number",args1)
    end
    args1 |> times()
  end
  defp primitive([:quotient,x,y],env) do
    {x1,_} = eval(x,env)
    {y1,_} = eval(y,env)
    if !is_number(x1) do
      Elxlisp.error("quotient not number",x1)
    end
    if !is_number(y1) do
      Elxlisp.error("quotient not number",y1)
    end
    div(x1,y1)
  end
  defp primitive([:quotient|arg],_) do
    Elxlisp.error("quotient argument error",arg)
  end
  defp primitive([:recip,x],env) do
    {x1,_} = eval(x,env)
    if !is_number(x1) do
      Elxlisp.error("difference not number",x1)
    end
    1 / x1
  end
  defp primitive([:recip|arg],_) do
    Elxlisp.error("recip argument error",arg)
  end
  defp primitive([:remainder,x,y],env) do
    {x1,_} = eval(x,env)
    {y1,_} = eval(y,env)
    if !is_number(x1) do
      Elxlisp.error("remainder not number",x1)
    end
    if !is_number(y1) do
      Elxlisp.error("remainder not number",y1)
    end
    rem(x1,y1)
  end
  defp primitive([:remainder|arg],_) do
    Elxlisp.error("remainder argument error",arg)
  end
  defp primitive([:divide,x,y],env) do
    {x1,_} = eval(x,env)
    {y1,_} = eval(y,env)
    if !is_number(x1) do
      Elxlisp.error("divide not number",x1)
    end
    if !is_number(y1) do
      Elxlisp.error("divide not number",y1)
    end
    [div(x1,y1),rem(x1,y1)]
  end
  defp primitive([:divide|arg],_) do
    Elxlisp.error("divide argument error",arg)
  end
  defp primitive([:expt,x,y],env) do
    {x1,_} = eval(x,env)
    {y1,_} = eval(y,env)
    if !is_number(x1) do
      Elxlisp.error("expt not number",x1)
    end
    if !is_number(y1) do
      Elxlisp.error("expt not number",y1)
    end
    :math.pow(x1,y1)
  end
  defp primitive([:expt|arg],_) do
    Elxlisp.error("expt argument error",arg)
  end
  defp primitive([:add1,x],env) do
    {x1,_} = eval(x,env)
    if !is_number(x1) do
      Elxlisp.error("add1 not number",x1)
    end
    x1 + 1
  end
  defp primitive([:add1|arg],_) do
    Elxlisp.error("add1 argument error",arg)
  end
  defp primitive([:sub1,x],env) do
    {x1,_} = eval(x,env)
    if !is_number(x1) do
      Elxlisp.error("sub1 not number",x1)
    end
    x1 - 1
  end
  defp primitive([:sub1|arg],_) do
    Elxlisp.error("sub1 argument error",arg)
  end
  defp primitive([:null,arg],env) do
    {s,_} = eval(arg,env)
    if s == nil or s == [] do
      :t
    else
      nil
    end
  end
  defp primitive([:null|arg],_) do
    Elxlisp.error("null argument error",arg)
  end
  defp primitive([:length,arg],env) do
    {s,_} = eval(arg,env)
    if !is_list(s) do
      Elxlisp.error("list not list",s)
    end
    length(s)
  end
  defp primitive([:length|arg],_) do
    Elxlisp.error("length argument error",arg)
  end
  defp primitive([:operate,op,x,y],env) do
    {x1,_} = eval(x,env)
    {y1,_} = eval(y,env)
    if !is_number(x1) do
      Elxlisp.error("operate not number",x1)
    end
    if !is_number(y1) do
      Elxlisp.error("operate not number",y1)
    end
    cond do
      op == :+ -> x1+y1
      op == :- -> x1-y1
      op == :x -> x1*y1
      op == :/ -> x1/y1
    end
  end
  defp primitive([:operate|arg],_) do
    Elxlisp.error("operate argument error",arg)
  end
  defp primitive([:atom,arg],env) do
    {s,_} = eval(arg,env)
    if is_atom(s) || is_number(s) do
      :t
    else
      nil
    end
  end
  defp primitive([:eq,x,y],env) do
    {x1,_} = eval(x,env)
    {y1,_} = eval(y,env)
    if x1 == y1 do
      :t
    else
      nil
    end
  end
  defp primitive([:eq|arg],_) do
    Elxlisp.error("eq argument error",arg)
  end
  defp primitive([:equal,x,y],env) do
    {x1,_} = eval(x,env)
    {y1,_} = eval(y,env)
    if x1 == y1 do
      :t
    else
      nil
    end
  end
  defp primitive([:equql|arg],_) do
    Elxlisp.error("equal argument error",arg)
  end
  defp primitive([:greaterp,x,y],env) do
    {x1,_} = eval(x,env)
    {y1,_} = eval(y,env)
    if !is_number(x1) do
      Elxlisp.error("greaterp not number",x1)
    end
    if !is_number(y1) do
      Elxlisp.error("greaterp not number",y1)
    end
    if x1 > y1 do
      :t
    else
      nil
    end
  end
  defp primitive([:greaterp|arg],_) do
    Elxlisp.error("greaterp argument error",arg)
  end
  defp primitive([:lessp,x,y],env) do
    {x1,_} = eval(x,env)
    {y1,_} = eval(y,env)
    if !is_number(x1) do
      Elxlisp.error("lessp not number",x1)
    end
    if !is_number(y1) do
      Elxlisp.error("lessp not number",y1)
    end
    if x1 < y1 do
      :t
    else
      nil
    end
  end
  defp primitive([:lessp|arg],_) do
    Elxlisp.error("lessp argument error",arg)
  end
  defp primitive([:max|arg],env) do
    arg1 = evlis(arg,env)
    if !Enum.all?(arg1,fn(x) -> is_number(x) end) do
      Elxlisp.error("max not number",arg1)
    end
    Enum.max(arg1)
  end
  defp primitive([:min|arg],env) do
    arg1 = evlis(arg,env)
    if !Enum.all?(arg1,fn(x) -> is_number(x) end) do
      Elxlisp.error("min not number",arg1)
    end
    Enum.min(arg1)
  end
  defp primitive([:logor|arg],env) do
    arg1 = arg |> evlis(env)
    if !Enum.all?(arg1,fn(x) -> is_integer(x) end) do
      Elxlisp.error("logor not number",arg1)
    end
    arg1 |> logor
  end
  defp primitive([:logand|arg],env) do
    arg1 = arg |> evlis(env)
    if !Enum.all?(arg1,fn(x) -> is_integer(x) end) do
      Elxlisp.error("logand not number",arg1)
    end
    arg1 |> logand
  end
  defp primitive([:logxor|arg],env) do
    arg1 = arg |> evlis(env)
    if !Enum.all?(arg1,fn(x) -> is_integer(x) end) do
      Elxlisp.error("logxor not number",arg1)
    end
    arg1 |> logxor
  end
  defp primitive([:leftshift,x,n],env) do
    {x1,_} = eval(x,env)
    {n1,_} = eval(n,env)
    if !is_integer(x1) do
      Elxlisp.error("lessp not number",x1)
    end
    if !is_integer(n1) do
      Elxlisp.error("lessp not number",n1)
    end
    leftshift(x1,n1)
  end
  defp primitive([:leftshift|arg],_) do
    Elxlisp.error("leftshift argument error",arg)
  end
  defp primitive([:numberp,arg],env) do
    {s,_} = eval(arg,env)
    if is_number(s) do
      :t
    else
      nil
    end
  end
  defp primitive([:numberp|arg],_) do
    Elxlisp.error("numberp argument error",arg)
  end
  defp primitive([:floatp,arg],env) do
    {s,_} = eval(arg,env)
    if is_float(s) do
      :t
    else
      nil
    end
  end
  defp primitive([:floatp|arg],_) do
    Elxlisp.error("floatp argument error",arg)
  end
  defp primitive([:zerop,arg],env) do
    {s,_} = eval(arg,env)
    if s == 0 do
      :t
    else
      nil
    end
  end
  defp primitive([:zerop|arg],_) do
    Elxlisp.error("zerop argument error",arg)
  end
  defp primitive([:minusp,arg],env) do
    {s,_} = eval(arg,env)
    if s < 0 do
      :t
    else
      nil
    end
  end
  defp primitive([:minusp|arg],_) do
    Elxlisp.error("zerop argument error",arg)
  end
  defp primitive([:onep,arg],env) do
    {s,_} = eval(arg,env)
    if s == 1 do
      :t
    else
      nil
    end
  end
  defp primitive([:onep|arg],_) do
    Elxlisp.error("onep argument error",arg)
  end
  defp primitive([:listp,arg],env) do
    {s,_} = eval(arg,env)
    if is_list(s) do
      :t
    else
      nil
    end
  end
  defp primitive([:listp|arg],_) do
    Elxlisp.error("listp argument error",arg)
  end
  defp primitive([:symbolp,arg],env) do
    {s,_} = eval(arg,env)
    if is_atom(s) do
      :t
    else
      nil
    end
  end
  defp primitive([:symbolp|arg],_) do
    Elxlisp.error("symbolp argument error",arg)
  end
  defp primitive([:read],_) do
    {s,_} = Read.read([],:stdin)
    s
  end
  defp primitive([:eval,x,nil],_) do
    {s,_} = eval(x,nil)
    s
  end
  defp primitive([:eval,x,[:quote,y]],_) do
    {s,_} = eval(x,y)
    s
  end
  defp primitive([:eval|arg],_) do
    Elxlisp.error("eval argument error",arg)
  end
  defp primitive([:apply,f,a,e],env) do
    funcall([f|a],env++e)
  end
  defp primitive([:apply|arg],_) do
    Elxlisp.error("apply argument error",arg)
  end
  defp primitive([:print,x],env) do
    {x1,_} = eval(x,env)
    Print.print(x1)
  end
  defp primitive([:print|arg],_) do
    Elxlisp.error("print argument error",arg)
  end
  defp primitive([:quit],_) do
    throw "goodbye"
  end
  defp primitive([:quit|arg],_) do
    Elxlisp.error("quit argument error",arg)
  end
  defp primitive([:rev,[:quote,x]],_) do
    Enum.reverse(x)
  end
  defp primitive([:rev|arg],_) do
    Elxlisp.error("rev argument error",arg)
  end
  defp primitive([:and|args],env) do
    args1 = evlis(args,env)
    if Enum.all?(args1,fn(x) -> x != nil end) do
      :t
    else
      nil
    end
  end
  defp primitive([:or|args],env) do
    args1 = evlis(args,env)
    if Enum.any?(args1,fn(x) -> x != nil end) do
      :t
    else
      nil
    end
  end

  #----------subr---------------
  defp load(env,[]) do env end
  defp load(env,buf) do
    {s,buf1} = Read.read(buf,:filein)
    {_,env1} = Eval.eval(s,env)
    load(env1,buf1)
  end

  defp plus([]) do 0 end
  defp plus([x|xs]) do
    if !is_number(x) do
      throw "Error: Not number +"
    end
    x + plus(xs)
  end

  defp times([]) do 1 end
  defp times([x|xs]) do
    if !is_number(x) do
      throw "Error: Not number *"
    end
    x * times(xs)
  end

  defp logor([x,y]) do
    bor(x,y)
  end
  defp logor([x|xs]) do
    bor(x,logor(xs))
  end

  defp logand([x,y]) do
    band(x,y)
  end
  defp logand([x|xs]) do
    band(x,logand(xs))
  end

  defp logxor([x,y]) do
    bxor(x,y)
  end
  defp logxor([x|xs]) do
    bxor(x,logxor(xs))
  end

  defp leftshift(x,0) do x end
  defp leftshift(x,n) when n > 0 do
    x <<< n
  end
  defp leftshift(x,n) when n < 0 do
    x >>> n
  end

  defp is_subr(x) do
    y = [:car,:caar,:cdr,:cons,:plus,:difference,:times,:quotient,:recip,
         :remainder,:divide,:expt,:add1,:sub1,:null,:length,:operate,
         :eq,:equal,:greaterp,:lessp,:max,:min,:logor,:logand,:leftshift,
         :numberp,:floatp,:onep,:zerop,:minusp,:listp,:symbolp,:read,:atom,
         :eval,:apply,:print,:quit,:rev,:and,:or,:load]
    Enum.member?(y,x)
  end


end
