; euler.asm - Euler's Sum of Powers Conjecture  Version 1.0.0
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
; This program calculates Euler's Sum of Powers Conjecture
; (X0)^5 + (X1)^5 + (X2)^5 + (X3)^5 = Y^5
; where each X and Y are unique.
; This problem is taken from rosettacode.org
; Domain for this problem: integers 0 to 250 inclusive
; Expected result is: 27 84 110 133 144
; That means that:
; 27^5 + 84^5 + 110^5 + 133^5 = 144^5
; This assembler version of the problem uses the same
; heuristics as the C version, but runs slower.
;---------------------------------------------------------------

	bits 32                  ; 80386 NASM assembler
	global _start            ; ld is the linker

	section .text
_start:                          ; entry point
	mov esp,svend            ; set own stack of 2048 registers
	call fill                ; fill the array with k^5
                                 ; where k = 0 to 250 inclusive
	call calc                ; calculate conjecture
eoj:
	mov eax,1                ; exit
	xor ebx,ebx              ; rc = 0
	int 0x80                 ; syscall
	hlt
	nop
	nop
	nop
;---------------------------------------------------
; Calculate for (a=0;a<=250;a++)
;---------------------------------------------------
calc:
	push eax
	xor eax,eax
	mov [a],eax
.lp:
	call calcb
	mov eax,[a]
	inc eax
	mov [a],eax
	cmp eax,251
	jb .lp
	pop eax
	ret
;---------------------------------------------------
; Calculate for (b=a+1;b<=250;b++)
;---------------------------------------------------
calcb:
	push eax
	mov eax,[a]
	inc eax
	mov [b],eax
.lp:
	call calcc
	mov eax,[b]
	inc eax
	mov [b],eax
	cmp eax,251
	jb .lp
	pop eax
	ret
;---------------------------------------------------
; Calculate for (c=b+1;c<=250;c++)
;---------------------------------------------------
calcc:
	push eax
	mov eax,[b]
	inc eax
	mov [c],eax
.lp:
	call calcd
	mov eax,[c]
	inc eax
	mov [c],eax
	cmp eax,251
	jb .lp
	pop eax
	ret
;---------------------------------------------------
; Calculate for (d=c+1;d<=250;d++)
;---------------------------------------------------
calcd:
	push eax
	mov eax,[c]
	inc eax
	mov [d],eax
.lp:
	call calcsum
	mov eax,[d]
	inc eax
	mov [d],eax
	cmp eax,251
	jb .lp
	pop eax
	ret
;---------------------------------------------------
; Calculate sum = lst[a] + lst[b] + lst[c] + lst[d]
; Compare sum to lst[e] in cmprsum()
;---------------------------------------------------
calcsum:
	push eax
	push ebx
	push esi
	;------------------------------------------------
	; initialize sum to lst[a]
	;------------------------------------------------
	mov esi,lst
	mov eax,[a]
	shl eax,3
	add esi,eax
	mov eax,[esi]        ; low  order 32 bits of lst[a]
	mov [sum],eax
	mov eax,[esi+4]      ; high order 32 bits of lst[a]
	mov [sum+4],eax
	;------------------------------------------------
	; add lst[b] to sum
	; 64-bit + 64-bit add
	;------------------------------------------------
	mov esi,lst
	mov eax,[b]
	shl eax,3
	add esi,eax
	mov ebx,[esi]
	mov eax,[sum]
	add eax,ebx            ; sum = sum + lst[b]
	mov [sum],eax
	mov ebx,[esi+4]
	mov eax,[sum+4]
	adc eax,ebx
	mov [sum+4],eax
	;------------------------------------------------
	; add lst[c] to sum
	;------------------------------------------------
	mov esi,lst
	mov eax,[c]
	shl eax,3
	add esi,eax
	mov ebx,[esi]
	mov eax,[sum]
	add eax,ebx            ; sum = sum + lst[c]
	mov [sum],eax
	mov ebx,[esi+4]
	mov eax,[sum+4]
	adc eax,ebx
	mov [sum+4],eax
	;------------------------------------------------
	; add lst[d] to sum
	;------------------------------------------------
	mov esi,lst
	mov eax,[d]
	shl eax,3
	add esi,eax
	mov ebx,[esi]
	mov eax,[sum]
	add eax,ebx            ; sum = sum + lst[d]
	mov [sum],eax
	mov ebx,[esi+4]
	mov eax,[sum+4]
	adc eax,ebx
	mov [sum+4],eax
	;------------------------------------------------
	; now compare sum to lst[e]
	; where e is d+1 to 250 inclusive
	; looking for a match
	; if sum < lst[e],
	;     return to calcd
	;------------------------------------------------
	call cmprsum           ; now compare sum to lst[e]
	pop esi
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; for (e=d+1;e<=250;e++)
; Compare sum to lst[e]
; if equal, print a,b,c,d,e, then return to calcsum
; which returns to calcd
; else if sum < lst[e], return to calcsum
; which returns to calcd
;---------------------------------------------------
cmprsum:
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
	push ebp
	;------------------------------------------------
	; initialize e to d+1
	;------------------------------------------------
	mov eax,[d]
	inc eax
	mov [e],eax
