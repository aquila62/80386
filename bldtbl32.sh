#!/bin/bash
if [ -f crc32tbl.inc ]
then
echo "File crc32tbl.inc already exists"
exit 1
fi
if [ -f crctbl32 ]
then
crctbl32 >crc32tbl.inc
else
echo "crc.asm did not compile"
echo "Can not run bldtbl32.sh"
exit 1
fi
