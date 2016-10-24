eeglraw:		eeglraw.o
		ld eeglraw.o -o eeglraw

eeglraw.o:		eeglraw.asm
		nasm -f elf eeglraw.asm -l eeglraw.lst -o eeglraw.o

clean:
		rm -f eeglraw eeglraw.o eeglraw.lst
