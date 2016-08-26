crc:			crc.o
		ld crc.o -o crc

crc.o:			crc.asm
		nasm -f elf crc.asm -l crc.lst -o crc.o

clean:
		rm -f crc crc.o crc.lst
