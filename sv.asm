; sv.asm - Sieve of Eratosthenes   Version 1.0.0
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
; sieve of Eratosthenes
; classical algorithm to calculate list of prime numbers 
; written in NASM 32-bit assembler
; creates ELF object
; link with ld
; compile with sv.mak make file
; run in Linux
; no parameters
;------------------------------------------------------------
	bits 32               ; 32-bit assembler
	global _start         ; tell Linux what the entry point is
	section .text         ; read only, executable section
; the largest odd prime number in this program < (MAX*2)
; defines amount of virtual memory to reserve
; 0x08000000 matches the C program sieve.c
; 0x10000000 works in assembler but not in C
; 0x10000000 produces a segmentation error in C
MAX	equ 0x01000000   ; to match with C program
; MAX	equ 0x10000000   ; to generate more prime numbers
_start:
	call bldsv       ; initialize table of odd ordinal numbers
	call xout        ; cross out odd non-prime numbers (eg 9,15,21,...)
	call shw         ; print (partial) list of primes
	call tally       ; count number of primes in list
	                 ; The full list is too long to print
eoj:                     ; terminate the program
	mov eax,1        ; terminate the program
	xor ebx,ebx      ; RC=0
	int 0x80         ; syscall (operating system service)
	nop
	nop
	nop
	nop
;------------------------------------------------------------
; initialize a large table of odd ordinal numbers 3,5,7,...
; sv stands for "sieve of Eratosthenes"
; See wikipedia article for more information
;------------------------------------------------------------
bldsv:
	; push registers used onto stack
	; before the return instruction, they are popped
	; in the reverse order in which they are saved
	push eax
	push ebx
	push esi
	push edi
	mov esi,sv          ; point to beginning of table
	;----------------------------
	;------------------------------------
	; edi register points to end of table
	;------------------------------------
	mov edi,esi
	mov eax,MAX
	shl eax,2           ; size of each integer is 4 bytes
	; edi = esi + (MAX * 4)
	add edi,eax
	mov [svend],edi     ; save table end pointer
	;----------------------------
	mov eax,3           ; table of odd numbers 3,5,7,...
;--------------------------------------------------
; initialize table to odd ordinal numbers 3,5,7,...
;--------------------------------------------------
.lp:                        ; for each odd number 3,5,7,...
	mov [esi],eax       ; store ordinal# in table
	inc eax
	inc eax             ; next = current + 2
	add esi,4           ; next entry in table
	cmp esi,edi         ; end of table?
	jb .lp              ; no, repeat loop
	;---------------------------------------------
	; restore used registers from stack
	; in opposite order from which they were saved
	;---------------------------------------------
	pop edi
	pop esi
	pop ebx
	pop eax
	ret                 ; return to caller
;------------------------------------------------------------
; routine to cross out (zero out) all non-prime odd numbers
; in the table
; if the prime number is 3, cross out 9,15,21,27,...
;------------------------------------------------------------
xout:
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
	mov eax,3           ; first potential prime is 3
	mov [prm],eax       ; save current potential prime#
	mov eax,sv          ; point to beginning of table          
	mov [bgn],eax       ; save pointer
.lp:                        ; outer loop
	mov eax,[prm]       ; load current potential prime#
	shl eax,2           ; gap is prime * 4 bytes
	mov [gap],eax       ; save this number as the gap
	;---------------------------------------------
	; check if end of table has been reached
	;---------------------------------------------
	mov esi,[bgn]       ; current potential prime address
	mov edi,[svend]     ; load end of table pointer
	cmp esi,edi         ; reached end of table?
	jnb .done           ; yes, no more primes
	;---------------------------------------------
	; check if current number is non-prime
	; (already crossed out)
	; for example:  9,15,21,...
	;---------------------------------------------
	mov eax,[esi]       ; load current potential prime
	or eax,eax          ; has it been zeroed out?
	jz .nxt             ; yes, process next number
	;---------------------------------------------
	; the current number is prime (3,5,7,11,13,17,...)
	; point to the first odd multiple of the prime
	; for example, 9,15,21,...
	; the example here is based on prime number 3
	;---------------------------------------------
	mov ebx,[gap]       ; load the gap (12,20,28,...)
	add esi,ebx         ; first multiple
	cmp esi,edi         ; reached end of table?
	jnb .done           ; yes, no more primes
	xor eax,eax         ; zero constant
.lp2:                       ; inner loop
	mov [esi],eax       ; cross out odd nmultiple of prime
	add esi,ebx         ; point to next odd multiple of prime
	cmp esi,edi         ; end of table?
	jb .lp2             ; no, repeat inner loop
.nxt:                       ; set up next iteration of outer loop
	mov eax,[prm]       ; load the current prime
	inc eax
	inc eax             ; next potential odd prime = current + 2
	mov [prm],eax       ; store the new current potential prime
	mov eax,[bgn]       ; point to current starting position
	add eax,4           ; point to next starting position
	mov [bgn],eax       ; save next starting position
	jmp .lp             ; repeat outer loop
.done:
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
;------------------------------------------------------------
; Count the number of primes in the list
;------------------------------------------------------------
tally:
	push eax
	push ebx
	push esi
	mov esi,sv        ; point to beginning of table
	xor eax,eax
	inc eax           ; start with 3
	mov [kount],eax   ; initialize count to zero
