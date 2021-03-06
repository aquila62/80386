; eeglgen.asm - Extended Eegl Generator  Version 1.0.0
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
	call init           ; initialize eegl to date time
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
	call eegl             ; next eegl generation
	call xorbit           ; xor the output into a single bit
	mov eax,[bit]
	add eax,0x30          ; convert to ASCII
	call putchar          ; print bit
	jmp .lp               ; repeat loop
	pop eax
	ret
;---------------------------------------------------
; initialize eegl state to date & time
;---------------------------------------------------
init:
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
	push ebp
	mov eax,13         ; get seconds since epoch
	xor ebx,ebx        ; NULL parameter
	int 0x80           ; syscall
	mov [secs],eax     ; save seconds since epoch
	mov [lfsr],eax     ; first lfsr = secs
	call bldint
	mov eax,[rndint]
	mov [prev],eax
	call bldint
	mov eax,[rndint]
	mov [pprev],eax
	call bldtbl        ; build the eegl state table
	pop ebp
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; initialize the eegl state table with random data
;---------------------------------------------------
bldtbl:
	push eax
	push ebx
	push ecx
	push edi
	mov edi,tbl           ; point to the table
	mov ecx,1024          ; table size = 1024 numbers
.lp:                          ; table loop
	call bldint           ; generate eegl output
	mov eax,[rndint]      ; eax = eegl lfsr
	mov [edi],eax         ; save eax in table
	add edi,4             ; point to next entry in table
	loop .lp              ; repeat loop 1024 times
	pop edi
	pop ecx
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; create random 32-bit integer
;---------------------------------------------------
bldint:
	push eax
	push ebx
	push ecx
	xor ebx,ebx
	mov ecx,32
.lp:
	call calclfsr
	mov eax,[bit]
	shl ebx,1
	or eax,ebx
	mov ebx,eax
	loop .lp
	mov [rndint],ebx
	mov eax,ebx
	pop ecx
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; calculate new lfsr
;---------------------------------------------------
calclfsr:
	push eax
	push ebx
	mov eax,[lfsr]
	shr eax,31
	mov [s1],eax
	mov eax,[lfsr]
	shr eax,30
	mov [s2],eax
	mov eax,[lfsr]
	shr eax,10
	mov [s3],eax
	; xor the tap bits together
	mov eax,[lfsr]
	mov ebx,[s1]
	xor eax,ebx
	mov ebx,[s2]
	xor eax,ebx
	mov ebx,[s3]
	xor eax,ebx
	and eax,1
	mov [bit],eax
	;-----------------------------------------
	; roll the lfsr
	; place the output bit just created
	; in the top position to create a new lfsr
	;-----------------------------------------
	mov ebx,eax
	shl ebx,31
	mov eax,[lfsr]
	shr eax,1
	or eax,ebx
	mov [lfsr],eax
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; calculate extended eegl
; the extended eegl algorithm is called eegl
; eegl is eegl with the Bays-Durham Shuffle
;---------------------------------------------------
eegl:
	push eax
	push ebx
	push esi
	mov eax,[pprev]         ; index to the state table
	shr eax,22              ; grab upper 10 bits
	mov [indx],eax          ; index into state table
	mov eax,[prev]          ; shift current to previous
	mov [pprev],eax
	mov eax,[outpt]
	mov [prev],eax
	call calclfsr           ; generate new lfsr
	;-----------------------------------
	; Bays-Durham Shuffle
	;-----------------------------------
	mov esi,tbl             ; point to entry in table
	mov eax,[indx]
	shl eax,2
	add esi,eax
	mov ebx,[esi]           ; swap current lfsr
	mov eax,[lfsr]          ; with entry in table
	mov [esi],eax
	mov [lfsr],ebx
	;-------------------------------------------------------
	; xor previous two outputs with current lfsr
	; to create new output
	;-------------------------------------------------------
	mov eax,[lfsr]          ; xor lfsr with prev and pprev
	mov ebx,[prev]
	xor eax,ebx
	mov ebx,[pprev]
	xor eax,ebx
	mov [outpt],eax         ; new output after shuffle
	pop esi
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; xor the lfsr into a single bit
;---------------------------------------------------
xorbit:
	push eax
	push ebx
	push ecx
	mov ebx,[outpt]
	mov ecx,31
.lp:
	mov eax,ebx
	shr ebx,1
	xor eax,ebx
	loop .lp
	and eax,1
	mov [bit],eax
	pop ecx
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; print eegl state
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
	push esi
	push edi
	push ebp
	mov eax,3        ; read input withn wait
	mov ebx,0        ; stdin
	mov ecx,kbbuf    ; buf
	mov edx,1        ; length
	int 0x80         ; syscall
	cmp al,'q'       ; q?
	jz eoj           ; yes, quit
	cmp al,0x1a      ; CTL-Z?
	jz eoj           ; yes, quit
	pop ebp
	pop edi
	pop esi
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
lfsr    resd 1          ; eegl linear feedback register
bit     resd 1          ; eegl linear feedback register
rndint  resd 1          ; eegl linear feedback register
s1      resd 1          ; eegl linear feedback register
s2      resd 1          ; eegl linear feedback register
s3      resd 1          ; eegl linear feedback register
tbl     resd 1024       ; state table
indx    resd 1          ; index into state table
tmp     resd 1          ; temporary lfsr for Bays-Durham shuffle
outpt   resd 1          ; current  output
prev    resd 1          ; previous output
pprev   resd 1          ; previous previous output
stack   resd 2048       ; program stack
stkend  resd 4          ; highest address of stack
