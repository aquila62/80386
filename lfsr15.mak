lfsr15:			lfsr15.o
		gcc lfsr15.o -o lfsr15

lfsr15.o:		lfsr15.asm
		nasm -f elf -o lfsr15.o lfsr15.asm

clean:
		rm -f lfsr15.o lfsr15
