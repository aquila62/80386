; twr.asm - Solve the Tower of Hanoi Puzzle Version 1.0.0
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
; Tower of Hanoi puzzle
; recursive algorithm
; number of moves is 2^n-1
; see Wikipedia for the rules to solve the puzzle.
; written in NASM 32-bit assembler
; creates ELF object
; link with ld
; compile with twr.mak make file
; run in Linux
; Usage:
; echo #disks | twr | less
; Example:
; echo 5 | twr | less
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
	mov [prmstk],esp      ; save runtime stack
	mov esp,stkend        ; create new program stack
        ;------------------------------------------------------------
	; initialize move count to zero
        ;------------------------------------------------------------
	xor eax,eax
	mov [kount],eax
        ;------------------------------------------------------------
	; read the total number of disks from stdin
        ;------------------------------------------------------------
	call getparm
        ;------------------------------------------------------------
	; place all the disks on the A stack
	; the B and C stacks are empty
	; the order of then disks is largest to smallest
        ;------------------------------------------------------------
	call bld
        ;------------------------------------------------------------
	; print the original Tower of Hanoi state
        ;------------------------------------------------------------
	call shw
        ;------------------------------------------------------------
	; make the initial move call with 4 parameters
	; movedsk(n,source,target,auxiliary)
        ;------------------------------------------------------------
	mov eax,stkb          ; parm 4
	push eax
	mov eax,stkc          ; parm 3
	push eax
	mov eax,stka          ; parm 2
	push eax
	mov eax,[totdsks]     ; parm 1
	push eax
	call movedsk          ; top level recursive call
	add esp,16            ; restore the stack
        ;------------------------------------------------------------
	call shw              ; print final state
	call puteol           ; print final end of line
eoj:                     ; terminate the program
	mov eax,1        ; terminate the program
	xor ebx,ebx      ; RC=0
	int 0x80         ; syscall (operating system service)
	nop
	nop
	nop
	nop
;---------------------------------------------------
; read total disks from stdin
; total disks is a single digit
;---------------------------------------------------
getparm:
	push eax
	push ebx
        ;---------------------------------------------------
	; get input parameter from stack
	; prmstk contains address of argc
	; prmstk+4 contains address of argv[0]
	; prmstk+8 contains address of argv[1]
        ;---------------------------------------------------
	mov ebx,[prmstk]       ; ebx = runtime stack address
	mov eax,[ebx]          ; eax = parm count argc
	cmp eax,2              ; one parameter?
	jnz .err               ; no, print usage
	add ebx,8              ; ebx = address of argv[1]
	mov eax,[ebx]          ; eax points to argv[1] string
	mov ebx,eax            ; ebx points to argv[1] string
	mov al,[ebx]           ; 1st character in 1st parm
	sub al,0x30            ; convert ASCII to binary
	cmp al,2               ; less than 2?
	jb .err                ; yes, print usage
	cmp al,9               ; greater than 9?
	ja .err                ; yes, print usage
	xor ebx,ebx            ; clear high order 24 bits
	mov bl,al              ; ebx = total disks
	mov [totdsks],ebx      ; store totdsks
	pop ebx
	pop eax
	ret
.err:
	call usage       ; invalid #disks, print usage
	jmp eoj          ; and quit
;---------------------------------------------------
; print usage protocol
;---------------------------------------------------
usage:
	push eax
	mov eax,usagemsg
	call putstr              ; print string
	pop eax
	ret
;---------------------------------------------------
; populate stack A with n disks
;---------------------------------------------------
bld:
	push eax
	push ebx
	push ecx
	mov al,[totdsks]          ; save total #disks
	mov [stka],al             ; in stack A header
	mov ebx,stka+1            ; point to first disk in stack
	mov ecx,[totdsks]         ; loop counter = totdsks
.lpa:
	mov al,cl                 ; save disk number
	mov [ebx],al              ; in stack
	inc ebx                   ; point to next disk in stack
	dec cl                    ; disk# = disk# - 1
	or cl,cl                  ; disk# = zero?
	jnz .lpa                  ; no, repeat loop
	mov ecx,6                 ; loop counter
.lpa2:                            ; loop to add zeros at end of stack
	xor al,al                 ; al = 0
	mov [ebx],al              ; store zero at end of stack
	inc ebx                   ; point to next disk in stack
	loop .lpa2                ; repeat loop
	mov ebx,stkb              ; point to stack B header
	mov ecx,16                ; size of stack B
.lpb:                             ; stack B loop
	xor al,al                 ; al = 0
	mov [ebx],al              ; store zero in stack B
	inc ebx                   ; point to next disk in stack
	loop .lpb                 ; repeat loop ecx times
	mov ebx,stkc              ; point to stack C header
	mov ecx,16                ; size of stack C
