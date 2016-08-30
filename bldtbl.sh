#!/bin/bash
if [ -f crc16tbl.inc ]
then
echo "File crc16tbl.inc already exists"
exit 1
fi
crctbl >crc16tbl.inc
