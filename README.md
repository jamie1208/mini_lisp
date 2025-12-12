# mini_lisp
This is my final project in compiler class.
========================================
Mini Lisp Interpreter
========================================

Author: Jamie Tsai
Student ID: xxxxxxxx
Course: Compiler Design
Semester: 113-2

----------------------------------------
1. Project Description
----------------------------------------
This project implements a Mini-Lisp interpreter using
Flex (Lex) and Bison (Yacc).

The interpreter supports:
- Integer and Boolean values
- Arithmetic operations
- Logical operations
- Variable definition
- Conditional expressions
- Function definition and function calls
- Lexical scoping (closures)

The program parses Mini-Lisp source code, builds an
Abstract Syntax Tree (AST), and evaluates it using
an environment-based interpreter.

----------------------------------------
2. Files
----------------------------------------
mini_lisp.y      : Bison grammar and semantic actions
mini_lisp.l      : Flex lexical analyzer
Makefile         : Build and run commands
README.txt       : Project description and usage
ex1.txt          : Sample input program

----------------------------------------
3. How to Compile
----------------------------------------
Make sure Flex and Bison are installed.

Compile the project by running:

    make

Or manually:

    bison -d mini_lisp.y
    flex mini_lisp.l
    gcc mini_lisp.tab.c lex.yy.c -o mini_lisp

----------------------------------------
4. How to Run
----------------------------------------
Run the interpreter with input redirected from a file:

    ./mini_lisp < ex1.txt

----------------------------------------
5. Supported Syntax and Features
----------------------------------------

5.1 Values
----------
- Integer: 10, 20, -3
- Boolean: #t, #f

5.2 Arithmetic Operations
------------------------
(+ a b ...)
(- a b)
(* a b ...)
(/ a b)
(mod a b)

Example:
(+ 1 2 3)
(* 2 3 4)

5.3 Logical Operations
---------------------
(and a b ...)
(or a b ...)
(not a)

Example:
(and #t #f)
(not #t)

5.4 Variable Definition
-----------------------
(define x 10)

Example:
(define a 5)
(print-num a)

5.5 Conditional Expression
--------------------------
(if condition then-exp else-exp)

Example:
(if (> 3 2) 10 20)

5.6 Function Definition
-----------------------
(fun (param1 param2 ...) body)

Example:
(fun (x y) (+ x y))

5.7 Function Call
-----------------
(function arg1 arg2 ...)

Example:
(define add (fun (x y) (+ x y)))
(add 3 4)

5.8 Closure Support
------------------
Functions capture the environment at definition time.

Example:
(define make-adder
  (fun (x)
    (fun (y) (+ x y))))

(define add5 (make-adder 5))
(add5 3)   ; result = 8

5.9 Print Statements
--------------------
(print-num exp)
(print-bool exp)

----------------------------------------
6. Error Handling
----------------------------------------
- Type errors are detected at runtime
- Undefined variables will produce an error message
- Function argument count mismatch will produce an error

----------------------------------------
7. Notes
----------------------------------------
- The interpreter uses lexical scoping
- Function arguments are evaluated in the caller environment
- Function bodies are evaluated in the function's closure environment

----------------------------------------
8. Sample Input
----------------------------------------
(define foo
  (fun (a b c) (+ a b (* b c))))

(print-num (foo 10 9 8))

----------------------------------------
End of README
----------------------------------------
