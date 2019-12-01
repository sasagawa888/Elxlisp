# Elxlisp
Lisp 1.5 M-expression.
Also S-expression is available with invoke option.

## Installation
make clone from GitHub

## invoke
- mix elxlisp  (sequential and M-expression)
- mix elxlisp seq (sequential and M-expression)
- mix elxlisp para (parallel and M-expression)
- mix elxlisp sexp (sequential and S-expression)
- mix elxlisp mexp (sequential and M-expression)

## example
```elixir
mix elxlisp
Lisp 1.5 in Elixir M-expression in sequential
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

## environment is association list
```elixir
Lisp 1.5 in Elixir M-expression in sequential
? eval[(cons x y);((x . 1)(y . 2))]
(1 . 2)
?
```

## parallel
When invoke in parallel, evlis function run in parallel.
Fibonacci run faster in parallel. See test.meta

## compiler

```elixir
Lisp 1.5 in Elixir M-expression in sequential
? compile["test.meta"]
ok
? load["test.o"]
T
? time[fib[30]]
"time: 23140 micro second"
"-------------"
832040
? time[tarai[12;6;0]]
"time: 105260 micro second"
"-------------"
12
? time[ack[3;9]]
"time: 98380 micro second"
"-------------"
4093
?
```

## data type
- integer
- float
- string
- symbol
- list


## special form
- cond      
[p1->e1;p2->e2...]
- if
- defun    
foo[x] = boo[x]      
- setq
- quote
- lambda
- function
- time  print execute time (micro second)

## primitive
- car
- cdr
- cons
- plus
- difference
- times
- quotient
- recip
- remainder
- divide
- expt
- add1
- sub1
- null
- length
- operate
- eq
- equal
- greaterp
- eqgreaterp
- lessp
- eqlessp
- max
- min
- logor
- logand
- leftshift
- numberp
- floatp
- onep
- zerop
- minusp
- listp
- symbolp
- read
- eval
- apply
- print
- prin1
- putprop
- get
- set
- quit
- reverse
- member
- append
- mapcar
- maplist
- and
- or
- load
if extension of file is  "meta" then load file as M-expression.
if extension of file is  "lsp" then load file as S-expression.
if extension of file is  "o" then load file as compiled code.
- compile  compile file and generate file with extension "o"
- trace
- untrace

## Acknowledgment

special thanks Dr. John McCarthy

## Reference document
[Lisp 1.5 programmer's manual](http://www.softwarepreservation.org/projects/LISP/book/LISP%201.5%20Programmers%20Manual.pdf)
