; knap01.asm - Knapsack 0/1 Problem  Version 1.0.0
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
; Knapsack 0/1 Problem
; This is a recursive program.
; A knapsack is filled with ingredients from knap01.rc
; See knap01.rc for the ingredients used in this test.
; Only one unit of each item may be added to the knapsack.
; maximize value where weight <= 400 decagrams.
; 400 is stored in the variable maxwgt (maximum weight).
; This program produces 2779 lines of output
; and computes 4194304 different combinations to arrive
; at the maximum value of 1030 for 12 ingredients.
;
; Usage:
;
; knap01
; knap01 | less
; knap01 | tail -15 
;------------------------------------------------------------
	bits 32               ; 32-bit assembler
	global _start         ; tell Linux what the entry point is
	section .text         ; read only, executable section
_start:
	mov esp,stkend     ; new stack address
	call init          ; zero out header,weight,value arrays
	call fill          ; read knap01.rc into the arrays       
	; the bit array is the array of 0/1 choices
	call bitinit       ; initialize bit array to zero
	xor eax,eax        ; eax = 0
	; maxval is the value that is maximized by the program
	mov [maxval],eax   ; initialize maximum value to zero
	xor eax,eax        ; n = 0  (n is index to lists)
	push eax           ; 1st parameter n = 0..(kount-1)
	call maxmize       ; maximize the knapsack (recursive)
	pop eax            ; pop the 1st parameter
eoj:                       ; terminate the program
	mov eax,1          ; terminate the program
	xor ebx,ebx        ; RC=0
	int 0x80           ; syscall (operating system service)
	nop
	nop
	nop
	nop
;---------------------------------------------------
; Recursive routine
; Maximize the contents of the knapsack
;---------------------------------------------------
maxmize:
	push ebp
	mov ebp,esp
	push eax
	push ebx
	push esi
	mov eax,[ebp+8]       ; n (0..21)
	mov [enn],eax         ; save the current value of n
	mov ebx,[kount]       ; calculate max n-1
	dec ebx               ; max n-1 = count-1
	cmp eax,ebx           ; n =< kount?
	; in this test kount = 22
	; the index goes from 0 to 21
	jz .max1              ; n = count-1, evaluate result
	jb .max2              ; n < count-1, continue recursion
	jmp .max9             ; n > count-1, return from recursion
.max1:
	;-------------------------------------------------
	; see if the maximum value has been reached so far
	; bitlst[kount-1] = 0
	;-------------------------------------------------
	mov ebx,[kount]       ; kount = 22
	dec ebx               ; kount-1 = 21
	mov esi,bitlst        ; address of bitlst
	add esi,ebx           ; address of bitlst[kount-1]
	xor al,al             ; al = 0
	mov [esi],al          ; bitlst[kount-1] = 0
	call eval             ; evaluate the current state
	;-------------------------------------------------
	; set bitlst[kount-1] = 1
	;-------------------------------------------------
	mov ebx,[kount]       ; kount = 22
	dec ebx               ; kount-1 = 21
	mov esi,bitlst        ; address of bitlst
	add esi,ebx           ; address of bitlst[kount-1]
	mov al,1              ; al = 1
	mov [esi],al          ; bitlst[kount-1] = 1
	call eval             ; evaluate the current state again
	;-------------------------------------------------
	; reset bitlst[kount-1] = 0
	; This is redundant, so that the state at a higher
	; level of recursion will show a zero in the last
	; bit.
	;-------------------------------------------------
	mov ebx,[kount]       ; kount = 22
	dec ebx               ; kount-1 = 21
	mov esi,bitlst        ; address of bitlst
	add esi,ebx           ; address of bitlst[kount-1]
	xor al,al             ; al = 0
	mov [esi],al          ; bitlst[kount-1] = 0
	jmp .max9             ; return from recursion
