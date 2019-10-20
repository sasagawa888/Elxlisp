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

## caution
environment is tuple of Elixir data type.
It can be expressed as follows:
({x 1}{y 2})   ->   [{:x,1},{:y,2}]

'''elixir
Lisp 1.5 in Elixir
? eval[cons[x;y];({x 1}{y 2})]
(1 . 2)
?
'''
