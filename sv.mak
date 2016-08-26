sv:			sv.o
		ld sv.o -o sv

sv.o:			sv.asm
		nasm -f elf sv.asm -l sv.lst -o sv.o

clean:
		rm -f sv sv.o sv.lst
