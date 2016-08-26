; crc.asm - 32 Bit CRC Hash   Version 1.0.0
; Copyright (C) 2016 aquila62 at github.com

; This program is free software; you can redistribute it and/or
; modify it under the terms of the GNU General Public License as
; published by the Free Software Foundation; either version 2 of
; the License, or (at your option) any later version.

; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with this program; if not, write to:

   ; Free Software Foundation, Inc.
   ; 59 Temple Place - Suite 330
   ; Boston, MA 02111-1307, USA.

	bits 32               ; 32-bit assembler
	global _start         ; tell Linux what the entry point is
	section .text         ; read only, executable section
_start:
        ;------------------------------------------------------------
	; set the program stack size to 8192
	; That allows 2048 pushes on the stack
	; This is more than enough for this program
	; The stack is now part of the .bss section.
        ;------------------------------------------------------------
	mov esp,stkend
	call bld            ; build the crc table
	call calc           ; calculate the crc from stdin
eoj:
	mov eax,1           ; exit
	xor ebx,ebx         ; rc = 0
	int 0x80            ; syscall
	nop
	nop
	nop
	nop
;---------------------------------------------------
; build crc table
;---------------------------------------------------
bld:
	push eax
	push ebx
	push ecx
	push edx
	xor eax,eax             ; eax = 0
	mov [byt],eax           ; start with byte = 0
	mov ebx,crctbl          ; point to crc table
.lp:                            ; outer loop x 256
	mov eax,[byt]           ; eax = byte 0 to 255
	mov [crcbyt],eax        ; save in temporary byte
	mov ecx,8               ; set loop counter to 8
.lp2:                           ; inner loop x 8 bits
	mov edx,[crcbyt]        ; edx = byte
	and edx,1               ; low order bit of byte
	mov eax,edx             ; eax = low order bit of byte
	sub eax,edx             ; eax = eax - edx - edx
	sub eax,edx             ; result is 0 or 0xffffffff
	mov [msk],eax           ; save result in mask
	mov eax,[crcbyt]        ; eax = byte
	shr eax,1               ; shift right 1 bit
	mov [left],eax          ; save as (byte >> 1)
	mov eax,0xedb88320      ; eax = the crc-32 polynomial
	mov edx,[msk]           ; edx = the mask
	and eax,edx             ; lower 8 bits of the polynomial
	mov [rght],eax          ; 0xedb88320 & mask
	mov eax,[left]          ; byte >> 1
	mov edx,[rght]          ; 0xedb88320 & mask
	xor eax,edx             ; (byte >> 1) ^ (0x3db88320 & mask)
	mov [crcbyt],eax        ; save in byte
	loop .lp2               ; repeat inner loop 8 times
	mov [ebx],eax           ; save in table[byte]
	add ebx,4               ; point to table[byte+1]
	mov eax,[byt]           ; byte = byte + 1
	inc eax
	mov [byt],eax           ; save new value for byte
	cmp eax,256             ; 256 entries in table?
	jb .lp                  ; no, repeat outer loop 256 times
	pop edx                 ; return to mainline
	pop ecx
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; calculate the crc of input stream from stdin
;---------------------------------------------------
calc:
	push eax
	push ebx
	push ecx
	push edx
	push esi
	xor eax,eax         ; eax = 0
	dec eax             ; eax = 0xffffffff
	mov [crc],eax       ; initialize crc to 0xffffffff
.lp:
        ;---------------------------------------------------
	; read one 64k block from stdin
	; Linux returns the length of the block in eax
	; end of file if eax is zero
        ;---------------------------------------------------
	mov eax,3           ; read
	xor ebx,ebx         ; stdin
	mov ecx,buf         ; buffer address
	mov edx,65536       ; length = 64k
	int 0x80            ; syscall
	or eax,eax          ; empty block?
	jz .done            ; yes, end of input file, finish crc
	mov [bufsz],eax     ; loop count
	mov ebx,buf         ; point to input buffer
.lp2:
	mov al,[ebx]        ; al = byte from buffer
	mov [byt],eax       ; save input byte
	mov eax,[crc]       ; eax = crc
	mov edx,[byt]       ; edx = current byte
	xor eax,edx         ; eax = crc ^ byte
	and eax,0xff        ; low 8 bits of eax
	mov [indx],eax      ; index to crc table
	mov esi,crctbl      ; point to crc table
	shl eax,2           ; index = index * 4
	add esi,eax         ; point to crctbl[indx]
	mov eax,[crc]       ; eax = crc
	shr eax,8           ; shift crc 8 bits to right
	mov edx,[esi]       ; edx = crctbl[indx]
	xor eax,edx         ; crc = (crc >> 8) ^ crctbl[indx]
	mov [crc],eax       ; save new crc
	;-------------------------------------------------
	; check end of buffer
	;-------------------------------------------------
	inc ebx             ; point to next byte in buffer
	mov eax,[bufsz]     ; bufsz = bufsz - 1
	dec eax
	mov [bufsz],eax
	or eax,eax          ; bufsz = 0?
	jnz .lp2            ; no, repeat crc calculation
	jmp .lp             ; yes, read another block of input
.done:
	;-------------------------------------------------
	; crc = ~crc
	;-------------------------------------------------
	mov eax,[crc]       ; eax = crc
	xor eax,0xffffffff  ; crc = ~crc
	mov [crc],eax       ; final crc
	;-------------------------------------------------
	; print crc in hex to stdout
	;-------------------------------------------------
	call puteax
	call puteol
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; print crc table in hex
;---------------------------------------------------
shwtbl:
	push eax
	push ebx
	push ecx
	push edx
	mov ebx,crctbl        ; point to crc table
	mov ecx,256           ; loop counter = 256
	xor edx,edx           ; initialize index to table = 0
