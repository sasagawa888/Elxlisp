# Elxlisp
Lisp 1.5 M-expression. Now under construction.

**TODO**
and[]
or[]
maplist[]
fix float number parse
assoc[]
sublis[]
subst[]
label[]

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