.lp:
	;------------------------------------------------
	; set esi to lst[e]
	;------------------------------------------------
	mov eax,[e]
	shl eax,3        ; each entry is 8 bytes
	mov esi,lst
	add esi,eax
	;------------------------------------------------
	; first compare the high order 32 bits
	;------------------------------------------------
	mov eax,[esi+4]
	mov ebx,[sum+4]
	sub eax,ebx        ; subtract sum from lst[e]
	jz .mtch1          ; if equal, compare lower 32 bits
	js .nxt            ; if sum > lst[e], loop
	jmp .done          ; if sum < lst[e], return
.mtch1:
	;------------------------------------------------
	; if high order 32 bits match,
	; compare low order 32 bits
	;------------------------------------------------
	mov eax,[esi]
	mov ebx,[sum]
	sub eax,ebx        ; subtract sum from lst[e]
	jz .mtch           ; if equal, print match
	js .nxt            ; if sum > lst[e], loop
	jmp .done          ; if sum < lst[e], return
.mtch:
	;------------------------------------------------
	; sum == lst[e]
	; print a,b,c,d,e
	; return
	;------------------------------------------------
	mov eax,[a]
	mov [prime],eax
	call putprime
	;------------
	mov eax,[b]
	mov [prime],eax
	call putprime
	;------------
	mov eax,[c]
	mov [prime],eax
	call putprime
	;------------
	mov eax,[d]
	mov [prime],eax
	call putprime
	;------------
	mov eax,[e]
	mov [prime],eax
	call putprime
	call puteol
	jmp .done            ; return
.nxt:
	;------------------------------------------------
	; sum > lst[e]
	; loop and compare lst[e+1]
	; e = d+1 to 250 inclusive
	;------------------------------------------------
	mov eax,[e]
	inc eax
	mov [e],eax
	cmp eax,251
	jb .lp
	;--------------
.done:
	;------------------------------------------------
	; return to calcsum
	; which returns to calcd
	;------------------------------------------------
	pop ebp
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; fill list with k^5
; where 0 <= k <= 250
;---------------------------------------------------
fill:
	push eax
	xor eax,eax
	mov [a],eax
.lp:
	; [a] is 0 to 250 inclusive
	; getpwr uses [a] as its parameter
	call getpwr        ; [fifth] = eax^5
	mov eax,[a]
	inc eax
	mov [a],eax
	cmp eax,251
	jb .lp
	pop eax
	ret
