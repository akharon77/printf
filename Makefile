all: asmFromC cFromAsm

asmFromC: mainC.o printf.o
	gcc -o asmFromC printf.o mainC.o -no-pie

cFromAsm: mainAsm.o
	ld mainAsm.o -o cFromAsm /lib/x86_64-linux-gnu/libc.so --dynamic-linker /lib64/ld-linux-x86-64.so.2

mainAsm.o: main.asm
	fasm main.asm mainAsm.o

mainC.o: main.c
	gcc -c main.c -o mainC.o -no-pie

printf.o: printf.asm
	fasm printf.asm printf.o

clean:
	rm *.o *.out
