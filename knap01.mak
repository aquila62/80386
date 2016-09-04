knap01:			knap01.o
		ld knap01.o -o knap01

knap01.o:		knap01.asm
		nasm -f elf knap01.asm -l knap01.lst -o knap01.o

clean:
		rm -f knap01 knap01.o knap01.lst