.lp:                          ; table loop x 256
	mov eax,edx           ; eax = index to table 0-255
	call puthex           ; print 8-bit index
	call putspc           ; followed by space
	mov eax,[ebx]         ; eax = table[i]
	call puteax           ; print table entry in hex
	add ebx,4             ; point to table[i+1]
	inc edx               ; index = index + 1
	loop .lp              ; loop 256 times
	call puteol           ; print end of line at end
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; read keyboard with wait, if CTL-Z quit
; There is no wait for piped input
;---------------------------------------------------
pause:
	push eax
	push ebx
	push ecx
	push edx
	mov eax,3        ; read input withn wait
	mov ebx,0        ; stdin
	mov ecx,kbbuf    ; buf
	mov edx,1        ; length
	int 0x80         ; syscall
	cmp al,'q'       ; q?
	jz eoj           ; yes, quit
	cmp al,0x1a      ; CTL-Z?
	jz eoj           ; yes, quit
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; print null terminated string
;---------------------------------------------------
putstr:              ; eax = message
	push eax
	push ebx
        mov ebx,eax    ; point to beginning of message
.lp:
	mov al,[ebx]   ; al = character to print
	or al,al       ; end of string?
	jz .done       ; yes, return
	call putchar   ; print character
	inc ebx        ; point to next character in string
	jmp .lp        ; repeat loop
.done:
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; print esi register in hex
;---------------------------------------------------
putesi:
	push eax
	mov eax,esi
	call puteax
	call putspc
	pop eax
	ret
;---------------------------------------------------
; print edi register in hex
;---------------------------------------------------
putedi:
	push eax
	mov eax,edi
	call puteax
	call putspc
	pop eax
	ret
;---------------------------------------------------
; print X followed by one space
;---------------------------------------------------
putx:
	push eax
	mov al,'X'
	call putchar
	mov al,0x20
	call putchar
	pop eax
	ret
;---------------------------------------------------
; print Y followed by one space
;---------------------------------------------------
puty:
	push eax
	mov al,'Y'
	call putchar
	mov al,0x20
	call putchar
	pop eax
	ret
;---------------------------------------------------
; print one space
;---------------------------------------------------
putspc:
	push eax
	mov al,0x20
	call putchar
	pop eax
	ret
;---------------------------------------------------
; print end of line
;---------------------------------------------------
puteol:
	push eax
	mov al,10
	call putchar
	pop eax
	ret
;---------------------------------------------------
; print edx
;---------------------------------------------------
putedx:
	push eax
	push edx
	mov eax,edx
	call puteax
	pop edx
	pop eax
	ret
;---------------------------------------------------
; print 32-bit eax register in hex
; print in big endian format
;---------------------------------------------------
puteax:
	push eax
	shr eax,16        ; print upper 16 bits
	call putax
	pop eax
	push eax
	and eax,0xffff    ; print lower 16 bits
	call putax
	call putspc
	pop eax
	ret
;---------------------------------------------------
; print 16-bit half of register in hex
; print in big endian format
;---------------------------------------------------
putax:
	push eax
	xchg ah,al       ; print upper 8 bits
	call puthex
	xchg ah,al       ; print lower 8 bits
	call puthex
	pop eax
	ret
;---------------------------------------------------
; print al in hex followed by one space
;---------------------------------------------------
puthexa:
	push eax
	call puthex
	call putspc
	pop eax
	ret
;---------------------------------------------------
; print one byte in hex
; print in big endian format
; high order nybble first
;---------------------------------------------------
puthex:
	push eax
	shr al,4            ; print upper 4 bits
	call putnbl
	pop eax
	push eax
	and al,0x0f         ; print lower 4 bits
	call putnbl
	pop eax
	ret
;---------------------------------------------------
; print one nybble in hex
; translate from binary to hex using a translate table
;---------------------------------------------------
putnbl:
	push eax
	push ebx
	mov ebx,hxtbl    ; translate binary to hex
	xlatb
	call putchar
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; print one ASCII character to stdout
; extra caution is taken to preserve integrity of
; all working registers
; ebp register is assumed to be safe
;---------------------------------------------------
putchar:
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
	mov [chbuf],al  ; place character in its own buffer
	mov eax,4       ; write
	mov ebx,1       ; handle (stdout)
	mov ecx,chbuf   ; addr of buf to write
	mov edx,1       ; #chars to write
	int 0x80        ; syscall
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
	;---------------------------------
	; reserved space for constant data
	; read only, not executable
	;---------------------------------
	section .data
	align 16
; binary to hex translate table
hxtbl:  db '0123456789ABCDEF'
	;---------------------------------
	; reserved space for variable data
	; read/write, not executable
	;---------------------------------
	section .bss
	align 16
chbuf	resb 4          ; print character buffer
kbbuf	resb 4          ; print character buffer
byt     resd 1          ; byte 0-255
crcbyt  resd 1          ; crc byte 0-255
msk     resd 1          ; mask
left    resd 1          ; left  half of expression
rght    resd 1          ; right half of expression
crc     resd 1          ; cyclical redundancy check crc
bufsz   resd 1          ; size of input buffer
indx    resd 1          ; index into crc table
crctbl  resd 256        ; crc table
buf     resb 65536      ; input buffer
stack   resb 8192       ; recursive program stack
stkend  resb 4          ; highest address of stack
