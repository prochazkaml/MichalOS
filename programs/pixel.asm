; ------------------------------------------------------------------
; MichalOS Pixel Editor
; ------------------------------------------------------------------

	%INCLUDE "include/program.inc"

start:
	call .draw_background
	
.main_loop:
	call .draw_box_16
	call os_wait_for_key
	cmp ah, 72
	je .cursor_up
	
	cmp ah, 75
	je .cursor_left
	
	cmp ah, 77
	je .cursor_right
	
	cmp ah, 80
	je .cursor_down

	cmp al, 27
	je .exit
	
	cmp al, 'p'
	je .mode_change
	
	cmp ah, 59			; F1
	je .file_menu
	
	cmp ax, 1F13h		; Ctrl + S
	je .save
	
	cmp ax, 180Fh		; Ctrl + O
	je .open
	
	cmp ax, 310Eh		; Ctrl + N
	je .new
	
	cmp ax, 1011h		; Ctrl + Q
	je .new
	
	cmp ax, 1F00h		; Ctrl + Alt + S
	je .save_as

	cmp ah, 16			; Color 0-7
	jl .not_1row
	
	cmp ah, 23
	jg .not_1row
	
	sub ah, 16			; Turn this into a color (0-7)
	
	call .get_buffer
	
	mov [si], ah
	
	jmp .main_loop
	
.not_1row:
	cmp ah, 30			; Color 8-15
	jl .not_2row
	
	cmp ah, 37
	jg .not_2row
	
	sub ah, 30			; Turn this into a color (8-15)
	add ah, 8
	
	call .get_buffer
	
	mov [si], ah
	
	jmp .main_loop

.not_2row:
	jmp .main_loop
	
.file_menu:
	mov ax, .file_list
	call os_option_menu
	
	jc start
	
	cmp ax, 1
	je .new
	
	cmp ax, 2
	je .open
	
	cmp ax, 3
	je .save
	
	cmp ax, 4
	je .save_as
	
	cmp ax, 5
	je .exit
	
.new:
	mov di, buffer
	clr al
	mov cx, 256
	rep stosb
	mov si, buffer
	jmp start
	
.open:
	mov bx, .extension_number
	call os_file_selector_filtered		; Get filename
	jc start
	
	mov bx, ax			; Save filename for now

	mov di, ax

	call os_string_length
	add di, ax			; DI now points to last char in filename

	dec di
	dec di
	dec di				; ...and now to first char of extension!
	
	pusha
	
	mov si, .pix_extension
	mov cx, 3
	rep cmpsb			; Does the extension contain 'PCX'?
	je .valid_pix_extension		; Skip ahead if so
	
	popa
					; Otherwise show error dialog
	clr dx		; One button for dialog box
	mov ax, .err_string
	mov bx, .err_string2
	clr cx
	call os_dialog_box
	jmp .open
	
.valid_pix_extension:
	popa
	mov ax, bx
	mov si, ax
	mov di, .load_file
	call os_string_copy
	mov cx, buffer
	call os_load_file
	mov byte [.save_flag], 1
	jmp start
	
.save:
	cmp byte [.save_flag], 0
	je .save_as
	
	mov ax, .load_file
	call os_remove_file
	jc .save_error
	
	mov ax, .load_file
	mov cx, 256
	mov bx, buffer
	call os_write_file
	jc .save_error
	
	mov ax, .save_ok_msg
	clr bx
	clr cx
	clr dx
	call os_dialog_box
	
	jmp start

.save_error:
	mov ax, .save_error_msg
	clr bx
	clr cx
	clr dx
	call os_dialog_box
	jmp start
	
.save_as:
	mov ax, .filenamebuff
	mov bx, .save_msg
	call os_input_dialog
	
	call os_string_uppercase
	
	mov cx, 256
	mov bx, buffer
	call os_write_file
	jc .save_error
	
	mov byte [.save_flag], 1
	mov si, .filenamebuff
	mov di, .load_file
	call os_string_copy
	jmp start
	
.mode_change:
	xor byte [.mode], 01h
	jmp .main_loop
	
.cursor_up:
	cmp byte [.cursor_y], 0
	je .main_loop
	dec byte [.cursor_y]
	jmp .main_loop
	
.cursor_left:
	cmp byte [.cursor_x], 0
	je .main_loop
	dec byte [.cursor_x]
	jmp .main_loop
	
.cursor_right:
	cmp byte [.cursor_x], 15
	je .main_loop
	inc byte [.cursor_x]
	jmp .main_loop
	
.cursor_down:
	cmp byte [.cursor_y], 15
	je .main_loop
	inc byte [.cursor_y]
	jmp .main_loop
	
.get_buffer:
	push ax
	push bx
	clr ah
	clr bh
	mov al, [.cursor_x]
	and al, 0Fh
	mov bl, [.cursor_y]
	and bl, 0Fh
	rol bl, 4
	add al, bl
	mov si, buffer
	add si, ax
	pop bx
	pop ax
	cmp byte [.mode], 1
	je .fill
	ret
	
.fill:
	pusha
	mov di, buffer
	rol ax, 8
	mov cx, 256
	rep stosb
	mov si, buffer
	popa
	ret
	
