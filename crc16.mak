crc16:			crc16.o
		ld crc16.o -o crc16

crc16.o:		crc16.asm
		nasm -f elf crc16.asm -l crc16.lst -o crc16.o

clean:
		rm -f crc16 crc16.o crc16.lst
