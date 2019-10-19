# Elxlisp
Lisp 1.5 M-expression. Now under construction.

**TODO**
load[filename]
and[]
or[]
maplist[]
fix float number parse
divide[]
expt[]
quotient[]
recip[]
sub1[]
add1[]
plus[]
difference[]
minus[]
times[]
equalp[]
logor[]
logend[]
logxor[]
assoc[]
sublis[]
subst[]

## Installation
make clone from GitHub

## invoke
mix elxlisp


## example
```elixir
mix elxlisp
Lisp 1.5 in Elixir
? cons[A;B]
(A . B)
? car[(A B C)]
A
? third[x]=car[cdr[cdr[x]]]
third
? third[(1 2 3)]
3
? quit[]
goodbye
```
