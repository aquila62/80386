
emul:			emul.o
		ld emul.o -o emul

emul.o:			emul.asm
		nasm -f elf emul.asm -l emul.lst -o emul.o

clean:
		rm -f emul emul.o emul.lst
