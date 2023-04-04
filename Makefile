all: asmFromC cFromAsm

asmFromC: mainC.o printf.o
	gcc -o asmFromC printf.o mainC.o -no-pie

cFromAsm: mainAsm.o
	gcc -o cFromAsm mainAsm.o -no-pie

mainAsm.o: main.asm
	fasm main.asm mainAsm.o

mainC.o: main.c
	gcc -c main.c -o mainC.o -no-pie

printf.o: printf.asm
	fasm printf.asm printf.o

clean:
	rm *.o *.out
