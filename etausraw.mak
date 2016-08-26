etausraw:		etausraw.o
		ld etausraw.o -o etausraw

etausraw.o:		etausraw.asm
		nasm -f elf etausraw.asm -l etausraw.lst -o etausraw.o

clean:
		rm -f etausraw etausraw.o etausraw.lst
