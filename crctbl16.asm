; crctbl16.asm - Build a 16 Bit CRC Table    Version 1.0.0
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

;------------------------------------------------------------
; Build a CCITT 16 bit CRC table.
;
; Usage:
; crctbl | less
;
; The output is an include file for a table in a CRC program.
;------------------------------------------------------------
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
	mov esp,stkend        ; create new program stack
	call bld              ; build the table
        ;------------------------------------------------------------
	; terminate the program
        ;------------------------------------------------------------
eoj:
	mov eax,1        ; terminate the program
	xor ebx,ebx      ; RC=0
	int 0x80         ; syscall (operating system service)
;---------------------------------------------------
; Build a CCITT 16 bit CRC table
;---------------------------------------------------
bld:
	push eax
	push ebx
	push ecx
	push edx
	mov eax,ttlmsg
	call putstr
	xor cl,cl         ; byte 0..0xff
	mov [byt],cl
.lp:
	xor edx,edx       ; crc = 0
	mov [crc],dx
	mov ax,[byt]
	mov [cee],ax      ; cee = byte
	mov ch,8          ; loop counter = 8
.lp2:
	mov al,[crc+1]
	mov ah,[cee]
	xor al,ah         ; crc = crc ^ (byte << 8)
	and al,0x80
	or al,al          ; is high order bit 1 ?
	jz .lp3           ; no, just shift crc to left
	mov ax,[crc]      ; yes, shift crc to left and...
	shl ax,1
	mov [crc],ax
	mov ax,[crc]
	mov dx,[poly]
	xor ax,dx         ; xor (crc << 1) ^ poly
	mov [crc],ax
	jmp .lp4          ; continue to next iteration
.lp3:                     ; high order bit is zero
	mov ax,[crc]      ; shift crc 1 bit to left
	shl ax,1
	mov [crc],ax
.lp4:                     ; next inner loop iteration
	mov al,[cee]      ; shift cee to left
	shl al,1
	mov [cee],al
	dec ch            ; decrement loop counter
	or ch,ch
	jnz .lp2
	mov eax,dwmsg
	call putstr
	call putcrc
	mov al,[byt]      ; end of outer loop?
	cmp al,0xff
	jz .lp5           ; yes, end of job
	inc al            ; no, increment byte
	mov [byt],al
	jmp .lp           ; repeat outer loop 256 times
.lp5:
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
; print Z followed by one space
;---------------------------------------------------
putz:
	push eax
	mov al,'Z'
	call putchar
	mov al,0x20
	call putchar
	pop eax
	ret
;---------------------------------------------------
; print byte in hex followed by one space
;---------------------------------------------------
putbyt:
	push eax
	mov al,'b'
	call putchar
	mov al,'y'
	call putchar
	mov al,'t'
	call putchar
	call putspc
	mov al,[byt]
	call puthexa
	pop eax
	ret
;---------------------------------------------------
; print cee  in hex followed by one space
;---------------------------------------------------
putcee:
	push eax
	mov al,'c'
	call putchar
	mov al,'e'
	call putchar
	mov al,'e'
	call putchar
	call putspc
	mov al,[cee]
	call puthexa
	pop eax
	ret
;---------------------------------------------------
; print crc in hex followed by H and end of line
;---------------------------------------------------
putcrc:
	push eax
	mov ax,[crc]
	call putax
	call puteol
	pop eax
	ret
;---------------------------------------------------
; print crc in hex followed by one space for debugging
;---------------------------------------------------
putcrcdb:
	push eax
	mov al,'c'
	call putchar
	mov al,'r'
	call putchar
	mov al,'c'
	call putchar
	call putspc
	mov ax,[crc]
	call putax
	call putspc
	pop eax
	ret
;---------------------------------------------------
; print cl in hex followed by one space
;---------------------------------------------------
putcl:
	push eax
	mov al,'C'
	call putchar
	mov al,'L'
	call putchar
	call putspc
	mov al,cl
	call puthexa
	pop eax
	ret
;---------------------------------------------------
; print dx in hex followed by one space
;---------------------------------------------------
putdx:
	push eax
	mov al,'D'
	call putchar
	mov al,'X'
	call putchar
	call putspc
	mov ax,dx
	call putax
	call putspc
	pop eax
	ret
;---------------------------------------------------
; print dl in hex followed by one space
;---------------------------------------------------
putdl:
	push eax
	mov al,'D'
	call putchar
	mov al,'L'
	call putchar
	call putspc
	mov al,dh
	call puthexa
	pop eax
	ret
;---------------------------------------------------
; print dh in hex followed by one space
;---------------------------------------------------
putdh:
	push eax
	mov al,'D'
	call putchar
	mov al,'H'
	call putchar
	call putspc
	mov al,dh
	call puthexa
	pop eax
	ret
;---------------------------------------------------
; print al in hex followed by one space
;---------------------------------------------------
puthexa:
	push eax
	call puthex
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
ttlmsg: db 'tbl:',10,0
dwmsg:  db '   dw 0x',0
poly:   dd 0x00001021
	;---------------------------------
	; reserved space for variable data
	; read/write, not executable
	;---------------------------------
	section .bss
	align 16
chbuf	resb 4          ; print character buffer
kbbuf	resb 4          ; print character buffer
byt  	resb 4          ; current byte
cee  	resb 4          ; current byte
crc  	resw 4          ; crc
stack   resb 8192       ; recursive program stack
stkend  resb 4          ; highest address of stack
