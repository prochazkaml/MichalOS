; ==================================================================
; MichalOS String manipulation functions
; ==================================================================

; ------------------------------------------------------------------
; os_string_encrypt -- Encrypts a string using a totally military-grade encryption algorithm
; IN: SI = Input string/Output string
; OUT: None, registers preserved

os_string_encrypt:
	pusha
	mov di, si

	mov ax, si
	call os_string_length
	shl al, 2
	xor al, 123
	
	mov cl, 123
	add cl, al
	xor cl, 219
	
.loop:
	lodsb
	test al, al
	jz .exit
	
	add al, cl
	xor al, 10101010b
	stosb
	
	add cl, 77
	jmp .loop
	
.exit:
	popa
	ret

; ------------------------------------------------------------------
; os_string_add -- Add a string on top of another string
; IN: AX/BX = Main string/Added string
; OUT: None, registers preserved

os_string_add:
	pusha
	push ax
	call os_string_length		; Get the length of the main string
	pop di
	add di, ax					; Add it to the pointer
	mov si, bx
 	call os_string_copy			; Copy the string
 	popa
 	ret
	
; ------------------------------------------------------------------
; os_string_length -- Return length of a string
; IN: AX = string location
; OUT AX = length (other regs preserved)

os_string_length:
	pusha

	mov bx, ax			; Move location of string to BX

	xor cx, cx			; Counter

.more:
	cmp byte [bx], 0		; Zero (end of string) yet?
	je .done
	inc bx				; If not, keep adding
	inc cx
	jmp .more


.done:
	mov word [.tmp_counter], cx	; Store count before restoring other registers
	popa

	mov ax, [.tmp_counter]		; Put count back into AX before returning
	ret


	.tmp_counter	dw 0


; ------------------------------------------------------------------
; os_string_reverse -- Reverse the characters in a string
; IN: SI = string location
; OUT: None, registers preserved

os_string_reverse:
	pusha

	cmp byte [si], 0		; Don't attempt to reverse empty string
	je .end

	mov ax, si
	call os_string_length

	mov di, si
	add di, ax
	dec di				; DI now points to last char in string

.loop:
	mov byte al, [si]		; Swap bytes
	mov byte bl, [di]

	mov byte [si], bl
	mov byte [di], al

	inc si				; Move towards string centre
	dec di

	cmp di, si			; Both reached the centre?
	ja .loop

.end:
	popa
	ret


; ------------------------------------------------------------------
; os_find_char_in_string -- Find location of character in a string
; IN: SI = string location, AL = character to find
; OUT: AX = location in string, or 0 if char not present

