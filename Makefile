all: main.out

main.out: main.o printf.o
	gcc -no-pie -o main.out printf.o main.o

main.o: main.c
	gcc -no-pie -c main.c -o main.o

printf.o: printf.asm
	fasm printf.asm

clean:
	rm *.o *.out