.max2:
	;----------------------------------------------------
	; n < kount-1
	; The lowest level of recursion has not yet been
	; reached.
	; set bitlst[n] = 0
	;----------------------------------------------------
	mov eax,[ebp+8]    ; 1st parameter = n
	mov esi,bitlst     ; esi = address of bitlst
	add esi,eax        ; esi = address of bitlst[n]
	xor bl,bl          ; bl = 0
	mov [esi],bl       ; bitlst[n] = 0
	;----------------------------------------------------
	; call maxmize recursively with a parameter n+1
	; and bitlst[n] = 0
	;----------------------------------------------------
	inc eax            ; eax = n + 1
	push eax           ; 1st parameter = n + 1
	call maxmize       ; recursive call
	pop eax            ; pop the 1st parameter
	;----------------------------------------------------
	; now call maxmize recursively again with parameter n+1
	; and bitlst[n] = 1
	;----------------------------------------------------
	mov esi,bitlst     ; esi = address of bitlst
	mov eax,[ebp+8]    ; 1st parameter = n
	add esi,eax        ; esi = address of bitlst[n]
	mov al,1           ; al = 1
	mov [esi],al       ; bitlst[n] = 1
	;-------------------------------------
	mov eax,[ebp+8]    ; 1st parameter = n
	inc eax            ; eax = n+1
	push eax           ; 1st parameter = n + 1
	call maxmize       ; recursive call
	pop eax            ; pop the 1st parameter
.max9:                     ; return from recursion
	pop esi
	pop ebx
	pop eax
	pop ebp
	ret
;---------------------------------------------------
; evaluate total value for the current state
; sum the total weight of chosen ingredients
; validate that total weight <= maxwght
; In this test maxwgt = 400
; sum the total value  of chosen ingredients
; If total value >= maxval so far, print
; the chose ingredients of the current state.
; along with the current maximum value up to this point.
;---------------------------------------------------
eval:
	push eax
	push ebx
	;------------------------------------------
	; initialize total weight and value to zero
	;------------------------------------------
	xor eax,eax            ; eax = 0
	mov [totwgt],eax       ; totwgt = 0
	mov [totval],eax       ; totval = 0
	mov eax,bitlst         ; address of bitlst[0]
	mov [bitptr],eax       ; bitptr = address of bitlst[0]
	mov eax,wgtlst         ; address of wgtlst[0]
	mov [wgtptr],eax       ; wgtptr = address of wgtlst[0]
	mov eax,vallst         ; address of vallst[0]
	mov [valptr],eax       ; valptr = address of vallst[0]
.lp:    ; loop for calculating total weight and value
	mov esi,[bitptr]       ; esi = address of bitlst[i]
	mov al,[esi]           ; al = bitlst[i]
	or al,al               ; is bitlst[i] zero?
	jz .nxt                ; yes, do not accumulate totals
	;------------------------------------------
	; total weight = totwgt + wgtlst[i]
	;------------------------------------------
	mov esi,[wgtptr]
	mov ebx,[esi]
	mov eax,[totwgt]
	add eax,ebx
	mov [totwgt],eax
	;--------------------------------------------------
	; if total weight > maxwgt, continue loop
	;--------------------------------------------------
	mov ebx,[maxwgt]       ; ebx = maximum weight
	cmp eax,ebx            ; total weight > max weight?
	ja .nxt                ; yes, continue loop
	;--------------------------------------------------
	; total weight <= maximum weight
	; accumulate total value = totval + vallst[i]
	;--------------------------------------------------
	mov esi,[valptr]       ; address of vallst[i]
	mov ebx,[esi]          ; ebx = vallst[i]
	mov eax,[totval]       ; eax = total value so far
	add eax,ebx            ; totval += vallst[i]
	mov [totval],eax       ; save the new total value
.nxt:
	;--------------------------------------------------
	; increase all pointers by one
	; test for end of loop
	; if not end of loop, continue next iteration
	;--------------------------------------------------
	; bitptr = address of bitlst[i+1]
	; each bit is one byte
	;--------------------------------------------------
	mov eax,[bitptr]
	inc eax
	mov [bitptr],eax
	;--------------------------------------------------
	; hdrptr = address of hdrlst[i+1]
	; each header is 32 bytes
	;--------------------------------------------------
	mov eax,[hdrptr]
	add eax,32
	mov [hdrptr],eax
	;--------------------------------------------------
	; wgtptr = address of wgtlst[i+1]
	; each weight is 4 bytes
	;--------------------------------------------------
	mov eax,[wgtptr]
	add eax,4
	mov [wgtptr],eax
	;--------------------------------------------------
	; valptr = address of vallst[i+1]
	; each vale is 4 bytes
	;--------------------------------------------------
	mov eax,[valptr]
	add eax,4
	mov [valptr],eax
	;--------------------------------------------------
	; test for end of loop
	; repeat loop if not at end of bit list
	;--------------------------------------------------
	mov eax,[bitptr]
	mov ebx,[bitend]
	cmp eax,ebx
	jb .lp
	;--------------------------------------------------
	; end of accumulation loop
	; check that total weight <= maximum weight
	; if not too heavy, compare total value
	;--------------------------------------------------
	mov eax,[totwgt]
	mov ebx,[maxwgt]
	cmp eax,ebx
	ja .done
	;--------------------------------------------------
	; check that total value >= maximum value
	; if new maximum value, print new ingredients
	;--------------------------------------------------
	mov eax,[totval]
	mov ebx,[maxval]
	cmp eax,ebx
	jb .done
	;--------------------------------------------------
	; new maximum value, print new ingredients
	;--------------------------------------------------
	mov [maxval],eax       ; save new maximum value
	call putmax            ; print new ingredients
