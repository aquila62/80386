lmt:			lmt.o
		ld lmt.o -o lmt

lmt.o:			lmt.asm
		nasm -f elf lmt.asm -l lmt.lst -o lmt.o

clean:
		rm -f lmt lmt.o lmt.lst
