knap:			knap.o
		ld knap.o -o knap

knap.o:			knap.asm
		nasm -f elf knap.asm -l knap.lst -o knap.o

clean:
		rm -f knap knap.o knap.lst
