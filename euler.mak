euler:			euler.o
		ld euler.o -o euler

euler.o:		euler.asm
		nasm -f elf euler.asm -l euler.lst -o euler.o

clean:
		rm -f euler euler.o euler.lst