.done:  ; end of evaluation
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; print maximum value
; print weight and value of each chosen ingredient
;---------------------------------------------------
putmax:
	push eax
        ;---------------------------------------------------
	; print maximum value in decimal
        ;---------------------------------------------------
	mov eax,maxhdr      ; print "Maximum value "
	call putstr
	;---------------------------------------------------
	mov eax,[maxval]    ; print maxval in decimal
	mov [prime],eax
	call putprime
	;---------------------------------------------------
	call puteol         ; print end of line
	mov eax,itmhdr      ; print headers for item, wgt, val
	call putstr
	;---------------------------------------------------
	; set pointers to beginning of each array
	;---------------------------------------------------
	mov eax,bitlst
	mov [bitptr],eax
	mov eax,hdrlst
	mov [hdrptr],eax
	mov eax,wgtlst
	mov [wgtptr],eax
	mov eax,vallst
	mov [valptr],eax
.lp:                         ; chosen ingredient loop
	mov esi,[bitptr]     ; esi = address of bitlst[i]
	mov al,[esi]         ; al = bitlst[i]
	or al,al             ; is bitlst[i] zero?
	jz .nxt              ; yes, continue loop
	;---------------------------------------------------
	; print ingredient name
	;---------------------------------------------------
	mov eax,[hdrptr]
	call putstr
	call putspc
	;---------------------------------------------------
	; print weight of ingredient in decimal
	;---------------------------------------------------
	mov esi,[wgtptr]
	mov eax,[esi]
	mov [prime],eax
	call putprime
	call putspc
	;---------------------------------------------------
	; print value of ingredient in decimal
	;---------------------------------------------------
	mov esi,[valptr]
	mov eax,[esi]
	mov [prime],eax
	call putprime
	call puteol       ; print end of line
.nxt:
	;---------------------------------------------------
	; increase all pointers by one unit
	;---------------------------------------------------
	; increase bitlst pointer by one byte
	;---------------------------------------------------
	mov eax,[bitptr]
	inc eax
	mov [bitptr],eax
	;---------------------------------------------------
	; increase hdrlst pointer by 32 bytes
	;---------------------------------------------------
	mov eax,[hdrptr]
	add eax,32
	mov [hdrptr],eax
	;---------------------------------------------------
	; increase wgtlst pointer by 4 bytes
	;---------------------------------------------------
	mov eax,[wgtptr]
	add eax,4
	mov [wgtptr],eax
	;---------------------------------------------------
	; increase value pointer by 4 bytes
	;---------------------------------------------------
	mov eax,[valptr]
	add eax,4
	mov [valptr],eax
	;---------------------------------------------------
	; if not end of loop, continue next iteration
	;---------------------------------------------------
	mov eax,[hdrptr]
	mov ebx,[hdrend]
	cmp eax,ebx
	jb .lp
.max9:
	;---------------------------------------------------
	; all chosen ingredients have been printed
	; print separation line of dashes
	;---------------------------------------------------
	call putdash
	pop eax
	ret
;---------------------------------------------------
; initialize bit array to zero
;---------------------------------------------------
bitinit:
	push eax
	push ecx
	push edi
	xor al,al
	mov edi,bitlst
	mov ecx,32           ; bitlst is 32 bits
.lp:
	mov [edi],al
	inc edi
	loop .lp
	pop edi
	pop ecx
	pop eax
	ret