.lpc:                             ; stack C loop
	xor al,al                 ; al = 0
	mov [ebx],al              ; store zero in stack C
	inc ebx                   ; point to next disk in stack
	loop .lpc                 ; repeat loop ecx times
	pop ecx
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; recursive move routine
; step1. movedsk(n-1,source,auxiliary,target);
; step2. move disk n from source to target
; step3. movedsk(n-1,auxiliary,target,source);
;---------------------------------------------------
movedsk:
	push ebp
	mov ebp,esp      ; ebp points to parameter list - 8
	push eax
	push ebx
	;---------------------------------------------------
	; if first parm (n) < 1
	; return
	;---------------------------------------------------
	mov eax,[ebp+8]     ; check value of n
	cmp eax,0x01        ; is parm 1 less than 1?
	jb .done            ; yes, return
	;---------------------------------------------------
        ; step1. movedsk(n-1,source,auxiliary,target);
	; new parm4     = current parm3 
	; new auxiliary = current target
	;---------------------------------------------------
	mov eax,[ebp+8+8]    ; input target stack
	mov [parm4],eax      ; new auxiliary stack
	;---------------------------------------------------
	; new parm3     = current parm4 
	; new target    = current auxiliary
	;---------------------------------------------------
	mov eax,[ebp+8+12]   ; input auxiliary stack
	mov [parm3],eax      ; new target stack
	;---------------------------------------------------
	; new parm2     = current parm2 
	; new source    = current source
	;---------------------------------------------------
	mov eax,[ebp+8+4]    ; input source stack
	mov [parm2],eax      ; new source stack
	;---------------------------------------------------
	; new parm1     = current parm1 minus one 
	; new n         = current n-1
	;---------------------------------------------------
	mov eax,[ebp+8]      ; input number of disks n
	dec eax              ; minus one
	mov [parm1],eax      ; new number of disks n-1
	;---------------------------------------------------
	; make recursive call with 4 parameters
	;---------------------------------------------------
	mov eax,[parm4]
	push eax             ; push parm 4
	mov eax,[parm3]
	push eax             ; push parm 3
	mov eax,[parm2]
	push eax             ; push parm 2
	mov eax,[parm1]
	push eax             ; push parm 1
	call movedsk         ; recursive call to movedsk
	add esp,16           ; restore the stack
	;---------------------------------------------------
	; move disk n from source to target
	; first pop stka
	;---------------------------------------------------
	mov ebx,[ebp+8+4]       ; current source stack
	xor eax,eax             ; zero the eax reg
	mov al,[ebx]            ; al = number of disks in source stack
	add ebx,eax             ; point to end of source stack
	mov al,[ebx]            ; pop top of source stack
	mov [popdsk],al         ; save disk in popdsk
	xor eax,eax             ; replace stack with zero
	mov [ebx],al            ; replace end of stack
	mov ebx,[ebp+8+4]       ; point to source stack header
	mov al,[ebx]            ; al = stack header 
	or al,al                ; is stack header zero?
	jnz .noufl              ; no, continue
	call underflow          ; yes, print underflow message
	jmp eoj                 ; quit
.noufl:                         ; stack header greater than zero
	dec al                  ; stack header minus 1
	mov [ebx],al            ; save stack header
	;---------------------------------------------------
	; move disk n from source to target
	; push popped disk onto target stack
	;---------------------------------------------------
	mov ebx,[ebp+8+8]       ; point to target stack header
	mov al,[ebx]            ; al = target stack header
	inc al                  ; al = al + 1
	mov [ebx],al            ; save stack header
	add ebx,eax             ; point to top of stack + 1
	mov al,[popdsk]         ; al = popped source disk
	mov [ebx],al            ; push source disk onto target stack
	inc ebx                 ; point to next disk in stack
	xor al,al               ; al = zero
	mov [ebx],al            ; zero next disk in stack
	;---------------------------------------------------
	; print the current Tower of Hanoi state
	;---------------------------------------------------
	mov eax,[kount]         ; add 1 to move count
	inc eax
	mov [kount],eax
	call putkount           ; print move count in decimal
	call puteol             ; print end of line
	call shw                ; print three stacks
	;---------------------------------------------------
        ; step3. movedsk(n-1,auxiliary,target,source);
	; new parm4     = current parm1 
	; new auxiliary = current source
	;---------------------------------------------------
	mov eax,[ebp+8+4]    ; input source stack
	mov [parm4],eax      ; new auxiliary stack
	;---------------------------------------------------
	; new parm3     = current parm3 
	; new target    = current target
	;---------------------------------------------------
	mov eax,[ebp+8+8]    ; input target stack
	mov [parm3],eax      ; new target stack
	;---------------------------------------------------
	; new parm2     = current parm4 
	; new source    = current auxiliary
	;---------------------------------------------------
	mov eax,[ebp+8+12]   ; input auxiliary stack
	mov [parm2],eax      ; new source stack
	;---------------------------------------------------
	; new parm1     = current parm1 minus one 
	; new n         = current n-1
	;---------------------------------------------------
	mov eax,[ebp+8]      ; input number of disks n
	dec eax              ; minus one
	mov [parm1],eax      ; new number of disks n-1
	;---------------------------------------------------
	; make recursive call with 4 parameters
	;---------------------------------------------------
	mov eax,[parm4]
	push eax             ; push parm 4
	mov eax,[parm3]
	push eax             ; push parm 3
	mov eax,[parm2]
	push eax             ; push parm 2
	mov eax,[parm1]
	push eax             ; push parm 1
	call movedsk         ; recursive call to movedsk
	add esp,16           ; restore the stack
	;---------------------------------------------------
