etausgen:		etausgen.o
		ld etausgen.o -o etausgen

etausgen.o:		etausgen.asm
		nasm -f elf etausgen.asm -l etausgen.lst -o etausgen.o

clean:
		rm -f etausgen etausgen.o etausgen.lst
