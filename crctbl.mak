
crctbl:			crctbl.o
		ld crctbl.o -o crctbl

crctbl.o:		crctbl.asm
		nasm -f elf crctbl.asm -l crctbl.lst -o crctbl.o

clean:
		rm -f crctbl crctbl.o crctbl.lst
