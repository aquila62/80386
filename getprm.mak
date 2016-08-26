getprm:			getprm.o
		ld getprm.o -o getprm

getprm.o:			getprm.asm
		nasm -f elf getprm.asm -l getprm.lst -o getprm.o

clean:
		rm -f getprm getprm.o getprm.lst
