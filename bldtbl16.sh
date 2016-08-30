#!/bin/bash
if [ -f crc16tbl.inc ]
then
echo "File crc16tbl.inc already exists"
exit 1
fi
if [ -f crctbl16 ]
then
crctbl16 >crc16tbl.inc
else
echo "crc16.asm did not compile"
echo "Can not run bldtbl16.sh"
exit 1
fi
