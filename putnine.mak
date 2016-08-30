putnine:		putnine.o
		ld putnine.o -o putnine

putnine.o:		putnine.asm
		nasm -f elf putnine.asm -l putnine.lst -o putnine.o

clean:
		rm -f putnine putnine.o putnine.lst
