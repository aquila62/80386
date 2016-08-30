#!/bin/bash
make -f lfsr15.mak
make -f sv.mak
make -f twr.mak
make -f crc.mak
make -f etausgen.mak
make -f etausraw.mak
make -f lmt.mak
make -f getprm.mak
#----------------------------
make -f crctbl.mak
if [ -f crctbl ]
then
bldtbl.sh
else
echo "crctbl.asm did not compile"
echo "Can not run bldtbl.sh"
exit 1
fi
#----------------------------
if [ -f crc16tbl.inc ]
then
make -f crc16.mak
make -f putnine.mak
else
echo "crc16.asm did not compile"
echo "Could not include crc16tbl.inc"
exit 1
fi