.lp:
	mov eax,[esi]     ; test for prime number
	or eax,eax        ; number is zero?
	jz .nxt           ; yes, test next number
	mov eax,[kount]   ; not zero, tally number
	inc eax
	mov [kount],eax
.nxt:
	add esi,4         ; point to next number in list
	mov eax,esi
	mov ebx,svend
	cmp eax,ebx       ; reached end of list?
	jb .lp            ; no, repeat tally
	mov eax,tallymsg  ; print "total primes "
	call putstr       ; print to stderr
	call puttally     ; yes, print tally to stdout
	pop esi
	pop ebx
	pop eax
	ret
;------------------------------------------------------------
; print out a partial list of primes
; the algorithm here is to skip all but the last n primes
; print out the last n primes
;------------------------------------------------------------
shw:
	push eax
	push ebx
	push esi
	push edi
	xor eax,eax         ; initialize counter to zero
	mov [kount],eax
	; first prime number is 2
	; but it is not printed, for brevity
	; only the last n primes are printed
	mov esi,sv          ; point to beginning of table
	mov ebx,0x00fff000  ; bypass n primes for brevity
	shl ebx,2           ; size of number is 4 bytes
	add esi,ebx         ; point near end of table
	mov ebx,4           ; size of each number in bytes
	mov edi,[svend]     ; pointer to end of table
.lp:                        ; print loop
	mov eax,[esi]       ; load the prime number
	or eax,eax          ; has it been crossed out?
	jz .nxt             ; yes, find the next prime number
	mov [prime],eax
	call putprime       ; no, print the prime in decimal
	call puteol         ; print one prime per line
.nxt:                       ; point to the next prime
	add esi,ebx         ; add 4 bytes to prime pointer
	cmp esi,edi         ; end of table?
	jb .lp              ; no, repeat loop
	pop edi
	pop esi
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; print prime number in decimal
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
; print prime number count in decimal
;---------------------------------------------------
puttally:
	push eax
	push ebx
	push ecx
	push edx
	;-------------------------------------------
	; calculate units digit
	;-------------------------------------------
	xor edx,edx
	mov eax,[kount]
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
	call puterr                ; print digit
.pk3:
	mov eax,[dgtstk+32]        ; hundred millions digit
        add eax,0x30               ; convert to ASCII
	call puterr                ; print digit
.pk4:
	mov eax,[dgtstk+28]        ; ten millions digit
        add eax,0x30               ; convert to ASCII
	call puterr                ; print digit
.pk5:
	mov eax,[dgtstk+24]        ; millions digit
        add eax,0x30               ; convert to ASCII
	call puterr                ; print digit
.pk6:
	mov eax,[dgtstk+20]        ; hundred thousands digit
        add eax,0x30               ; convert to ASCII
	call puterr                ; print digit
.pk7:
	mov eax,[dgtstk+16]        ; ten thousands digit
        add eax,0x30               ; convert to ASCII
	call puterr                ; print digit
.pk8:
	mov eax,[dgtstk+12]        ; thousands digit
        add eax,0x30               ; convert to ASCII
	call puterr                ; print digit
.pk9:
	mov eax,[dgtstk+8]         ; hundreds digit
        add eax,0x30               ; convert to ASCII
	call puterr                ; print digit
.pk10:
	mov eax,[dgtstk+4]         ; tens digit
        add eax,0x30               ; convert to ASCII
	call puterr                ; print digit
.pk11:
	mov eax,[dgtstk]           ; units digit
        add eax,0x30               ; convert to ASCII
	call puterr                ; print digit
	mov al,10                  ; end of line char
	call puterr                ; print to stderr
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
; print string to stderr
;---------------------------------------------------
putstr:
	push eax
	push esi
	mov esi,eax        ; eax points to string
.lp:
	mov al,[esi]       ; current char in string
	or al,al           ; end of string?
	jz .done           ; yes, finish
	call puterr        ; no, print char to stdout
	inc esi            ; point to next char in string
	jmp .lp            ; repeat string loop
.done:
	pop esi
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
;---------------------------------------------------
; print one ASCII character to stderr
; extra caution is taken to preserve integrity of
; all working registers
; ebp register is assumed to be safe
;---------------------------------------------------
puterr:
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
	push ebp
	mov [chbuf],al  ; place character in its own buffer
	mov eax,4       ; write
	mov ebx,2       ; handle (stdout)
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
tallymsg: db 'Total primes ',0
	; reserved space for variable data
	; read/write, not executable
	section .bss
	align 16
chbuf	resb 4          ; print character buffer
prm:	resd 2          ; current prime number
gap:	resd 2          ; gap in bytes between multiples
bgn:	resd 2          ; current starting position in table
prime   resd 2          ; prime number to print
kount   resd 2          ; count of prime numbers in list
dgtstk  resd 32         ; decimal digit stack
sv:	resd MAX+MAX    ; table of odd numbers 3,5,7,...
svend:	resd 2          ; pointer to end of table
;---------------------------------------------------
; end of program
;---------------------------------------------------