.done:
	pop ebx
	pop eax
	pop ebp
	ret
;---------------------------------------------------
; print underflow message, quit
;---------------------------------------------------
underflow:
	push eax
	mov eax,uflmsg
	call putstr          ; print string
	pop eax
	ret
;---------------------------------------------------
; print state of Tower of Hanoi
; print contents of each stack from bottom to top 
;---------------------------------------------------
shw:
	push eax
	push ebx
	mov al,'A'           ; print A stack
	call putchar
	call putspc
	mov ebx,stka+1       ; point to bottom of stack
.lpa:
	mov al,[ebx]         ; al = disk
	or al,al             ; disk = 0?
	jz .lpa2             ; yes, print A stack
	add al,0x30          ; no, print disk in ASCII
	call putchar
	call putspc
	inc ebx              ; point to next disk
	jmp .lpa             ; repeat loop
.lpa2:
	call puteol
	mov al,'B'           ; print B stack
	call putchar
	call putspc
	mov ebx,stkb+1       ; point to bottom of stack
.lpb:
	mov al,[ebx]         ; al = disk
	or al,al             ; disk = 0?
	jz .lpb2             ; yes, print B stack
	add al,0x30          ; no, print disk in ASCII
	call putchar
	call putspc
	inc ebx              ; point to next disk
	jmp .lpb             ; repeat loop
.lpb2:
	call puteol
	mov al,'C'           ; print C stack
	call putchar
	call putspc
	mov ebx,stkc+1       ; point to bottom of stack
.lpc:
	mov al,[ebx]         ; al = disk
	or al,al             ; disk = 0?
	jz .lpc2             ; yes, print C stack
	add al,0x30
	call putchar
	call putspc
	inc ebx              ; point to next disk
	jmp .lpc             ; repeat loop
.lpc2:
	call puteol
	call putdash         ; print dashes at end
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; print 16 dashes followed by eol
;---------------------------------------------------
putdash:
	push eax
	push ecx
	xor eax,eax
	mov ecx,16           ; loop counter
.lp:
	mov al,'-'           ; print dash
	call putchar
	loop .lp             ; repeat loop
	call puteol          ; print end of line
	pop ecx
	pop eax
	ret
;---------------------------------------------------
; print kount in decimal
;---------------------------------------------------
putkount:
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
	xor edx,edx
        ;---------------------------------------------------
        ; print digits from stack
        ;---------------------------------------------------
	mov eax,[dgtstk+12]        ; thousands digit
	or eax,eax                 ; zero?
	jnz .pk2                   ; no, print 4 digits
	mov eax,[dgtstk+8]         ; hundreds digit
	or eax,eax                 ; zero?
	jnz .pk3                   ; no, print 3 digits
	mov eax,[dgtstk+4]         ; tens digit
	or eax,eax                 ; zero?
	jnz .pk4                   ; no, print 2 digits
	jmp .pk5                   ; yes, print 1 digit
.pk2:
	mov eax,[dgtstk+12]        ; thousands digit
        add eax,0x30               ; convert to ASCII
	call putchar               ; print digit
.pk3:
	mov eax,[dgtstk+8]         ; hundreds digit
        add eax,0x30               ; convert to ASCII
	call putchar               ; print digit
.pk4:
	mov eax,[dgtstk+4]         ; tens digit
        add eax,0x30               ; convert to ASCII
	call putchar               ; print digit
.pk5:
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
promptmsg: db 'Enter number of disks: ',0
usagemsg:  db 'Usage: twr #disks',0x0a
           db 'Where #disks is 2-9',0x0a
           db 'Example twr 7',0x0a,0
uflmsg:    db 'Stack underflow',0x0a,0
	;---------------------------------
	; reserved space for variable data
	; read/write, not executable
	;---------------------------------
	section .bss
	align 16
chbuf	resb 4          ; print character buffer
kbbuf	resb 4          ; print character buffer
dgtstk  resd 16         ; decimal digit stack
prmstk  resd 1          ; runtime parameter stack address
parm1   resd 1          ; recursive call parm 1
parm2   resd 1          ; recursive call parm 2
parm3   resd 1          ; recursive call parm 3
parm4   resd 1          ; recursive call parm 4
totdsks resd 1          ; total number of disks
kount   resd 1          ; move count
popdsk  resb 4          ; popped source disk
stka    resb 16         ; stack A
stkb    resb 16         ; stack B
stkc    resb 16         ; stack C
stack   resb 16384      ; recursive program stack
stkend  resb 4          ; highest address of stack
