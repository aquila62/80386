crctbl32:			crctbl32.o
		ld crctbl32.o -o crctbl32

crctbl32.o:		crctbl32.asm
		nasm -f elf crctbl32.asm -l crctbl32.lst -o crctbl32.o

clean:
		rm -f crctbl32 crctbl32.o crctbl32.lst