os_find_char_in_string:
	pusha

	mov cx, 1			; Counter -- start at first char (we count
					; from 1 in chars here, so that we can
					; return 0 if the source char isn't found)

.more:
	cmp byte [si], al
	je .done
	cmp byte [si], 0
	je .notfound
	inc si
	inc cx
	jmp .more

.done:
	mov [.tmp], cx
	popa
	mov ax, [.tmp]
	ret

.notfound:
	popa
	xor ax, ax
	ret


	.tmp	dw 0


; ------------------------------------------------------------------
; os_string_uppercase -- Convert zero-terminated string to upper case
; IN: AX = string location
; OUT: None, registers preserved

os_string_uppercase:
	pusha

	mov si, ax			; Use SI to access string

.more:
	cmp byte [si], 0		; Zero-termination of string?
	je .done			; If so, quit

	cmp byte [si], 'a'		; In the lower case A to Z range?
	jb .noatoz
	cmp byte [si], 'z'
	ja .noatoz

	sub byte [si], 20h		; If so, convert input char to upper case

	inc si
	jmp .more

.noatoz:
	inc si
	jmp .more

.done:
	popa
	ret


; ------------------------------------------------------------------
; os_string_lowercase -- Convert zero-terminated string to lower case
; IN: AX = string location
; OUT: None, registers preserved

os_string_lowercase:
	pusha

	mov si, ax			; Use SI to access string

.more:
	cmp byte [si], 0		; Zero-termination of string?
	je .done			; If so, quit

	cmp byte [si], 'A'		; In the upper case A to Z range?
	jb .noatoz
	cmp byte [si], 'Z'
	ja .noatoz

	add byte [si], 20h		; If so, convert input char to lower case

	inc si
	jmp .more

.noatoz:
	inc si
	jmp .more

.done:
	popa
	ret


; ------------------------------------------------------------------
; os_string_copy -- Copy one string into another
; IN: SI = source, DI = destination (programmer ensure sufficient room)
; OUT: None, registers preserved

os_string_copy:
	pusha

.more:
	lodsb
	stosb
	cmp byte al, 0			; If source string is empty, quit out
	jne .more
	popa
	ret


; ------------------------------------------------------------------
; os_string_join -- Join two strings into a third string
; IN: AX = string one, BX = string two, CX = destination string
; OUT: None, registers preserved

os_string_join:
	pusha

	mov si, ax
	mov di, cx
	call os_string_copy

	call os_string_length		; Get length of first string

	add cx, ax			; Position at end of first string

	mov si, bx			; Add second string onto it
	mov di, cx
	call os_string_copy

	popa
	ret


; ------------------------------------------------------------------
; os_string_chomp -- Strip leading and trailing spaces from a string
; IN: AX = string location
; OUT: None, registers preserved

os_string_chomp:
	pusha

	mov dx, ax			; Save string location

	mov di, ax			; Put location into DI
	xor cx, cx			; Space counter

.keepcounting:				; Get number of leading spaces into BX
	cmp byte [di], ' '
	jne .counted
	inc cx
	inc di
	jmp .keepcounting

.counted:
	test cx, cx			; No leading spaces?
	jz .finished_copy

	mov si, di			; Address of first non-space character
	mov di, dx			; DI = original string start

.keep_copying:
	mov al, [si]			; Copy SI into DI
	mov [di], al			; Including terminator
	test al, al
	jz .finished_copy
	inc si
	inc di
	jmp .keep_copying

.finished_copy:
	mov ax, dx			; AX = original string start

	call os_string_length
	test ax, ax			; If empty or all blank, done, return 'null'
	jz .done

	mov si, dx
	add si, ax			; Move to end of string

.more:
	dec si
	cmp byte [si], ' '
	jne .done
	mov byte [si], 0		; Fill end spaces with 0s
	jmp .more			; (First 0 will be the string terminator)

.done:
	popa
	ret


; ------------------------------------------------------------------
; os_string_compare -- See if two strings match
; IN: SI = string one, DI = string two
; OUT: carry set if same, clear if different

os_string_compare:
	pusha

.more:
	mov al, [si]			; Retrieve string contents
	mov bl, [di]

	cmp al, bl			; Compare characters at current location
	jne .not_same

	test al, al			; End of first string? Must also be end of second
	jz .terminated

	inc si
	inc di
	jmp .more


.not_same:				; If unequal lengths with same beginning, the byte
	popa				; comparison fails at shortest string terminator
	clc				; Clear carry flag
	ret


.terminated:				; Both strings terminated at the same position
	popa
	stc				; Set carry flag
	ret


; ------------------------------------------------------------------
; os_string_parse -- Take string (eg "run foo bar baz") and return
; pointers to zero-terminated strings (eg AX = "run", BX = "foo" etc.)
; IN: SI = string
; OUT: AX, BX, CX, DX = individual strings

os_string_parse:
	push si

	mov ax, si			; AX = start of first string

	xor bx, bx			; By default, other strings start empty
	xor cx, cx
	xor dx, dx

	push ax				; Save to retrieve at end

.loop1:
	lodsb				; Get a byte
	test al, al			; End of string?
	jz .finish
	cmp al, ' '			; A space?
	jne .loop1
	dec si
	mov byte [si], 0		; If so, zero-terminate this bit of the string

	inc si				; Store start of next string in BX
	mov bx, si

.loop2:					; Repeat the above for CX and DX...
	lodsb
	test al, al
	jz .finish
	cmp al, ' '
	jne .loop2
	dec si
	mov byte [si], 0

	inc si
	mov cx, si

.loop3:
	lodsb
	test al, al
	jz .finish
	cmp al, ' '
	jne .loop3
	dec si
	mov byte [si], 0

	inc si
	mov dx, si

.finish:
	pop ax

	pop si
	ret


; ------------------------------------------------------------------
; os_string_to_int -- Convert decimal string to integer value
; IN: SI = string location (max 5 chars, up to '65535')
; OUT: AX = number

os_string_to_int:
	call os_string_to_32int		; This function only exists for compatibility reasons
	ret

; ------------------------------------------------------------------
; os_string_to_hex -- Convert hexadecimal string to integer value
; IN: SI = string location (max 8 chars, up to 'FFFFFFFF')
; OUT: EAX = number

os_string_to_hex:
	pushad
	
	mov ax, si			; First, uppercase the string
	call os_string_uppercase

	xor eax, eax				; Temporary 32-bit integer
	
.loop:
	push eax
	lodsb					; Load a byte from SI
	mov cl, al
	pop eax
	test cl, cl				; Have we reached the end?
	jz .exit			; If we have, exit
	
	cmp cl, '9'
	jle .no_change
	
	sub cl, 7
	
.no_change:
	sub cl, '0'				; Convert the value to decimal
	and ecx, 255			; Keep the low 8 bits only
	mov ebx, 16 
	mul ebx					; Multiply EAX by 16
	add eax, ecx			; Add the value to the integer
	jmp .loop				; Loop again
	
.exit:
	mov [.tmp_dword], eax
	popad
	mov eax, [.tmp_dword]
	ret
	
	.tmp_dword	dd 0

; ------------------------------------------------------------------
; os_int_to_string -- Convert unsigned integer to string
; IN: AX = unsigned int
; OUT: AX = string location

os_int_to_string:
	pusha

	xor cx, cx
	mov bx, 10			; Set BX 10, for division and mod
	mov di, .t			; Get our pointer ready

.push:
	xor dx, dx
	div bx				; Remainder in DX, quotient in AX
	inc cx				; Increase pop loop counter
	push dx				; Push remainder, so as to reverse order when popping
	test ax, ax			; Is quotient zero?
	jnz .push			; If not, loop again
.pop:
	pop dx				; Pop off values in reverse order, and add 48 to make them digits
	add dl, '0'			; And save them in the string, increasing the pointer each time
	mov [cs:di], dl
	inc di
	dec cx
	jnz .pop

	mov byte [cs:di], 0		; Zero-terminate string

	popa
	mov ax, .t			; Return location of string
	ret


	.t times 7 db 0


; ------------------------------------------------------------------
; os_sint_to_string -- Convert signed integer to string
; IN: AX = signed int
; OUT: AX = string location

os_sint_to_string:
	pusha

	xor cx, cx
	mov bx, 10			; Set BX 10, for division and mod
	mov di, .t			; Get our pointer ready

	test ax, ax			; Find out if X > 0 or not, force a sign
	js .neg				; If negative...
	jmp .push			; ...or if positive
.neg:
	neg ax				; Make AX positive
	mov byte [.t], '-'		; Add a minus sign to our string
	inc di				; Update the index
.push:
	xor dx, dx
	div bx				; Remainder in DX, quotient in AX
	inc cx				; Increase pop loop counter
	push dx				; Push remainder, so as to reverse order when popping
	test ax, ax			; Is quotient zero?
	jnz .push			; If not, loop again
.pop:
	pop dx				; Pop off values in reverse order, and add 48 to make them digits
	add dl, '0'			; And save them in the string, increasing the pointer each time
	mov [di], dl
	inc di
	dec cx
	jnz .pop

	mov byte [di], 0		; Zero-terminate string

	popa
	mov ax, .t			; Return location of string
	ret


	.t times 7 db 0

; ------------------------------------------------------------------
; os_get_time_string -- Get current time in a string (eg '10:25')
; IN: BX = string location
; OUT: None, registers preserved

os_get_time_string:
	pusha
	
	mov di, bx			; Location to place the string

	mov ah, 02h			; Get the current time
	call os_int_1Ah
	
	jc .exit

	push cx	

	mov al, ch
	call os_bcd_to_int
	cmp ax, 10
	jge .hour_10
	
	push ax
	mov al, '0'
	stosb
	pop ax
	
.hour_10:
	call os_int_to_string
	mov si, ax
	
.hour_loop:	
	lodsb
	test al, al
	jz .hour_loop_end
	stosb
	jmp .hour_loop
	
.hour_loop_end:
	mov al, ':'			; Insert the time separator (or whatever it's called)
	stosb
		
	pop cx
	mov al, cl
	call os_bcd_to_int
	cmp ax, 10
	jge .minute_10
	
	push ax
	mov al, '0'
	stosb
	pop ax
	
.minute_10:
	call os_int_to_string
	mov si, ax
		
.minute_loop:	
	lodsb
	stosb
	
	test al, al
	jnz .minute_loop

.exit:
	popa
	ret

; ------------------------------------------------------------------
; os_get_date_string -- Get current date in a string (eg '12/31/2007')
; IN: BX = string location
; OUT: None, registers preserved

os_get_date_string:
	pusha

	mov di, bx
	
	clc				; For buggy BIOSes
	mov ah, 4			; Get date data from BIOS in BCD format
	call os_int_1Ah
	jnc .fmt1_day

	clc
	mov ah, 4			; BIOS was updating (~1 in 500 chance), so try again
	call os_int_1Ah

.fmt1_day:
	mov ah, dl			; Day
	call .add_2digits

	mov al, '/'
	stosb				; Day-month separator

.fmt1_month:
	mov ah,	dh			; Month
	call .add_2digits

	mov al, '/'
	stosb

.fmt1_century:
	mov ah,	ch			; Century
	call .add_2digits

.fmt1_year:
	mov ah, cl			; Year
	call .add_2digits

	clr al				; Terminate date string
	stosb

	popa
	ret

.add_2digits:
	mov al, ah			; Convert AH to 2 ASCII digits
	shr al, 4
	call .add_digit
	mov al, ah
	and al, 0Fh
	call .add_digit
	ret

.add_digit:
	add al, '0'			; Convert AL to ASCII
	stosb				; Put into string buffer
	ret
	
	
; ------------------------------------------------------------------
; os_string_tokenize -- Reads tokens separated by specified char from
; a string. Returns pointer to next token, or 0 if none left
; IN: AL = separator char, SI = beginning
; OUT: DI = next token or 0 if none

os_string_tokenize:
	push si

.next_char:
	cmp byte [si], al
	je .return_token
	cmp byte [si], 0
	jz .no_more
	inc si
	jmp .next_char

.return_token:
	mov byte [si], 0
	inc si
	mov di, si
	pop si
	ret

.no_more:
	xor di, di
	pop si
	ret

; ------------------------------------------------------------------
; os_string_callback_tokenizer -- Prints a token from string, requests are done by callback
; IN: AX = comma-separated string
; OUT: AL = AH = max length of any token, CX = number of entries in the list,
;      SI = callback location (if C clear, accepts CX as entry ID, prints out result)

os_string_callback_tokenizer:
	push bx
	mov [.strbaseptr], ax
	mov [.strcurptr], ax
	mov word [.curentryid], 0

	mov si, ax
	clr cx

	cmp byte [si], 0	; Check if the list contains any entries
	je .no_entries

	inc cx				; Automatically assume there is at least 1 entry in the list
	clr ah				; For storing the max length
	clr bl				; For storing the current length

.entry_loop:
	lodsb

	inc bl				; Increment the current width
	cmp bl, ah			; Save it if it is the largest so far
	jle .no_expand

	mov ah, bl

.no_expand:
	test al, al			; End of string?
	jz .no_entries

	cmp al, ','			; End of entry?
	jne .entry_loop

	clr bl				; Reset the width counter
	inc cx				; Increment the entry counter
	jmp .entry_loop

.no_entries:
	pop bx
	dec ah				; Terminator character was counted as well, so get rid of it
	mov al, ah
	mov si, .callback
	ret

.callback:
	jc .cb_exit

	dec cx
	
	mov si, [.strcurptr]

	; Check if we're able to simply advance forward or if we have to rewind to the start
	
	cmp cx, [.curentryid]
	jge .advance

	mov word [.curentryid], 0
	mov si, [.strbaseptr]

.advance:
	sub cx, [.curentryid]	; Subtract the IDs that we've already processed
	
	test cx, cx				; Do we already have the thing we want?
	jz .print_loop

	; If not, then find it

.search_loop:
	lodsb

	test al, al				; This should not happen
	jz .cb_exit

	cmp al, ','
	jne .search_loop

	inc word [.curentryid]
	loop .search_loop

.print_loop:
	lodsb

	test al, al
	jz .cb_save_exit

	cmp al, ','
	je .cb_save_exit

	call os_putchar
	jmp .print_loop

.cb_save_exit:
	inc word [.curentryid]
	mov [.strcurptr], si	

.cb_exit:
	ret

.strbaseptr		dw 0
.strcurptr		dw 0
.curentryid		dw 0

; ------------------------------------------------------------------
; os_32int_to_string -- Converts an unsigned 32-bit integer into a string.
; IN: EAX = unsigned int
; OUT: AX = string location

os_32int_to_string:
	pushad

	xor cx, cx
	mov ebx, 10			; Set BX 10, for division and mod
	mov di, .t			; Get our pointer ready

.push:
	xor edx, edx
	div ebx				; Remainder in DX, quotient in AX
	inc cx				; Increase pop loop counter
	push edx			; Push remainder, so as to reverse order when popping
	test eax, eax		; Is quotient zero?
	jnz .push			; If not, loop again

.pop:
	pop edx				; Pop off values in reverse order, and add 48 to make them digits
	add dl, '0'			; And save them in the string, increasing the pointer each time
	mov [di], dl
	inc di
	dec cx
	jnz .pop

	mov byte [di], 0		; Zero-terminate string

	popad
	mov ax, .t			; Return location of string
	ret


	.t times 11 db 0

; ------------------------------------------------------------------
; os_string_to_32int -- Converts a string into a 32-bit integer.
; IN: SI = string location
; OUT: EAX = unsigned integer

os_string_to_32int:
	pushad
	xor eax, eax				; Temporary 32-bit integer
	
.loop:
	push eax
	lodsb					; Load a byte from SI
	mov cl, al
	pop eax
	test cl, cl				; Have we reached the end?
	jz .exit			; If we have, exit
	sub cl, '0'				; Convert the value to decimal
	and ecx, 255			; Keep the low 8 bits only
	mul dword [.divisor]	; Multiply EAX by 10
	add eax, ecx			; Add the value to the integer
	jmp .loop				; Loop again
	
.exit:
	mov [.tmp_dword], eax
	popad
	mov eax, [.tmp_dword]
	ret
	
	.tmp_dword	dd 0
	.divisor	dd 10
	
; ==================================================================