;---------------------------------------------------
; open knap01.rc
; read line by line, filling 3 arrays
; header array, weight array, value array
; syscalls:
; 3 = read  handle buffer length
; 4 = write handle buffer length
; 5 = open filename access-mode -
; 6 = close handle - -
;---------------------------------------------------
fill:
	push eax
        ;---------------------------------------------------
	; open knap01.rc as input
        ;---------------------------------------------------
	call opn
        ;---------------------------------------------------
	; initialize kount, indx, all pointers
        ;---------------------------------------------------
	xor eax,eax
	mov [kount],eax        ; kount = 0
	mov [indx],eax         ; indx  = 0
	mov eax,hdrlst         ; address of hdrlst[0]
	mov [hdrptr],eax       ; save in pointer
	mov eax,wgtlst         ; address of wgtlst[0]
	mov [wgtptr],eax       ; save in pointer
	mov eax,vallst         ; address of vallst[0]
	mov [valptr],eax       ; save in pointer
.lp:                           ; ingredient loop
        ;---------------------------------------------------
	; tokens are delimited by white space
	; tabs, spaces, end of line
        ;---------------------------------------------------
	call gettkn            ; get first token on line
	mov eax,[eofsw]        ; if end of file
	or eax,eax
	jnz .lp9               ; return
        ;---------------------------------------------------
	; all comments must start at beginning of line
	; or after the last token,
	; otherwise the parsing will be out of sync
        ;---------------------------------------------------
	mov eax,[cmtsw]        ; if comment, next line
	or eax,eax
	jnz .lp
        ;---------------------------------------------------
	; 1st token is ingredient name, called header
	; copy header token to hdrlst[i]
	; point to hdrlst[i+1] for next loop
        ;---------------------------------------------------
	mov eax,token
	mov edi,[hdrptr]      ; edi = address of hdrlst[i]
	call cpyhdr           ; copy header to hdrlst[i]
	mov eax,[hdrptr]
	add eax,32            ; each header is 32 bytes
	mov [hdrptr],eax      ; save pointer to hdrlst[i+1]
	mov [hdrend],eax      ; save end of list pointer
        ;---------------------------------------------------
	; 2nd token is ingredient weight
	; copy weight token to wgtlst[i]
	; point to wgtlst[i+1] for next loop
        ;---------------------------------------------------
	call gettkn 
	mov eax,[eofsw]         ; if end of file, return
	or eax,eax
	jnz .lp9
        ;---------------------------------------------------
	; copy weight token to wgtlst[i]
	; convert number from ASCII to 32-bit binary
        ;---------------------------------------------------
	mov eax,token
	mov edi,[wgtptr]
	call asc2bin
        ;---------------------------------------------------
	; point wgtptr to wgtlst[i+1]
	; save pointer to current end of list
        ;---------------------------------------------------
	mov eax,[wgtptr]
	add eax,4             ; each header is 4 bytes
	mov [wgtptr],eax      ; save pointer to wgtlst[i+1]
	mov [wgtend],eax      ; save end of list pointer
        ;---------------------------------------------------
	; 3rd token is ingredient value
	; copy value token to vallst[i]
	; point to vallst[i+1] for next loop
        ;---------------------------------------------------
	call gettkn 
	mov eax,[eofsw]
	or eax,eax
	jnz .lp9
        ;---------------------------------------------------
	; copy weight token to wgtlst[i]
	; convert number from ASCII to 32-bit binary
        ;---------------------------------------------------
	mov eax,token
	mov edi,[valptr]
	call asc2bin
        ;---------------------------------------------------
	; point valptr to vallst[i+1]
	; save pointer to current end of list
        ;---------------------------------------------------
	mov eax,[valptr]
	add eax,4             ; each header is 4 bytes
	mov [valptr],eax      ; save pointer to vallst[i+1]
	mov [valend],eax      ; save end of list pointer
        ;---------------------------------------------------
	; kount = kount + 1
        ;---------------------------------------------------
	mov eax,[kount]
	inc eax
	mov [kount],eax
        ;---------------------------------------------------
	; save new address to end of bit list pointer
        ;---------------------------------------------------
	mov ebx,eax
	mov eax,bitlst
	add eax,ebx
	mov [bitend],eax
	jmp .lp         ; repeat ingredient loop
.lp9:
        ;---------------------------------------------------
	; end of loop, close input file knap01.rc
        ;---------------------------------------------------
	call cls
	pop eax
	ret
;---------------------------------------------------
; copy string from token to the header list
; edi already points to destination address
;---------------------------------------------------
cpyhdr:
	push eax
	push esi
	push edi
	mov esi,token        ; esi = address of token
