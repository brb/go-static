CC ?= gcc
GO ?= go

all: main

main: libsum.a main.a
	$(GO) tool 6l -o $@ -linkmode external -extldflags=-static main.a

libsum.a: sum.o
	ar rcs $@ $?

sum.o: sum.c
	$(CC) -static -nostdlib -o $@ -c $?

main.a: main.6 wrap.6
	$(GO) tool pack c $@ $?

main.6: main.go
	$(GO) tool 6g $?

wrap.6: wrap.s
	$(GO) tool old6a $?

clean:
	rm -f main *.a *.o *.6
