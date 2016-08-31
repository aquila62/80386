; knap.asm - Unbounded Knapsack Problem  Version 1.0.0
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
; Unbounded Knapsack Problem
; A knapsack is filled with three ingredients:
; 1. panacea (incredible healing properties)
; 2. ampules of ichor (Vampire's blood)
; 3. bars of gold (shiney gold)
; item       value    weight   volume
; panacea    3000      0.3     0.025
; ichor      1800      0.2     0.015
; gold       2500      2.0     0.002
; maximize value where weight <= 25 and volume <= 0.25
; Weights and volumes are converted to integers
; during computations.
; In this program there are four maximum results.
; They are all valid.
;------------------------------------------------------------
	bits 32               ; 32-bit assembler
	global _start         ; tell Linux what the entry point is
	section .text         ; read only, executable section
_start:
	mov esp,stkend   ; new stack address
	call maxmize     ; maximize the knapsack
eoj:                     ; terminate the program
	mov eax,1        ; terminate the program
	xor ebx,ebx      ; RC=0
	int 0x80         ; syscall (operating system service)
;---------------------------------------------------
; Maximize the contents of the knapsack
;---------------------------------------------------
maxmize:
	push eax
	push ebx
	xor eax,eax
	;---------------------------------------------------
	; Initialize all totals
	;---------------------------------------------------
	mov [tpwt],eax
	mov [tpvol],eax
	mov [tpval],eax
	mov [tiwt],eax
	mov [tivol],eax
	mov [tival],eax
	mov [tgwt],eax
	mov [tgvol],eax
	mov [tgval],eax
	mov [pan],eax
	mov [ich],eax
	mov [gld],eax
	mov [maxval],eax
	;---------------------------------------------------
	; cycle through panacea values
	;---------------------------------------------------
.lp:
	call doich            ; cycle through ichor values
	;---------------------------------------------------
	; increase panacea weight
	;---------------------------------------------------
	mov eax,[tpwt]
	mov ebx,[panwt]
	add eax,ebx
	mov [tpwt],eax
	mov ebx,250
	cmp eax,ebx
	ja .done
	;---------------------------------------------------
	; increase panacea volume
	;---------------------------------------------------
	mov eax,[tpvol]
	mov ebx,[panvol]
	add eax,ebx
	mov [tpvol],eax
	mov ebx,250
	cmp eax,ebx
	ja .done
	;---------------------------------------------------
	; increase panacea value
	;---------------------------------------------------
	mov eax,[tpval]
	mov ebx,[panval]
	add eax,ebx
	mov [tpval],eax
	;---------------------------------------------------
	; increase panacea count
	;---------------------------------------------------
	mov eax,[pan]
	inc eax
	mov [pan],eax
	jmp .lp            ; repeat panacea loop
.done:
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; ichor examples
;---------------------------------------------------
doich:
	push eax
	push ebx
.lp:
	call dogld            ; cycle through gold values
	;---------------------------------------------------
	; increase ichor weight
	;---------------------------------------------------
	mov eax,[tiwt]
	mov ebx,[ichwt]
	add eax,ebx
	mov [tiwt],eax
	mov ebx,250
	cmp eax,ebx
	ja .clr
	;---------------------------------------------------
	; increase ichor volume
	;---------------------------------------------------
	mov eax,[tivol]
	mov ebx,[ichvol]
	add eax,ebx
	mov [tivol],eax
	mov ebx,250
	cmp eax,ebx
	ja .clr
	;---------------------------------------------------
	; increase ichor value
	;---------------------------------------------------
	mov eax,[tival]
	mov ebx,[ichval]
	add eax,ebx
	mov [tival],eax
	;---------------------------------------------------
	; increase ichor count
	;---------------------------------------------------
	mov eax,[ich]
	inc eax
	mov [ich],eax
	jmp .lp             ; repeat ichor loop
.clr:                       ; zero ichor totals
	xor eax,eax
	mov [tiwt],eax
	mov [tivol],eax
	mov [tival],eax
	mov [ich],eax
	;---------------
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; gold examples
;---------------------------------------------------
dogld:
	push eax
	push ebx
.lp:
	call eval            ; evaluate the current state
	;---------------------------------------------------
	; increase gold weight
	;---------------------------------------------------
	mov eax,[tgwt]
	mov ebx,[gldwt]
	add eax,ebx
	mov [tgwt],eax
	mov ebx,250
	cmp eax,ebx
	ja .clr
	;---------------------------------------------------
	; increase gold volume
	;---------------------------------------------------
	mov eax,[tgvol]
	mov ebx,[gldvol]
	add eax,ebx
	mov [tgvol],eax
	mov ebx,250
	cmp eax,ebx
	ja .clr
	;---------------------------------------------------
	; increase gold value
	;---------------------------------------------------
	mov eax,[tgval]
	mov ebx,[gldval]
	add eax,ebx
	mov [tgval],eax
	;---------------------------------------------------
	; increase gold count
	;---------------------------------------------------
	mov eax,[gld]
	inc eax
	mov [gld],eax
	jmp .lp              ; repeat gold loop
.clr:                        ; zero gold totals
	xor eax,eax
	mov [tgwt],eax
	mov [tgvol],eax
	mov [tgval],eax
	mov [gld],eax
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; evaluate total value for the current state
;---------------------------------------------------
eval:
	push eax
	push ebx
        ;---------------------------------------------------
	; is total weight over the maximum?
        ;---------------------------------------------------
	mov eax,[tpwt]
	mov ebx,[tiwt]
	add eax,ebx
	mov ebx,[tgwt]
	add eax,ebx
	mov [totwt],eax
	mov ebx,250
	cmp eax,ebx
	ja .done           ; too heavy
        ;---------------------------------------------------
	; is total volume over the maximum?
        ;---------------------------------------------------
	mov eax,[tpvol]
	mov ebx,[tivol]
	add eax,ebx
	mov ebx,[tgvol]
	add eax,ebx
	mov [totvol],eax
	mov ebx,250
	cmp eax,ebx
	ja .done           ; too bulky
        ;---------------------------------------------------
	; compare total value to maximum
        ;---------------------------------------------------
	mov eax,[tpval]
	mov ebx,[tival]
	add eax,ebx
	mov ebx,[tgval]
	add eax,ebx
	mov [totval],eax
	mov ebx,[maxval]
	cmp eax,ebx
	jb .done              ; no new maximum value
	mov [maxval],eax      ; new maximum value
	call putmax           ; print new maximum value
.done:
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; print maximum value and counts of 3 ingredients
;---------------------------------------------------
putmax:
	push eax
        ;---------------------------------------------------
	; print maximum value in decimal
        ;---------------------------------------------------
	mov eax,vhdr
	call putstr
	mov eax,[totval]
	mov [prime],eax
	call putprime
        ;---------------------------------------------------
	; print panacea count in decimal
        ;---------------------------------------------------
	mov eax,phdr
	call putstr
	mov eax,[pan]
	mov [prime],eax
	call putprime
        ;---------------------------------------------------
	; print ichor count in decimal
        ;---------------------------------------------------
	mov eax,ihdr
	call putstr
	mov eax,[ich]
	mov [prime],eax
	call putprime
        ;---------------------------------------------------
	; print gold bar count in decimal
        ;---------------------------------------------------
	mov eax,ghdr
	call putstr
	mov eax,[gld]
	mov [prime],eax
	call putprime
	call puteol       ; print end of line
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
; print prime number count in decimal to stderr
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
	mov [chbuf],al  ; place character in its own buffer
	mov eax,4       ; write
	mov ebx,2       ; handle (stdout)
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
	; reserved space for constant data
	; read only, not executable
	section .data
	align 16
; binary to hex translate table
hxtbl:  db '0123456789ABCDEF'
panval:  dd 3000
ichval:  dd 1800
gldval:  dd 2500
panwt:   dd 3           ; tenths
ichwt:   dd 2           ; tenths
gldwt:   dd 20          ; tenths
maxwt:   dd 250         ; tenths
panvol:  dd 25          ; 1/1000
ichvol:  dd 15          ; 1/1000
gldvol:  dd 2           ; 1/1000
maxvol:  dd 250         ; 1/1000
vhdr:    db 'Maximum Value ',0
phdr:    db 'Panacea ',0
ihdr:    db 'Ichor ',0
ghdr:    db 'Gold ',0
	; reserved space for variable data
	; read/write, not executable
	section .bss
	align 16
chbuf	resb 4          ; print character buffer
prime   resd 1          ; number to print in decimal
pan     resd 1          ; number of panaceas
ich     resd 1          ; number of ichors
gld     resd 1          ; number of gold bars
tpval   resd 1          ; total panacea value
tival   resd 1          ; total ichor   value
tgval   resd 1          ; total gold    value
tpwt    resd 1          ; total panacea weight
tiwt    resd 1          ; total ichor   weight
tgwt    resd 1          ; total gold    weight
tpvol   resd 1          ; total panacea volume
tivol   resd 1          ; total ichor   volume
tgvol   resd 1          ; total gold    volume
totval  resd 1          ; total value
totwt   resd 1          ; total weight
totvol  resd 1          ; total volume
maxval  resd 1          ; maximum value obtained
kount   resd 2          ; count of prime numbers in list
dgtstk  resd 32         ; decimal digit stack
stack:  resd 2048       ; reserve program stack
stkend: resd 1          ; top of program stack
;---------------------------------------------------
; end of program
;---------------------------------------------------
