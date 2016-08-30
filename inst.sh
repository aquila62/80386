#!/bin/bash
make -f lfsr15.mak
make -f sv.mak
make -f twr.mak
make -f etausgen.mak
make -f etausraw.mak
make -f lmt.mak
make -f getprm.mak
make -f putnine.mak
#----------------------------
make -f crctbl32.mak
if [ -f crctbl32 ]
then
bldtbl32.sh
else
echo "crctbl32.asm did not compile"
echo "Can not run bldtbl32.sh"
exit 1
fi
#----------------------------
if [ -f crc32tbl.inc ]
then
make -f crc.mak
else
echo "crc32.asm did not compile"
echo "Could not include crc32tbl.inc"
exit 1
fi
#----------------------------
make -f crctbl16.mak
if [ -f crctbl16 ]
then
bldtbl16.sh
else
echo "crctbl16.asm did not compile"
echo "Can not run bldtbl16.sh"
exit 1
fi
#----------------------------
if [ -f crc16tbl.inc ]
then
make -f crc16.mak
else
echo "crc16.asm did not compile"
echo "Could not include crc16tbl.inc"
exit 1
fi
