; ==================================================================
; MichalOS Fatal error kill screen
; ==================================================================
	
	%include "programs/michalos.inc"

	mov [.ax], ax			; Store string location for now, ...
	call os_clear_screen
	
.main_screen:
	mov ax, cs
	mov ds, ax
	mov es, ax

	call os_init_text_mode

	mov ax, .title_msg
	mov bx, .footer_msg
	mov cx, 01001111b
	call os_draw_background
	
	mov dx, 2 * 256
	call os_move_cursor
	mov si, bomblogo
	call os_draw_icon
	
	mov dx, 2 * 256 + 35
	call os_move_cursor
	
	mov si, .msg0
	call os_print_string
	
	mov dx, 3 * 256 + 35
	call os_move_cursor
	
	mov ax, 0A2Ah					; Write a 43-character long asterisk-type line
	clr bh
	mov cx, 42
	int 10h
	
	mov dx, 5 * 256 + 35
	call os_move_cursor
	mov si, .msg3
	call os_print_string

	mov si, [.ax]
	call os_print_string

	call os_hide_cursor
	
	pop bx
	pop ax
	
	mov16 dx, 35, 7
	call os_move_cursor
	
	mov si, .msg
	call os_print_string
	
	call os_print_4hex
	
	mov al, ':'
	call os_putchar
	
	mov ax, bx
	call os_print_4hex
	
	mov16 dx, 35, 8
	call os_move_cursor
	
	mov si, .msg1
	call os_print_string
	
	mov ax, sp
	call os_print_4hex
	
	cli
	hlt
	
	.msg 			db 'Crash location: ', 0
	.msg1			db 'Stack pointer: ', 0
	
	.title_msg		db 'MichalOS Fatal Error'
	.footer_msg		db 0
	
	.msg0			db 'MichalOS has encountered a critical error.', 0
	.msg3			db 'Error: ', 0

	.ax				dw 0

	bomblogo	db 9, 16
				db 00000000b, 00000000b, 00000000b, 00000000b, 00000000b, 00100000b, 00000000b, 01100000b, 00000000b
				db 00000000b, 00000000b, 00000000b, 00000000b, 00000100b, 00000010b, 00000001b, 10000000b, 00000000b
				db 00000000b, 00000000b, 00000000b, 00000000b, 00000000b, 10000100b, 10000000b, 00000000b, 00000000b
				db 00000000b, 00000000b, 00000000b, 01101010b, 10100101b, 00000001b, 01010000b, 10001000b, 10000000b
				db 00000000b, 00000000b, 00000011b, 00000000b, 00000000b, 10101000b, 00000000b, 01000000b, 00000000b
				db 00000000b, 00000000b, 01010111b, 01010100b, 00000000b, 00011000b, 00100000b, 00100100b, 00000000b
				db 00000000b, 00000000b, 11111111b, 11111100b, 00000000b, 10000000b, 00100000b, 00000010b, 00000000b
				db 00000000b, 01011111b, 11111111b, 11111111b, 11010100b, 00000000b, 00100000b, 00000000b, 00000000b
				db 00000001b, 11111111b, 11111111b, 11111111b, 11111101b, 00000000b, 00000000b, 00000000b, 00000000b
				db 00000111b, 11111111b, 11111111b, 11111111b, 11111111b, 01000000b, 00000000b, 00000000b, 00000000b
				db 00001111b, 11111111b, 11111111b, 11111111b, 11111111b, 11000000b, 00000000b, 00000000b, 00000000b
				db 00001111b, 11111111b, 11111111b, 11111111b, 11111111b, 11000000b, 00000000b, 00000000b, 00000000b
				db 00001111b, 11111111b, 11111111b, 11111111b, 11111111b, 11000000b, 00000000b, 00000000b, 00000000b
				db 00000011b, 11111111b, 11111111b, 11111111b, 11111111b, 00000000b, 00000000b, 00000000b, 00000000b
				db 00000000b, 11111111b, 11111111b, 11111111b, 11111100b, 00000000b, 00000000b, 00000000b, 00000000b
				db 00000000b, 00001010b, 11111111b, 11111110b, 10000000b, 00000000b, 00000000b, 00000000b, 00000000b
				