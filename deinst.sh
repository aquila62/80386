#!/bin/bash
make -f lfsr15.mak clean
make -f sv.mak clean
make -f twr.mak clean
make -f knap.mak clean
make -f knap01.mak clean
make -f etausgen.mak clean
make -f etausraw.mak clean
make -f lmt.mak clean
make -f getprm.mak clean
make -f putnine.mak clean
make -f crctbl16.mak clean
make -f crctbl32.mak clean
make -f crc.mak clean
make -f crc16.mak clean
rm -f crc16tbl.inc
rm -f crc32tbl.inc
