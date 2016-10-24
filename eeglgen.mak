eeglgen:		eeglgen.o
		ld eeglgen.o -o eeglgen

eeglgen.o:		eeglgen.asm
		nasm -f elf eeglgen.asm -l eeglgen.lst -o eeglgen.o

clean:
		rm -f eeglgen eeglgen.o eeglgen.lst
