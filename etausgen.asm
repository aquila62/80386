; etausgen.asm - Extended Taus Generator  Version 1.0.0
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
	call init           ; initialize etaus to date time
	call gen            ; generate random bits
eoj:
	mov eax,1           ; exit
	xor ebx,ebx         ; rc = 0
	int 0x80            ; syscall
	nop
	nop
	nop
	nop
;---------------------------------------------------
; generate random bits
;---------------------------------------------------
gen:
	push eax
.lp:
	call etaus            ; next etaus generation
	mov eax,[outpt]       ; eax = etaus output
	and eax,1             ; capture low order bit
	add eax,0x30          ; convert to ASCII
	call putchar          ; print bit
	jmp .lp               ; repeat loop
	pop eax
	ret
;---------------------------------------------------
; initialize etaus state to date & time
;---------------------------------------------------
init:
	push eax
	push ebx
	push ecx
	push edx
	mov eax,13         ; get seconds since epoch
	xor ebx,ebx        ; NULL parameter
	int 0x80           ; syscall
	mov [secs],eax     ; save seconds since epoch
	mov [s1],eax       ; s1 = secs
	mov ebx,eax        ; ebx = eax
	shr eax,8          ; shift eax right  8 bits
	shl ebx,24         ; shift ebx left  24 bits
	or eax,ebx         ; eax rotated 8 bits to right
	mov [s2],eax       ; s2 = secs rotated 8 bits
	mov ebx,eax        ; ebx = eax
	shr eax,8          ; shift eax right  8 bits
	shl ebx,24         ; shift ebx left  24 bits
	or eax,ebx         ; eax rotated 8 bits to right
	mov [s3],eax       ; s3 = secs rotated 16 bits
	call taus          ; generate taus output
	mov eax,[outpt]    ; eax = taus output
	mov [prev],eax     ; prev = random 32-bit number
	call taus          ; generate taus output
	mov eax,[outpt]    ; eax = taus output
	mov [pprev],eax    ; pprev = random 32-bit number
	call bldtbl        ; build the etaus state table
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; initialize the etaus state table with random data
;---------------------------------------------------
bldtbl:
	push eax
	push ebx
	push ecx
	push edi
	mov edi,tbl           ; point to the table
	mov ecx,1024          ; table size = 1024 numbers
.lp:                          ; table loop
	call taus             ; generate taus output
	mov eax,[outpt]       ; eax = taus output
	mov ebx,[prev]        ; eax = output ^ prev ^ pprev
	xor eax,ebx
	mov ebx,[pprev]
	xor eax,ebx
	mov [edi],eax         ; save eax in table
	mov eax,[prev]        ; shift current to previous
	mov [pprev],eax
	mov eax,[outpt]
	mov [prev],eax
	add edi,4             ; point to next entry in table
	loop .lp              ; repeat loop 1024 times
	pop edi
	pop ecx
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; calculate taus
; this is the taus algorithm
;---------------------------------------------------
taus:
	push eax
	push ebx
	call tausone
	call taustwo
	call taustri
	mov eax,[s1]
	mov ebx,[s2]
	xor eax,ebx
	mov ebx,[s3]
	xor eax,ebx
	mov [outpt],eax
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; calculate extended taus
; the extended taus algorithm is called etaus
; etaus is taus with the Bays-Durham Shuffle
;---------------------------------------------------
etaus:
	push eax
	push ebx
	push esi
	mov eax,[pprev]         ; index to the state table
	and eax,0x3ff
	mov [indx],eax
	mov eax,[prev]          ; shift current to previous
	mov [pprev],eax
	mov eax,[outpt]
	mov [prev],eax
	call taus               ; generate taus output
	mov eax,[outpt]         ; xor output with prev and pprev
	mov ebx,[prev]
	xor eax,ebx
	mov ebx,[pprev]
	xor eax,ebx
	mov [outpt],eax         ; new output before shuffle
	;-----------------------------------
	; Bays-Durham Shuffle
	;-----------------------------------
	mov esi,tbl             ; point to entry in table
	mov eax,[indx]
	shl eax,2
	add esi,eax
	mov ebx,[esi]           ; swap current output
	mov eax,[outpt]         ; with entry in table
	mov [esi],eax
	mov [outpt],ebx
	pop esi
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; calculate tausone
; first step in taus algorithm
; calculate s1
; #define TAUSONE (et->s1 = (((et->s1&0xfffffffe)<<12) \
;       ^(((et->s1<<13)^et->s1)>>19)))
;---------------------------------------------------
tausone:
	push eax
	push ebx
	mov eax,[s1]
	and eax,0xfffffffe
	shl eax,12
	mov [aa1],eax
	mov eax,[s1]
	shl eax,13
	mov [bb1],eax
	mov ebx,[s1]
	xor eax,ebx
	mov [cc1],eax
	shr eax,19
	mov [dd1],eax
	mov eax,[aa1]
	mov ebx,[dd1]
	xor eax,ebx
	mov [s1],eax
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; calculate taustwo
; second step in taus algorithm
; calculate s2
; #define TAUSTWO (et->s2 = (((et->s2&0xfffffff8)<< 4) \
;       ^(((et->s2<< 2)^et->s2)>>25)))
;---------------------------------------------------
taustwo:
	push eax
	push ebx
	mov eax,[s2]
	and eax,0xfffffff8
	shl eax,4
	mov [aa2],eax
	mov eax,[s2]
	shl eax,2
	mov [bb2],eax
	mov ebx,[s2]
	xor eax,ebx
	mov [cc2],eax
	shr eax,25
	mov [dd2],eax
	mov eax,[aa2]
	mov ebx,[dd2]
	xor eax,ebx
	mov [s2],eax
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; calculate tausthree
; third step in taus algorithm
; calculate s3
; #define TAUSTRI (et->s3 = (((et->s3&0xfffffff0)<<17) \
;       ^(((et->s3<< 3)^et->s3)>>11)))
;---------------------------------------------------
taustri:
	push eax
	push ebx
	mov eax,[s3]
	and eax,0xfffffff0
	shl eax,17
	mov [aa3],eax
	mov eax,[s3]
	shl eax,3
	mov [bb3],eax
	mov ebx,[s3]
	xor eax,ebx
	mov [cc3],eax
	shr eax,11
	mov [dd3],eax
	mov eax,[aa3]
	mov ebx,[dd3]
	xor eax,ebx
	mov [s3],eax
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; print etaus state
; stub routine
;---------------------------------------------------
shwstate:
	push eax
	push ebx
	push ecx
	push edx
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
secs    resd 1          ; seconds since the epoch
s1      resd 1          ; taus s1
s2      resd 1          ; taus s2
s3      resd 1          ; taus s3
aa1     resd 1          ; taus work area
bb1     resd 1          ; taus work area
cc1     resd 1          ; taus work area
dd1     resd 1          ; taus work area
aa2     resd 1          ; taus work area
bb2     resd 1          ; taus work area
cc2     resd 1          ; taus work area
dd2     resd 1          ; taus work area
aa3     resd 1          ; taus work area
bb3     resd 1          ; taus work area
cc3     resd 1          ; taus work area
dd3     resd 1          ; taus work area
tbl     resd 1024       ; state table
indx    resd 1          ; index into state table
outpt   resd 1          ; current  output
prev    resd 1          ; previous output
pprev   resd 1          ; previous previous output
stack   resd 2048       ; program stack
stkend  resd 4          ; highest address of stack
