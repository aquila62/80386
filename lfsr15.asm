; lfsr15.asm - 15 Bit LFSR  Version 1.0.0
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

;---------------------------------------------------------------
; entry point is main, because of the subroutine, printf
; This program cycles through the LFSR algorithm until
; the state matches the original seed.
; The period length is 2^n-1 where n is the number of bits
; in the LFSR.
; This program has a 15 bit LFSR, so the period length
; should be 32767, which 2^15-1.
; The output is 7fff which is 32767 in hex.
; The decimal period length is also printed as 32767.
;---------------------------------------------------------------

	bits 32
	global main
	extern printf

;---------------------------------------------------------------
; macro to print floating point with printf
;---------------------------------------------------------------
%macro	pabc 0
	section .data
	section .text
	push eax
	mov eax,[fkount+4]     ; double period length
	push eax
	mov eax,[fkount]
	push eax
	push dword fmt         ; "period length %.0f",10,0
	call printf
	add esp,12
	pop eax
%endmacro

;---------------------------------------------------------------
; macro to print binary with printf
;---------------------------------------------------------------
%macro	pdef 0
	section .data
	section .text
	push eax
	mov eax,[kount]       ; binary period length
	push eax
	mov eax,fmt2          ; "period length %d",10,0
	push eax
	call printf
	add esp,8
	pop eax
%endmacro

;---------------------------------------------------------------
; macro to print binary with printf
;---------------------------------------------------------------
%macro	pghi 0
	section .data
	section .text
	push eax
	mov eax,[kount]       ; binary period length
	push eax
	mov eax,fmt3          ; "period length %d",10,0
	push eax
	call printf
	add esp,8
	pop eax
%endmacro

	section .text
main:
	fldz                     ; constant zero
	fstp qword [fkount]      ; store in fkount
	mov eax,0x1111           ; initialize the seed
	mov [sd],eax             ; with 1111
	call gen                 ; perform the LFSR cycle
	pabc
	pghi
eoj:
	mov eax,1                ; exit
	xor ebx,ebx              ; rc = 0
	int 0x80                 ; syscall
	nop
	nop
	nop
	nop
gen:
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
	push ebp
	xor edi,edi           ; binary counter
	mov eax,[sd]          ; eax = initial seed
	and eax,0x7fff        ; 15 bit mask
	mov esi,eax           ; esi = original seed
	mov ebp,eax           ; ebp = working state
.lp:
	;------------------------------------------------------
	; The algorithm is to xor bit 1 and bit 0
	;------------------------------------------------------
	shr eax,1             ; eax = bit 1
	mov ebx,eax           ; save in ebx
	mov eax,ebp           ; eax = bit 0
	xor eax,ebx           ; xor bit 1 and bit 0
	mov ebx,eax           ; save result in ebx
	mov eax,ebp           ; shift lfsr 1 bit to right
	shr eax,1
	and ebx,1             ; or the output in ebx
	shl ebx,14            ; into the 14th bit relative to zero
	or eax,ebx
	and eax,0x7fff        ; 15 bit state
	mov ebp,eax           ; save state in ebp for next iteration
	inc edi               ; binary count + 1
	fld qword [fkount]    ; floating point count + 1
	fld1
	fadd
	fstp qword [fkount]
	mov eax,ebp           ; compare state to original
	cmp eax,esi           ; current state = original state?
	jnz .lp               ; no, iterate again
	mov [kount],edi       ; yes, save period length
	pop ebp
	pop edi
	pop esi
	pop edx
	pop ecx
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
; print 32-bit register in hex
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
	push ebp
	mov [chbuf],al  ; place character in its own buffer
	mov eax,4       ; write
	mov ebx,1       ; handle (stdout)
	mov ecx,chbuf   ; addr of buf to write
	mov edx,1       ; #chars to write
	int 0x80        ; syscall
	pop ebp
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
	; reserved space for constant data
	; read only, not executable
	section .data
	align 16
; binary to hex translate table
hxtbl:  db '0123456789ABCDEF'
fmt:	db 'period length %.0f',10,0
fmt2:	db 'period length %d',10,0
fmt3:	db 'period length %04x hex',10,0
	section .bss
	align 16
chbuf	resb 4
sd	resd 1
kount	resd 1
fkount	resq 1
