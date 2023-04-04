all: asmFromC.out cFromAsm.out

asmFromC.out: mainC.o printf.o
	gcc -o asmFromC.out printf.o mainC.o -no-pie

cFromAsm.out: mainAsm.o
	gcc -o cFromAsm.out mainAsm.o -no-pie

mainAsm.o: main.asm
	fasm main.asm mainAsm.o

mainC.o: main.c
	gcc -c main.c -o mainC.o -no-pie

printf.o: printf.asm
	fasm printf.asm printf.o

clean:
	rm *.o *.out
