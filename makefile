mini_lisp: y.tab.o lex.yy.o
	gcc -g -o mini_lisp y.tab.o lex.yy.o -ll

y.tab.c: mini_lisp.y
	bison -d -o y.tab.c mini_lisp.y

y.tab.o: y.tab.c
	gcc -c -g -I.. y.tab.c

lex.yy.c: mini_lisp.l
	flex -o lex.yy.c mini_lisp.l

lex.yy.o: lex.yy.c
	gcc -c -g -I.. lex.yy.c

run: mini_lisp
	./mini_lisp < ex1.lsp
clean:
	rm -f y.tab.* lex.yy.* *.o mini_lisp
