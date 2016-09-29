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
	mov ebp,esp         ; save address of esp
	mov [stk],esp       ; save address of argc and argv
	mov eax,[ebp]       ; eax = argc
	mov [argc],eax      ; save argc
	call puteax         ; print argc in hex
	call puteol         ; print end of line
	call getparms
eoj:
	mov eax,1           ; exit
	xor ebx,ebx         ; rc = 0
	int 0x80            ; syscall
	nop
	nop
	nop
	nop
;-----------------------------------------------------
; print the parms **argv and the environment variables
;-----------------------------------------------------
getparms:
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
	mov esi,[stk]
	add esi,4
	mov [argv],esi
.lp:                            ; outer loop for each parm
	mov edi,[esi]           ; edi = parm address
.lp2:                           ; inner loop for each char in parm
	mov al,[edi]            ; al = char in parm
	or al,al                ; end of string?
	jz .nxt                 ; yes, print next parm
	call putchar            ; no, print character
	inc edi                 ; point to next char
	jmp .lp2                ; repeat inner loop
.nxt:
	call puteol             ; print end of line
	add esi,4               ; point to next parm
	mov eax,[esi]           ; is next parm address zero?
	or eax,eax
	jnz .lp                 ; no, print next parm
	add esi,4               ; yes, point to first env var
        ;-----------------------------------------------------
	; print environment variables
        ;-----------------------------------------------------
.lp3:                           ; outer loop for env var
	mov edi,[esi]           ; point to env var
	or edi,edi              ; end of env variable list?
	jz .done                ; yes, finish
.lp4:                           ; inner loop for env var
	mov al,[edi]            ; al = env var char
	or al,al                ; end of env var?
	jz .nxt2                ; yes, next env var
	call putchar            ; print env var char
	inc edi                 ; point to next char in env var
	jmp .lp4                ; repeat inner loop
.nxt2:                          ; get next env var
	call puteol             ; print end of line
	add esi,4               ; point to next env var
	jmp .lp3                ; print next env var
.done:                          ; finish
	pop edi                 ; return to mainline
	pop esi                 ; return to mainline
	pop edx                 ; return to mainline
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
stk     resd 1          ; run time stack address
argc    resd 1          ; argc
argv    resd 1          ; **argv
stack   resb 8192       ; recursive program stack
stkend  resb 4          ; highest address of stack
