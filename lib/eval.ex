defmodule Worker do
  def eval do
    receive do
      {sender,{c,x,env}} -> send sender,{:answer,[c, eval1(x,env)] }
    end
  end

  def eval1(x,env) do
    {s,_} = Eval.eval(x,env,:seq)
    s
  end
end
# ----------------eval-------------
defmodule Eval do
  use Bitwise

  @moduledoc """
  Evaluate M expression
  Return value is tuple. {val,env}
  ## example
  iex>Eval.eval(:t,[],:para)
  {:t,[]}
  iex>Eval.eval(nil,[],:para)
  {nil,[]}
  iex>Eval.eval(1,[],:para)
  {1,[]}
  iex>Eval.eval(:a,[[:a|1]],:para)
  {1,[[:a|1]]}
  """
  def eval(:t, env, _) do
    {:t, env}
  end

  def eval(:T, env, _) do
    {:t, env}
  end

  def eval(nil, env, _) do
    {nil, env}
  end

  def eval(:NIL, env, _) do
    {nil, env}
  end

  def eval([], env, _) do
    {[], env}
  end

  def eval(x, env, _) when is_atom(x) do
    if is_upper_atom(x) do
      {x, env}
    else
      s = assoc(x,env)
      {s, env}
    end
  end

  def eval(x, env, _) when is_number(x) do
    {x, env}
  end

  def eval(x, env, _) when is_binary(x) do
    {x, env}
  end

  def eval(x, env, _) when is_tuple(x) do
    {x, env}
  end

  def eval([:quote, x], env, _) do
    {x, env}
  end

  def eval([:define, left, right], env, _) do
    [name | arg] = left
    env1 = [[name| {:func, arg, right}] | env]
    {name, env1}
  end

  def eval([:set, name, arg], env, mode) do
    {name1, _} = eval(name, env, mode)
    {s, _} = eval(arg, env, mode)
    env1 = [[name1|s] | env]
    {s, env1}
  end

  def eval([:setq, name, arg], env, mode) do
    {s, _} = eval(arg, env, mode)
    env1 = [[name|s] | env]
    {s, env1}
  end

  def eval([:if, x, y, z], env, mode) do
    {x1, _} = eval(x, env, mode)

    if x1 != nil do
      eval(y, env, mode)
    else
      eval(z, env, mode)
    end
  end

  def eval([:cond, arg], env, _) do
    evcond(arg, env)
  end

  def eval([:prog, arg | body], env, _) do
    env1 = pairlis(arg, make_nil(arg), env)
    evprog(body, env1)
  end

  def eval([:lambda, args, body], env, _) do
    {{:func, args, body}, env}
  end

  def eval([:function, [:lambda, args, body]], env, _) do
    {{:funarg, args, body, env}, env}
  end

  def eval([:load, x], env, mode) do
    {x1, _} = eval(x, env, mode)
    {status, string} = File.read(x1)

    if status == :error do
      throw("Error load")
    end

    env1 = load(env, Read.tokenize(string))
    {:t, env1}
  end

  def eval([:time,x], env, mode) do
    {time, {result,_}} = :timer.tc(fn() -> eval(x,env,mode) end)
    IO.inspect "time: #{time} micro second"
    IO.inspect "-------------"
    {result,env}
  end

  def eval(x, env, mode) when is_list(x) do
    [f|args] = x
    if mode == :para do
      {funcall(f, paraevlis(args,env), env), env}
    else if mode == :seq do
      {funcall(f, evlis(args,env), env), env}
    end
    end
  end

  # -----------apply--------------------------
  defp funcall(f, args, env) when is_atom(f) do
    if is_subr(f) do
      primitive([f | args])
    else
      expr = assoc(f,env)

      if expr == nil do
        Elxlisp.error("Not exist function error", f)
      end

      {:func, args1, body} = assoc(f,env)
      env1 = pairlis(args1, args, env)
      {s, _} = eval(body, env1, :seq)
      s
    end
  end

  defp funcall(f, args, env) when is_list(f) do
    if Enum.at(f, 0) == :lambda do
      {{:func, args1, body}, _} = eval(f, env, :seq)
      env1 = pairlis(args1, args, env)
      {s, _} = eval(body, env1, :seq)
      s
    else
      if Enum.at(f, 0) == :function do
        {{:funarg, args1, body, env2}, _} = eval(f, env, :seq)
        env1 = pairlis(args1, args, env)
        {s, _} = eval(body, env1 ++ env2, :seq)
        s
      end
    end
  end

  defp evcond([], _) do
    nil
  end

  defp evcond([[p, e] | rest], env) do
    {s, _} = eval(p, env, :seq)

    if s != nil do
      eval(e, env, :seq)
    else
      evcond(rest, env)
    end
  end

  defp evprog([x], env) do
    eval(x, env, :seq)
  end

  defp evprog([x | xs], env) do
    {_, env1} = eval(x, env, :seq)
    evprog(xs, env1)
  end

  defp make_nil([]) do
    []
  end

  defp make_nil([_ | xs]) do
    [nil | make_nil(xs)]
  end

  defp evlis([], _) do
    []
  end

  defp evlis([x | xs], env) do
    {s, env} = eval(x, env, :seq)
    [s | evlis(xs, env)]
  end

  # paralell evlis
  defp paraevlis(x,env) do
    x1 = paraevlis1(x,env,0)
    c = length(x) - length(x1)
    x2 = paraevlis2(c,[])
    x1++x2
    |> Enum.sort()
    |> Enum.map(fn(x) -> Enum.at(x,1) end)
  end

  defp paraevlis1([],_,_) do [] end
  defp paraevlis1([x|xs],env,c) do
    if is_fun(x) do
      pid = spawn(Worker,:eval,[])
      send pid, {self(),{c,x,env}}
      paraevlis1(xs,env,c+1)
    else
      {s,_} = eval(x,env,:seq)
      [[c,s]|paraevlis1(xs,env,c+1)]
    end
  end

  defp paraevlis2(0,res) do res end
  defp paraevlis2(c,res) do
    receive do
      {:answer,ls} ->
        paraevlis2(c-1,[ls|res])
    end
  end


  def is_upper_atom(x) do
    Enum.all?(Atom.to_charlist(x), fn y -> y >= 65 && y <= 90 end)
  end

  def assoc(_,[]) do nil end
  def assoc(x,[[x|y]|_]) do
    y
  end
  def assoc(x,[_|y]) do
    assoc(x,y)
  end
  def pairlis([],_,env) do env end
  def pairlis([x|xs],[y|ys],env) do
    [[x|y]|pairlis(xs,ys,env)]
  end

  # ---------SUBR==================
  defp primitive([:car, arg]) do
    if !is_list(arg) do
      Elxlisp.error("car not list", arg)
    end

    [s | _] = arg
    s
  end

  defp primitive([:car | arg]) do
    Elxlisp.error("car argument error", arg)
  end

  defp primitive([:caar, arg]) do
    if !is_list(arg) or !is_list(hd(arg)) do
      Elxlisp.error("caar not list", arg)
    end

    [[s | _] | _] = arg
    s
  end

  defp primitive([:caar | arg]) do
    Elxlisp.error("caar argument error", arg)
  end

  defp primitive([:cdr, arg]) do
    if !is_list(arg) do
      Elxlisp.error("cdr not list", arg)
    end

    [_ | s] = arg
    s
  end

  defp primitive([:cdr | arg]) do
    Elxlisp.error("cdr argument error", arg)
  end

  defp primitive([:cons, x, y]) do
    [x | y]
  end

  defp primitive([:cons | arg]) do
    Elxlisp.error("cons argument error", arg)
  end

  defp primitive([:plus | args]) do
    if Enum.any?(args, fn x -> !is_number(x) end) do
      Elxlisp.error("plus not number", args)
    end

    args |> plus()
  end

  defp primitive([:difference, x, y]) do
    if !is_number(x) do
      Elxlisp.error("difference not number", x)
    end

    if !is_number(y) do
      Elxlisp.error("difference not number", y)
    end

    x - y
  end

  defp primitive([:difference | arg]) do
    Elxlisp.error("difference argument error", arg)
  end

  defp primitive([:times | args]) do
    if Enum.any?(args, fn x -> !is_number(x) end) do
      Elxlisp.error("times not number", args)
    end

    args |> times()
  end

  defp primitive([:quotient, x, y]) do
    if !is_number(x) do
      Elxlisp.error("quotient not number", x)
    end

    if !is_number(y) do
      Elxlisp.error("quotient not number", y)
    end

    div(x, y)
  end

  defp primitive([:quotient | arg]) do
    Elxlisp.error("quotient argument error", arg)
  end

  defp primitive([:recip, x]) do
    if !is_number(x) do
      Elxlisp.error("difference not number", x)
    end

    1 / x
  end

  defp primitive([:recip | arg]) do
    Elxlisp.error("recip argument error", arg)
  end

  defp primitive([:remainder, x, y]) do
    if !is_number(x) do
      Elxlisp.error("remainder not number", x)
    end

    if !is_number(y) do
      Elxlisp.error("remainder not number", y)
    end

    rem(x, y)
  end

  defp primitive([:remainder | arg]) do
    Elxlisp.error("remainder argument error", arg)
  end

  defp primitive([:divide, x, y]) do
    if !is_number(x) do
      Elxlisp.error("divide not number", x)
    end

    if !is_number(y) do
      Elxlisp.error("divide not number", y)
    end

    [div(x, y), rem(x, y)]
  end

  defp primitive([:divide | arg]) do
    Elxlisp.error("divide argument error", arg)
  end

  defp primitive([:expt, x, y]) do
    if !is_number(x) do
      Elxlisp.error("expt not number", x)
    end

    if !is_number(y) do
      Elxlisp.error("expt not number", y)
    end

    :math.pow(x, y)
  end

  defp primitive([:expt | arg]) do
    Elxlisp.error("expt argument error", arg)
  end

  defp primitive([:add1, x]) do
    if !is_number(x) do
      Elxlisp.error("add1 not number", x)
    end

    x + 1
  end

  defp primitive([:add1 | arg]) do
    Elxlisp.error("add1 argument error", arg)
  end

  defp primitive([:sub1, x]) do
    if !is_number(x) do
      Elxlisp.error("sub1 not number", x)
    end

    x - 1
  end

  defp primitive([:sub1 | arg]) do
    Elxlisp.error("sub1 argument error", arg)
  end

  defp primitive([:null, arg]) do
    if arg == nil or arg == [] do
      :t
    else
      nil
    end
  end

  defp primitive([:null | arg]) do
    Elxlisp.error("null argument error", arg)
  end

  defp primitive([:length, arg]) do
    if !is_list(arg) do
      Elxlisp.error("list not list", arg)
    end

    length(arg)
  end

  defp primitive([:length | arg]) do
    Elxlisp.error("length argument error", arg)
  end

  defp primitive([:operate, op, x, y]) do
    if !is_number(x) do
      Elxlisp.error("operate not number", x)
    end

    if !is_number(y) do
      Elxlisp.error("operate not number", y)
    end

    cond do
      op == :+ -> x + y
      op == :- -> x - y
      op == :x -> x * y
      op == :/ -> x / y
    end
  end

  defp primitive([:operate | arg]) do
    Elxlisp.error("operate argument error", arg)
  end

  defp primitive([:atom, arg]) do
    if is_atom(arg) || is_number(arg) do
      :t
    else
      nil
    end
  end

  defp primitive([:eq, x, y]) do
    if x == y do
      :t
    else
      nil
    end
  end

  defp primitive([:eq | arg]) do
    Elxlisp.error("eq argument error", arg)
  end

  defp primitive([:equal, x, y]) do
    if x == y do
      :t
    else
      nil
    end
  end

  defp primitive([:equql | arg]) do
    Elxlisp.error("equal argument error", arg)
  end

  defp primitive([:greaterp, x, y]) do
    if !is_number(x) do
      Elxlisp.error("greaterp not number", x)
    end

    if !is_number(y) do
      Elxlisp.error("greaterp not number", y)
    end

    if x > y do
      :t
    else
      nil
    end
  end

  defp primitive([:greaterp | arg]) do
    Elxlisp.error("greaterp argument error", arg)
  end

  defp primitive([:lessp, x, y]) do
    if !is_number(x) do
      Elxlisp.error("lessp not number", x)
    end

    if !is_number(y) do
      Elxlisp.error("lessp not number", y)
    end

    if x < y do
      :t
    else
      nil
    end
  end

  defp primitive([:lessp | arg]) do
    Elxlisp.error("lessp argument error", arg)
  end

  defp primitive([:max | arg]) do
    if !Enum.all?(arg, fn x -> is_number(x) end) do
      Elxlisp.error("max not number", arg)
    end

    Enum.max(arg)
  end

  defp primitive([:min | arg]) do
    if !Enum.all?(arg, fn x -> is_number(x) end) do
      Elxlisp.error("min not number", arg)
    end

    Enum.min(arg)
  end

  defp primitive([:logor | arg]) do
    if !Enum.all?(arg, fn x -> is_integer(x) end) do
      Elxlisp.error("logor not number", arg)
    end

    arg |> logor
  end

  defp primitive([:logand | arg]) do
    if !Enum.all?(arg, fn x -> is_integer(x) end) do
      Elxlisp.error("logand not number", arg)
    end

    arg |> logand
  end

  defp primitive([:logxor | arg]) do
    if !Enum.all?(arg, fn x -> is_integer(x) end) do
      Elxlisp.error("logxor not number", arg)
    end

    arg |> logxor
  end

  defp primitive([:leftshift, x, n]) do
    if !is_integer(x) do
      Elxlisp.error("lessp not number", x)
    end

    if !is_integer(n) do
      Elxlisp.error("lessp not number", n)
    end

    leftshift(x, n)
  end

  defp primitive([:leftshift | arg]) do
    Elxlisp.error("leftshift argument error", arg)
  end

  defp primitive([:numberp, arg]) do
    if is_number(arg) do
      :t
    else
      nil
    end
  end

  defp primitive([:numberp | arg]) do
    Elxlisp.error("numberp argument error", arg)
  end

  defp primitive([:floatp, arg]) do
    if is_float(arg) do
      :t
    else
      nil
    end
  end

  defp primitive([:floatp | arg]) do
    Elxlisp.error("floatp argument error", arg)
  end

  defp primitive([:zerop, arg]) do
    if arg == 0 do
      :t
    else
      nil
    end
  end

  defp primitive([:zerop | arg]) do
    Elxlisp.error("zerop argument error", arg)
  end

  defp primitive([:minusp, arg]) do
    if arg < 0 do
      :t
    else
      nil
    end
  end

  defp primitive([:minusp | arg]) do
    Elxlisp.error("zerop argument error", arg)
  end

  defp primitive([:onep, arg]) do
    if arg == 1 do
      :t
    else
      nil
    end
  end

  defp primitive([:onep | arg]) do
    Elxlisp.error("onep argument error", arg)
  end

  defp primitive([:listp, arg]) do
    if is_list(arg) do
      :t
    else
      nil
    end
  end

  defp primitive([:listp | arg]) do
    Elxlisp.error("listp argument error", arg)
  end

  defp primitive([:symbolp, arg]) do
    if is_atom(arg) do
      :t
    else
      nil
    end
  end

  defp primitive([:symbolp | arg]) do
    Elxlisp.error("symbolp argument error", arg)
  end

  defp primitive([:read]) do
    {s, _} = Read.read([], :stdin)
    s
  end

  defp primitive([:eval, x, nil]) do
    {s, _} = eval(x, nil, :seq)
    s
  end

  defp primitive([:eval, x, [:quote, y]]) do
    {s, _} = eval(x, y, :seq)
    s
  end

  defp primitive([:eval | arg]) do
    Elxlisp.error("eval argument error", arg)
  end

  defp primitive([:apply, f, a, e]) do
    funcall(f, a, e)
  end

  defp primitive([:apply | arg]) do
    Elxlisp.error("apply argument error", arg)
  end

  defp primitive([:print, x]) do
    Print.print(x)
  end

  defp primitive([:print | arg]) do
    Elxlisp.error("print argument error", arg)
  end

  defp primitive([:quit]) do
    throw("goodbye")
  end

  defp primitive([:quit | arg]) do
    Elxlisp.error("quit argument error", arg)
  end

  defp primitive([:reverse, x]) do
    Enum.reverse(x)
  end

  defp primitive([:reverse | arg]) do
    Elxlisp.error("reverse argument error", arg)
  end

  defp primitive([:and | args]) do
    if Enum.all?(args, fn x -> x != nil end) do
      :t
    else
      nil
    end
  end

  defp primitive([:or | args]) do
    if Enum.any?(args, fn x -> x != nil end) do
      :t
    else
      nil
    end
  end

  defp primitive([:not, x]) do
    if x == nil do
      :t
    else
      nil
    end
  end

  defp primitive([:not | arg]) do
    Elxlisp.error("not argument error", arg)
  end

  defp primitive([:member, x, y]) do
    if !is_list(y) do
      Elxlisp.error("member not list", y)
    end

    if Enum.member?(y, x) do
      :t
    else
      nil
    end
  end

  defp primitive([:member | arg]) do
    Elxlisp.error("member argument error", arg)
  end

  # ----------subr---------------
  defp load(env, []) do
    env
  end

  defp load(env, buf) do
    {s, buf1} = Read.read(buf, :filein)
    {_, env1} = Eval.eval(s, env, :seq)
    load(env1, buf1)
  end

  defp plus([]) do
    0
  end

  defp plus([x | xs]) do
    if !is_number(x) do
      throw("Error: Not number +")
    end

    x + plus(xs)
  end

  defp times([]) do
    1
  end

  defp times([x | xs]) do
    if !is_number(x) do
      throw("Error: Not number *")
    end

    x * times(xs)
  end

  defp logor([x, y]) do
    bor(x, y)
  end

  defp logor([x | xs]) do
    bor(x, logor(xs))
  end

  defp logand([x, y]) do
    band(x, y)
  end

  defp logand([x | xs]) do
    band(x, logand(xs))
  end

  defp logxor([x, y]) do
    bxor(x, y)
  end

  defp logxor([x | xs]) do
    bxor(x, logxor(xs))
  end

  defp leftshift(x, 0) do
    x
  end

  defp leftshift(x, n) when n > 0 do
    x <<< n
  end

  defp leftshift(x, n) when n < 0 do
    x >>> n
  end

  defp is_subr(x) do
    y = [
      :car,
      :caar,
      :cdr,
      :cons,
      :plus,
      :difference,
      :times,
      :quotient,
      :recip,
      :remainder,
      :divide,
      :expt,
      :add1,
      :sub1,
      :null,
      :length,
      :operate,
      :eq,
      :equal,
      :greaterp,
      :lessp,
      :max,
      :min,
      :logor,
      :logand,
      :leftshift,
      :numberp,
      :floatp,
      :onep,
      :zerop,
      :minusp,
      :listp,
      :symbolp,
      :read,
      :atom,
      :eval,
      :apply,
      :print,
      :quit,
      :reverse,
      :and,
      :or,
      :not,
      :load,
      :member
    ]

    Enum.member?(y, x)
  end

  # user defined function
  def is_fun(x) do
    if is_list(x) and !is_subr(Enum.at(x,0)) do
      true
    else
      false
    end
  end

end