.lp:
	mov al,[esi]
	or al,al             ; end of token?
	jz .lp9              ; yes, return
	mov [edi],al         ; no, copy character to destination
	inc esi              ; next source character
	inc edi              ; next destination character
	jmp .lp              ; repeat copy loop
.lp9:
	xor al,al            ; zero byte at end of string
	mov [edi],al
	mov [hdrend],edi     ; new end of hdrlst pointer
	pop edi
	pop esi
	pop eax
	ret
;---------------------------------------------------
; convert an ASCII number to 32-bit integer
; eax points to the ASCII string
; edi points to the destination integer address
;---------------------------------------------------
asc2bin:
	push eax
	push ebx
	push edx
	push esi
	push edi
        ;---------------------------------------------------
	; esi is address of source string
        ;---------------------------------------------------
	mov esi,eax
        ;---------------------------------------------------
	; initialize destination integer to zero
        ;---------------------------------------------------
	xor eax,eax
	mov [prime],eax
.lp:    ; digit loop
        ;---------------------------------------------------
	; i = (i * 10) + (j - 0x30)
	; where i is the destination integer
	; j is the current ASCII digit in the source string
        ;---------------------------------------------------
	; prime *= 10
        ;---------------------------------------------------
	mov eax,[prime]
	xor edx,edx
	mov ebx,10
	mul ebx                  ; prime *= 10
	xor ebx,ebx
	mov bl,[esi]
	or bl,bl                 ; end of source string?
	jz .lp9                  ; yes, return
	sub bl,0x30              ; ASCII to binary
	add eax,ebx
	mov [prime],eax          ; prime += j
	inc esi
	jmp .lp                  ; repeat digit loop
.lp9:
	mov eax,[prime]          ; *list = prime
	mov [edi],eax
	pop edi
	pop esi
	pop edx
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; get token by reading input file
; token is delimited by space, tab, and end of line
; input line is flushed from comment to end of line
;---------------------------------------------------
gettkn:
	push eax
	push ebx
	push ecx
	push edx
	push edi
	xor eax,eax
	mov [cmtsw],eax       ; default no comment
	mov edi,token         ; edi points to token[i]
.lp:                          ; leading white space loop
        ;---------------------------------------------------
	; bypass leading white space
        ;---------------------------------------------------
	call gethndl          ; read one character
	mov eax,[eofsw]       ; end of input file?
	or eax,eax
	jnz .lp9              ; yes, end of token
	mov al,[buf]     ; al = input character
	cmp al,0x0a      ; end of line
	jz .lp9          ; yes, end of token
	cmp al,0x20      ; space
	jz .lp           ; yes, next leading white space
	cmp al,0x09      ; tab
	jz .lp           ; yes, next leading white space
	cmp al,0x0d      ; return char
	jz .lp           ; yes, next leading white space
	cmp al,0x23      ; # (comment)
	jnz .lp2         ; no, beginning of token
	jmp .lp8         ; else, flush line
.lp2:                    ; token character loop
        ;---------------------------------------------------
	; test for trailing white space
        ;---------------------------------------------------
	mov al,[buf]
	cmp al,0x0a      ; end of line
	jz .lp9          ; yes, end of token
	cmp al,0x20      ; space
	jz .lp9          ; yes, end of token
	cmp al,0x09      ; tab
	jz .lp9          ; yes, end of token
	cmp al,0x23      ; # (comment)
	jnz .lp3         ; no, save character in token[i]
	jmp .lp8         ; else, flush line
.lp3:                    ; valid character
	mov [edi],al     ; save character in token[i]
	inc edi          ; point to token[i+1]
	call gethndl     ; read one character from input
	mov eax,[eofsw]  ; end of input file?
	or eax,eax
	jnz .lp9         ; yes, return
	jmp .lp2         ; no, read next input character
.lp8:                    ; comment
	call flush       ; flush input line
.lp9:                    ; end of token
        ;---------------------------------------------------
	; if header, weight, or value is empty,
	; the arrays will be out of sync
	; the header has underline character for a space
	; between words.  Example waterproof_trousers
        ;---------------------------------------------------
	xor al,al        ; al = 0
	mov [edi],al     ; zero at end of string
	pop edi
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; flush input line until end of line
;---------------------------------------------------
flush:
	push eax
	mov eax,1
	mov [cmtsw],eax       ; comment switch is true
