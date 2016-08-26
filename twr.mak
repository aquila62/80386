twr:			twr.o
		ld twr.o -o twr

twr.o:			twr.asm
		nasm -f elf twr.asm -l twr.lst -o twr.o

clean:
		rm -f twr twr.o twr.lst