.draw_box_16:
	mov cx, 32
	mov16 ax, 0C4h, 09h
	mov16 dx, 2, 2
	mov16 bx, 7, 0
	call os_move_cursor
	int 10h				; Clear the upper cursor area
	
	mov cx, 32
	mov16 ax, 0C4h, 09h
	mov16 dx, 2, 19
	mov16 bx, 7, 0
	call os_move_cursor
	int 10h				; Clear the bottom cursor area
	
	mov cx, 1
	mov al, 0B3h
	mov16 dx, 1, 3

.clear_left:
	call os_move_cursor
	int 10h				; Clear the left cursor area
	
	inc dh
	cmp dh, 3 + 16
	jl .clear_left
	
	mov al, 0B3h
	mov16 dx, 34, 3

.clear_right:
	call os_move_cursor
	int 10h				; Clear the right cursor area
	
	inc dh
	cmp dh, 3 + 16
	jl .clear_right
	
	mov cx, 1			; Draw the cursor
	mov al, 19h
	mov dl, [.cursor_x]
	shl dl, 1			; DL = DL * 2
	add dl, 2
	mov dh, 2
	mov bl, 7
	
	call os_move_cursor
	int 10h

	add dh, 17
	mov al, 18h
	call os_move_cursor
	int 10h

	mov al, 1Ah
	mov dh, [.cursor_y]
	add dh, 3
	mov dl, 1
	
	call os_move_cursor
	int 10h
	
	mov al, 1Bh
	mov dl, 34
	
	call os_move_cursor
	int 10h

	mov cx, 1			; Draw the corners
	mov al, 0DAh
	mov16 dx, 1, 2
	call os_move_cursor
	int 10h
	mov al, 0C0h
	mov dh, 19
	call os_move_cursor
	int 10h
	mov al, 0BFh
	mov16 dx, 34, 2
	call os_move_cursor
	int 10h
	mov al, 0D9h
	mov dh, 19
	call os_move_cursor
	int 10h
	
	mov16 ax, 32, 09h	; int 10h function + Full character
	mov cx, 2			; Print 2 characters
	mov16 dx, 2, 3		; Sprite position
	clr bh		; Video page
	mov si, buffer		; Buffer location
.draw_loop:
	call .getcolor		; Get the color
	call os_move_cursor
	int 10h
	inc si
	add dl, 2
	cmp dl, 2 + 2 * 16	; End of X?
	jl .draw_loop
	mov dl, 2
	inc dh
	cmp dh, 3 + 16		; End of Y?
	jl .draw_loop
	
	mov dl, [.cursor_x]	; Draw a visible cursor
	shl dl, 1			; DL = DL * 2
	add dl, 2
	mov dh, [.cursor_y]
	add dh, 3
	call os_move_cursor

	mov al, '['
	call os_putchar
	mov al, ']'
	call os_putchar

	mov16 dx, 29, 0
	call os_move_cursor
	mov si, .load_file
	call os_print_string
	
	mov16 dx, 40, 3
	call os_move_cursor
	mov si, .mode_msg
	call os_print_string
	cmp byte [.mode], 1
	je .fill_set
	mov si, .no_msg
	call os_print_string
	call os_hide_cursor
	ret

.getcolor:
	mov bl, [si]
	push ax
	mov al, bl
	xor al, 0Fh
	rol bl, 4
	or bl, al
	pop ax
	ret

.fill_set:
	mov si, .yes_msg
	call os_print_string
	call os_hide_cursor
	ret
	
.draw_background:
	mov ax, .title_msg
	mov bx, .footer_msg
	mov cx, 7
	call os_draw_background

	mov16 dx, 40, 5
	call os_move_cursor
	mov si, .help0
	call os_print_string
	add dh, 2
	call os_move_cursor
	mov si, .help1
	call os_print_string
	inc dh
	call os_move_cursor
	mov si, .help2
	call os_print_string
	ret

.exit:
	ret
	
	.file_list			db 'New,Open...,Save,Save as...,Exit', 0
	.save_error_msg		db 'Error saving the file!', 0
	.save_msg			db 'Enter a filename (PICTURE.PIX):', 0
	.title_msg			db 'MichalOS Pixel Art Editor - ', 0
	.footer_msg			db '[F1] - File, [P] - Toggle erase mode', 0
	.mode_msg			db 'Erase mode: ', 0
	.yes_msg			db 'on ', 0
	.no_msg				db 'off ', 0
	.save_ok_msg		db 'File saved.', 0
	.help0				db 'Controls:', 0
	.help1				db 'Q,W,E,R,T,Y,U,I - Colors 0-7', 0
	.help2				db 'A,S,D,F,G,H,J,K - Colors 8-15', 0
	.blank				db 0
	.cursor_x			db 0
	.cursor_y			db 0
	.mode				db 0
	.load_file			db 'Unnamed picture', 0
	.filenamebuff		times 60 db 0
	.save_flag			db 0
	.extension_number	db 1
	.pix_extension		db 'PIX', 0
	.err_string			db 'Invalid file type!', 0
	.err_string2		db '16x16 PIX only!', 0

	
buffer:
	
; ------------------------------------------------------------------
