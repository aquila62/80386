crctbl16:			crctbl16.o
		ld crctbl16.o -o crctbl16

crctbl16.o:		crctbl16.asm
		nasm -f elf crctbl16.asm -l crctbl16.lst -o crctbl16.o

clean:
		rm -f crctbl16 crctbl16.o crctbl16.lst
