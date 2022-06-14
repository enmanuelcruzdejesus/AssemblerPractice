		global	_start		; tell the linker about the entry point

		SECTION	.text

_start:		mov	eax, 4		; write()
		mov	ebx, 1		; stdout
		mov	ecx, str1	; string pointer
		mov	edx, str1_len	; string length
		int	0x80		; syscall

		mov	eax, 3		; read()
		mov	ebx, 0		; stdin
		mov	ecx, filename_str ; buffer pointer
		mov	edx, filename_str_len ; buffer length
		int	0x80
		mov	edi, filename_str
		dec	eax
		mov byte [edi + eax],0	; overwrite '\n' by null terminator

		mov	eax, 4		; write()
		mov	ebx, 1		; stdout
		mov	ecx, str2	; string pointer
		mov	edx, str2_len	; string length
		int	0x80		; syscall

		mov	eax, 3		; read()
		mov	ebx, 0		; stdin
		mov	ecx, word_str	; buffer pointer
		mov	edx, word_str_len ; buffer length
		int	0x80
		dec	eax
		mov	[word_str_real_len], eax ; store real length (without '\n')

		mov	eax, 5		; open()
		mov	ebx, filename_str ; null terminated
		mov	ecx, 0		; read only
		int	0x80		; syscall
		cmp	eax, 0
		jl	file_not_found	; less then zero -> jump
		mov	[filename_desc], eax ; save file descriptor

		mov	eax, 3		; read()
		mov	ebx, [filename_desc] ; file descriptor
		mov	ecx, file_buffer ; buffer pointer
		mov	edx, file_buffer_len ; buffer length
		int	0x80
		mov	[file_buffer_real_len], eax ; store real length

		mov	eax, 6		; close()
		mov	ebx, filename_desc ; file descriptor
		int	0x80

		; -----------------------

		mov	edi, file_buffer ; pointing to first byte of the buffer

restart:	mov	ecx, [file_buffer_real_len]
		push	edi		; save
		call	find_word
		cmp	al, 0
		jne	done		; no other words present

		; check whether we have enough chars left in the buffer
		mov	eax, edi	; eax = current EDI
		pop	ebx		; restore EDI into EBX
		sub	eax, ebx	; eax = number of process characters
		mov	ebx, [file_buffer_real_len]
		sub	ebx, eax	; ebx = number of remaining chars in EDI
		mov	[file_buffer_real_len], ebx
		mov	ecx, [word_str_real_len]
		cmp	ebx, ecx
		jl	done		; not enough chars to compare

		; ECX already set
		mov	esi, word_str	; first character of the word
		push	edi		; save
		repe	cmpsb		; compare while equal
		jne	.no_match

		; is the next char still a word?
		cmp byte [edi], 33
		jl	.match
		cmp byte [edi], 126
		jle	.no_match
.match:		inc word [word_count]	; matches++

.no_match:	; update length
		mov	eax, edi	; eax = current EDI
		pop	ebx		; restore EDI into EBX
		sub	eax, ebx	; eax = number of process characters
		mov	ebx, [file_buffer_real_len]
		sub	ebx, eax	; ebx = number of remaining chars in EDI
		jle	done		; if zero or less, finish
		mov	[file_buffer_real_len], ebx

		mov     ecx, ebx
		push	edi		; save
		call	find_word_end
		cmp     al, 0
		jne     done		; last word

		; update length again
		mov	eax, edi	; eax = current EDI
		pop	ebx		; restore EDI into EBX
		sub	eax, ebx	; eax = number of process characters
		mov	ebx, [file_buffer_real_len]
		sub	ebx, eax	; ebx = number of remaining chars in EDI
		jle	done		; if zero or less, finish
		mov	[file_buffer_real_len], ebx
		
		jmp	restart

		; ----------------------

done:		mov	eax, 4		; write()
		mov	ebx, 1		; stdout
		mov	ecx, str3	; string pointer
		mov	edx, str3_len	; string length
		int	0x80		; syscall

		mov	ax, [word_count]
		mov	edi, matches_str
		call	num2str

		mov	eax, 4		; write()
		mov	ebx, 1		; stdout
		mov	ecx, matches_str ; string pointer
		mov	edx, matches_str_len ; string length
		int	0x80		; syscall

		; we're done!
		mov	eax, 1		; exit()
		mov	ebx, 0		; 0 = success
		int	0x80

; --------------------------------------

find_word:	; EDI = str; ECX = str_len
		; returns AL = 0 if found, -1 otherwise; update EDI
		cmp byte [edi], 33	; first printable char
		jl	.skip
		cmp byte [edi], 126	; last printable char
		jg	.skip
.found		xor	al, al
		ret

.skip		inc	edi
		loop	find_word
.not_found	mov	al, -1
		ret

find_word_end:	; EDI = str; ECX = str_len
		; returns AL = 0 if found, -1 otherwise; update EDI
		cmp byte [edi], 33	; first printable char
		jl	.done
		cmp byte [edi], 126	; last printable char
		jg	.done
		inc	edi
		loop	find_word_end
		mov	al, -1
		ret

.done		xor	al, al
		ret

file_not_found:	mov	eax, 4		; write()
		mov	ebx, 1		; stdout
		mov	ecx, str4	; string pointer
		mov	edx, str4_len	; string length
		int	0x80		; syscall

		mov	eax, 1		; exit()
		mov	ebx, 1		; 1 = not success
		int	0x80
		ret
		
num2str:	; input in AX, output in [EDI]
		mov	bx, 10
		xor	ecx, ecx

.cycle1:	mov 	dx, 0
		div 	bx		; DX:AX / 10 = AX:QUOTIENT DX:REMAINDER
		push	dx		; save for later
		inc	ecx
		cmp	ax, 0
		jne	.cycle1

.cycle2:	pop	dx
		add	dl, 0x30	; binary -> ASCII
		mov	[edi], dl
		inc	edi
		loop	.cycle2
		ret

		SECTION	.data

str1		db	'Enter a filename (255  chars max): '
str1_len	equ	$-str1
str2		db	'Enter a word (255 chars max): '
str2_len	equ	$-str2
str3		db	'Number of occurences: '
str3_len	equ	$-str3
str4		db	'File not found.',10
str4_len	equ	$-str4

		SECTION	.bss

filename_str	resb	255+1		; 255 characters for path
filename_str_len equ	$-filename_str-1 ; -1 for '\0'
filename_desc	resd	1		; file descriptor

word_str	resb	255+1		; 255 characters for word
word_str_len	equ	$-word_str-1	; -1 for '\0'
word_str_real_len resd	1		; real length

word_count	resw	1		; number of occurences

file_buffer	resb	100000		; 100 000 bytes max
file_buffer_len	equ	$-file_buffer
file_buffer_real_len resd 1		; real length

matches_str	resb	16		; word matches string
matches_str_len	equ	$-matches_str