.lp:
	call gethndl
	mov eax,[eofsw]       ; end of file?
	or eax,eax
	jnz .lp9              ; yes, return
	mov al,[buf]
	cmp al,0x0a           ; end of line?
	jnz .lp               ; no, read next char
.lp9:                         ; end of line or eof
	pop eax
	ret
;---------------------------------------------------
; get character from file handle
;---------------------------------------------------
gethndl:
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
	push ebp
	mov eax,3          ; read
	mov ebx,[hndl]     ; file handle
	mov ecx,buf        ; buf
	mov edx,1          ; length
	int 0x80           ; syscall
	mov [len],eax      ; save length 0=eof
	or eax,eax         ; end of file?
	jnz .done          ; no, return
	inc eax            ; yes, eofsw = true
	mov [eofsw],eax
.done:
	pop ebp
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; open file
;---------------------------------------------------
opn:
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
	push ebp
	mov eax,5          ; open
	mov ebx,fname      ; file name address
	mov ecx,0          ; read-only = 0
	mov edx,0          ; access mode = NULL
	int 0x80           ; syscall
	mov [hndl],eax     ; save handle
	pop ebp
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; close file
;---------------------------------------------------
cls:
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
	push ebp
	mov eax,6          ; open
	mov ebx,[hndl]     ; file handle
	mov ecx,0          ; NULL
	mov edx,0          ; NULL
	int 0x80           ; syscall
	pop ebp
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; initialize header, weight, value arrays
;---------------------------------------------------
init:
	push eax
	push ecx
	push edi
	xor eax,eax
	mov edi,hdrlst        ; edi points to hdrlst
	mov ecx,256           ; 32x32 header list
.lp1:                         ; header list loop
	mov [edi],al          ; hdrlst[i] = 0
	inc edi               ; point to hdrlst[i+1]
	loop .lp1             ; loop 256 times
	;--------------------------------------------
	mov edi,wgtlst        ; edi points to wgtlst
	mov ecx,32            ; 32x4 weight list
.lp2:                         ; weight list loop
	mov [edi],eax         ; hdrlst[i] = 0
	add edi,4             ; point to wgtlst[i+1]
	loop .lp2             ; loop 32 times
	;--------------------------------------------
	mov edi,vallst        ; edi points to vallst
	mov ecx,32            ; 32x4 value list
.lp3:                         ; value list loop
	mov [edi],eax         ; wgtlst[i] = 0
	add edi,4             ; point to vallst[i+1]
	loop .lp3             ; loop 32 times
	pop edi
	pop ecx
	pop eax
	ret
;---------------------------------------------------
; debugging routine
; display the header list
;---------------------------------------------------
shwhdr:
	push eax
	push ebx
	push esi
	call puteol
	mov esi,hdrlst
.lp:
	mov eax,esi
	call putstr
	call puteol
	add esi,32
	mov eax,esi
	mov ebx,[hdrend]
	cmp eax,ebx
	jb .lp
.lp9:
	pop esi
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; debugging routine
; display the weight list
;---------------------------------------------------
shwwgt:
	push eax
	push ebx
	push esi
	call puteol
	mov esi,wgtlst
.lp:
	mov eax,[esi]
	mov [prime],eax
	call putprime
	call puteol
	add esi,4
	mov eax,esi
	mov ebx,[wgtend]
	cmp eax,ebx
	jb .lp
.lp9:
	pop esi
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; debugging routine
; display the bit list
; print bit list ruler
; print list of bits under the ruler
; print value of n at beginning of list
; this routine should be called from maxmize
; where the value of enn is set
;---------------------------------------------------
shwbit:
	push eax
	push ebx
	push esi
	call puteol
	mov eax,rule
	call putstr
	;----------------------------------------------------
	; print value of n in decimal
	; print leading space if 1 digit number
	;----------------------------------------------------
	mov eax,[enn]
	mov [prime],eax
	cmp eax,10
	jnb .spc
	call putspc
.spc:
	call putprime
	mov esi,bitlst
.lp:                          ; bit loop
	mov al,[esi]
	add al,0x30           ; print bit in ASCII
	call putchar
	call putspc
	inc esi
	mov eax,esi
	mov ebx,[bitend]      ; end of list?
	cmp eax,ebx
	jb .lp                ; no, repeat loop
.lp9:                         ; end of bit list
	call puteol           ; print end of line
	pop esi
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; debugging routine
; display the value list
;---------------------------------------------------
shwval:
	push eax
	push ebx
	push ecx
	push esi
	call puteol
	mov esi,vallst
	mov ecx,32