;---------------------------------------------------
; getpwr
; calculate [fifth] = eax^5
;---------------------------------------------------
getpwr:
	push eax
	push ebx
	push edx
	push esi
	mov eax,[a]            ; [a] = 0 to 250 inclusive
	mov [ayy],eax
	; initialize working fields to zero
	xor eax,eax
	mov [square],eax           ; a squared
	mov [square+4],eax
	mov [quad],eax             ; a^4
	mov [quad+4],eax
	mov [fifth],eax            ; a^5
	mov [fifth+4],eax
	mov [fifth+8],eax
	mov [fifth+12],eax
	; x^2
	; calculate a*a
	mov eax,[ayy]
	mov ebx,eax
	mul ebx
	mov [square],eax
	; x^4
	; calculate a*a*a*a
	mov eax,[square]
	mov ebx,eax
	mul ebx
	mov [quad],eax
	; x^5
	; calculate a*a*a*a*a
	mov eax,[quad]
	mov ebx,[ayy]
	mul ebx
	mov [fifth],eax
	mov [fifth+4],edx           ; 64 bit result
	; set lst[ayy] to [fifth]
	mov eax,[ayy]
	shl eax,3
	mov esi,lst
	add esi,eax
	mov eax,[fifth]
	mov [esi],eax
	mov eax,[fifth+4]
	mov [esi+4],eax
	pop esi
	pop edx
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; print number in decimal
;---------------------------------------------------
putprime:
	push eax
	push ebx
	push ecx
	push edx
	;-------------------------------------------
	; calculate units digit
	;-------------------------------------------
	xor edx,edx
	mov eax,[prime]
	mov ebx,10
	div ebx
	mov [dgtstk],edx
	;-------------------------------------------
	; calculate tens digit
	;-------------------------------------------
	xor edx,edx
	div ebx
	mov [dgtstk+4],edx
	;-------------------------------------------
	; calculate hundreds digit
	;-------------------------------------------
	xor edx,edx
	div ebx
	mov [dgtstk+8],edx
	;-------------------------------------------
	; calculate thousands digit
	;-------------------------------------------
	xor edx,edx
	div ebx
	mov [dgtstk+12],edx
	;-------------------------------------------
	; calculate ten thousands digit
	;-------------------------------------------
	xor edx,edx
	div ebx
	mov [dgtstk+16],edx
	;-------------------------------------------
	; calculate hundred thousands digit
	;-------------------------------------------
	xor edx,edx
	div ebx
	mov [dgtstk+20],edx
	;-------------------------------------------
	; calculate millions digit
	;-------------------------------------------
	xor edx,edx
	div ebx
	mov [dgtstk+24],edx
	;-------------------------------------------
	; calculate ten millions digit
	;-------------------------------------------
	xor edx,edx
	div ebx
	mov [dgtstk+28],edx
	;-------------------------------------------
	; calculate hundred millions digit
	;-------------------------------------------
	xor edx,edx
	div ebx
	mov [dgtstk+32],edx
	;-------------------------------------------
	; calculate billions digit
	;-------------------------------------------
	xor edx,edx
	div ebx
	mov [dgtstk+36],edx
        ;---------------------------------------------------
        ; print digits from stack
	; first bypass leading zeros
        ;---------------------------------------------------
	mov eax,[dgtstk+36]        ; billions digit
	or eax,eax                 ; zero?
	jnz .pk2                   ; no, print 10 digits
	mov eax,[dgtstk+32]        ; hundred millions digit
	or eax,eax                 ; zero?
	jnz .pk3                   ; no, print 9 digits
	mov eax,[dgtstk+28]        ; ten millions digit
	or eax,eax                 ; zero?
	jnz .pk4                   ; no, print 8 digits
	mov eax,[dgtstk+24]        ; millions digit
	or eax,eax                 ; zero?
	jnz .pk5                   ; no, print 7 digits
	mov eax,[dgtstk+20]        ; hundred thousands digit
	or eax,eax                 ; zero?
	jnz .pk6                   ; no, print 6 digits
	mov eax,[dgtstk+16]        ; ten thousands digit
	or eax,eax                 ; zero?
	jnz .pk7                   ; no, print 5 digits
	mov eax,[dgtstk+12]        ; thousands digit
	or eax,eax                 ; zero?
	jnz .pk8                   ; no, print 4 digits
	mov eax,[dgtstk+8]         ; hundreds digit
	or eax,eax                 ; zero?
	jnz .pk9                   ; no, print 3 digits
	mov eax,[dgtstk+4]         ; tens digit
	or eax,eax                 ; zero?
	jnz .pk10                  ; no, print 2 digits
	jmp .pk11                  ; yes, print 1 digit
;------------------------------------------------------
; entry points for bypassing leading zeros
;------------------------------------------------------
.pk2:
	mov eax,[dgtstk+36]        ; billions digit
        add eax,0x30               ; convert to ASCII
	call putchar               ; print digit
.pk3:
	mov eax,[dgtstk+32]        ; hundred millions digit
        add eax,0x30               ; convert to ASCII
	call putchar               ; print digit
.pk4:
	mov eax,[dgtstk+28]        ; ten millions digit
        add eax,0x30               ; convert to ASCII
	call putchar               ; print digit
.pk5:
	mov eax,[dgtstk+24]        ; millions digit
        add eax,0x30               ; convert to ASCII
	call putchar               ; print digit
.pk6:
	mov eax,[dgtstk+20]        ; hundred thousands digit
        add eax,0x30               ; convert to ASCII
	call putchar               ; print digit
.pk7:
	mov eax,[dgtstk+16]        ; ten thousands digit
        add eax,0x30               ; convert to ASCII
	call putchar               ; print digit
.pk8:
	mov eax,[dgtstk+12]        ; thousands digit
        add eax,0x30               ; convert to ASCII
	call putchar               ; print digit
.pk9:
	mov eax,[dgtstk+8]         ; hundreds digit
        add eax,0x30               ; convert to ASCII
	call putchar               ; print digit
.pk10:
	mov eax,[dgtstk+4]         ; tens digit
        add eax,0x30               ; convert to ASCII
	call putchar               ; print digit
.pk11:
	mov eax,[dgtstk]           ; units digit
        add eax,0x30               ; convert to ASCII
	call putchar               ; print digit
	call putspc                ; print space
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
	section .bss
	align 16
chbuf	resb 4            ; character buffer for putchar
a 	resd 1            ; X0 in the algorithm
b 	resd 1            ; X1 in the algorithm
c 	resd 1            ; X2 in the algorithm
d 	resd 1            ; X3 in the algorithm
e 	resd 2            ; Y in the algorithm
sum	resd 2            ; lst[a] + lst[b] + lst[c] + lst[d]
ayy     resd 1            ; temporary copy of [a]
square  resd 2            ; X*X
quad    resd 2            ; X^4
fifth   resd 4            ; X^5
prime   resd 1            ; parameter for putprime
dgtstk  resd 32           ; decimal digit stack
lst     resd 8192         ; 64-bit array
svarea  resd 8192         ; program stack
svend   resd 1
