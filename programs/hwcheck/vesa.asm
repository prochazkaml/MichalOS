vesa:				; CPU vendor
	call background
	
	mov ax, 4F00h
	mov di, buffer
	int 10h
	
	mov si, .msg0
	call os_print_string
	
	mov ax, [buffer + 04h]
	call os_print_4hex
	
	call os_print_newline

	mov si, .msg1
	call os_print_string
	
	mov eax, [buffer + 0Ah]
	call os_print_8hex
	
	call os_print_newline
	
	mov si, .msg2
	call os_print_string
	
	mov eax, 0
	mov ax, [buffer + 12h]
	shl eax, 6
	call os_32int_to_string
	mov si, ax
	call os_print_string
	mov si, unit_kb
	call os_print_string
	
	call os_wait_for_key
	
	jmp main_loop
	
	.msg0		db 'VESA version:  ', 0
	.msg1		db 'Abilities:     ', 0
	.msg2		db 'VESA memory:   ', 0