.lp:
	mov eax,[esi]
	mov [prime],eax
	call putprime
	call puteol
	add esi,4
	mov eax,esi
	mov ebx,[valend]
	cmp eax,ebx
	jb .lp
.lp9:
	pop esi
	pop ecx
	pop ebx
	pop eax
	ret
;---------------------------------------------------
; debugging routine
; display header, weight, value arrays together
;---------------------------------------------------
shwlst:
	push eax
	push ebx
	push esi
	mov eax,hdrlst
	mov [hdrptr],eax
	mov eax,wgtlst
	mov [wgtptr],eax
	mov eax,vallst
	mov [valptr],eax
	;-----------------------------------
	; loop to print a line from the list
	;-----------------------------------
.lp:
	mov eax,[hdrptr]
	call putstr
	call putspc
	;-----------------
	mov esi,[wgtptr]
	mov eax,[esi]
	mov [prime],eax
	call putprime
	call putspc
	;-----------------
	mov esi,[valptr]
	mov eax,[esi]
	mov [prime],eax
	call putprime
	call puteol
	;-----------------
	mov eax,[hdrptr]
	add eax,32
	mov [hdrptr],eax
	mov eax,[wgtptr]
	add eax,4
	mov [wgtptr],eax
	mov eax,[valptr]
	add eax,4
	mov [valptr],eax
	mov eax,[hdrptr]
	mov ebx,[hdrend]
	cmp eax,ebx
	jb .lp
	pop esi
	pop ecx
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
; Print line of dashes
;---------------------------------------------------
putdash:
	push eax
	push ecx
	mov ecx,40
	mov al,0x2d          ; dash
.lp:
	call putchar
	loop .lp
	call puteol
	pop ecx
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
; print X followed by space
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
; print Y followed by space
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
; print end of line
;---------------------------------------------------
puteol:
	push eax
	mov al,10
	call putchar
	pop eax
	ret
;---------------------------------------------------
; print string to stdout
;---------------------------------------------------
putstr:
	push eax
	push esi
	mov esi,eax        ; eax points to string
.lp:
	mov al,[esi]       ; current char in string
	or al,al           ; end of string?
	jz .done           ; yes, finish
	call putchar       ; no, print char to stdout
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
maxwgt   dd 400                  ; maximum weight allowed
; binary to hex translate table
hxtbl:   db '0123456789ABCDEF'
fname:   db 'knap01.rc',0
maxhdr:  db 'Maximum value ',0
itmhdr:  db 'Item        Weight      Value',10,0
;--------------------------------------
; the first 3 spaces are to print n
;--------------------------------------
rule:    db ' n . . . . v . . . . 1 '
         db '. . . . v . . . . 2 '
         db '. . . . v . . . . 3 '
         db '. . . . v',10,0
	; reserved space for constant data
	; read only, not executable
	section .bss
	align 16
buf      resb 8         ; input buffer for knap01.rc
hndl     resd 1         ; file handle
len      resd 1         ; buffer length 0=eof
eofsw    resd 1         ; end of file switch
cmtsw    resd 1         ; comment switch
;-----------------------------------------------------
; boolean choice list: 0=no 1=yes
;-----------------------------------------------------
bitlst   resb 32        ; list of boolean choices
bitend   resb 4         ; end of bit list
hdrlst   resb 1024      ; list of headers
hdrend   resb 4         ; end of header list
wgtlst   resd 32        ; list of weights
wgtend   resb 4         ; end of weight list
vallst   resd 32        ; list of values 
valend   resb 4         ; end of value list
indx     resd 1         ; index to arrays
bitptr   resd 1         ; pointer to choice array
hdrptr   resd 1         ; pointer to header array
wgtptr   resd 1         ; pointer to weight array
valptr   resd 1         ; pointer to value  array
token    resb 1024      ; token
totwgt   resd 1         ; total weight in decagrams (dag)
totval   resd 1         ; total value
maxval   resd 1         ; maximum value obtained
prime    resd 1         ; maximum value obtained
enn      resd 2         ; parameter n for maxmize
kount    resd 2         ; count of items in each list
chbuf    resb 8         ; decimal digit stack
dgtstk   resd 32        ; decimal digit stack
stack    resd 2048      ; reserve program stack
stkend   resd 1         ; top of program stack
;---------------------------------------------------
; end of program
;---------------------------------------------------
