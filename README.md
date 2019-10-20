# Elxlisp
Lisp 1.5 M-expression. Now under construction.


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
? load["test.meta"]
t
? fact[10]
3628800
? intersection[(A B C);(D C A)]
(A C)
? quit[]
goodbye
```
