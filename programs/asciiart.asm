; ------------------------------------------------------------------
; MichalOS Ascii Artist
; ------------------------------------------------------------------

	%INCLUDE "include/program.inc"
	
start:
	call draw_background
	mov di, buffer
	mov ax, 0720h
	mov cx, 80 * 25
	rep stosw
	
.loop:
	call sub_draw_screen	
	call os_wait_for_key
	
	cmp ah, 72
	je .go_up
	
	cmp ah, 75
	je .go_left
	
	cmp ah, 77
	je .go_right
	
	cmp ah, 80
	je .go_down

	cmp ax, 0F09h	; Tab
	je .go_far_right
	
	cmp ax, 0F00h	; Shift + Tab
	je .go_far_left
	
	cmp al, 8
	je .backspace
	
	cmp al, 13
	je .go_down
	
	cmp ah, 59
	je .file_menu
	
	cmp ah, 60
	je .new_attrib
	
	cmp ah, 61
	je .fill_attrib
	
	cmp ah, 62
	je char_picker

	cmp ah, 63
	je .paste_char
	
	cmp ah, 64
	je .fill_char
	
	cmp ah, 134
	je .help
	
	test al, al
	jz .loop
	
	cmp al, 27
	je .exit
	
	call sub_get_mem_ptr
	mov ah, [current_attrib]
	stosw
	
	jmp .go_right
	
.exit:
	ret	

.file_menu:
	mov ax, .file_list
	call os_option_menu
	
	jc .loop
	
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

.paste_char:
	mov ah, [current_attrib]
	mov al, [char_picker.selected_char]
	call sub_get_mem_ptr
	stosw
	jmp .go_right

.fill_char:
	mov di, buffer
	mov cx, 80 * 25
	mov al, [char_picker.selected_char]
	
.fill_char_loop:
	stosb
	inc di
	
	loop .fill_char_loop
	
	jmp .loop
	
	
.new_attrib:
	mov ax, .color_msg
	mov bx, .color2_msg
	xor cx, cx
	xor dx, dx
	call os_dialog_box
	
	call sub_draw_screen

	call os_color_selector
	jc .loop
	mov bl, al
	
	call os_color_selector
	jc .loop
	shl al, 4
	add bl, al
	
	mov [current_attrib], bl
	jmp .loop
	
	.color_msg	db 'First you will pick a foreground color', 0
	.color2_msg	db 'and then a background color.', 0

.fill_attrib:
	mov ax, .color_msg
	mov bx, .color2_msg
	xor cx, cx
	xor dx, dx
	call os_dialog_box
	
	call sub_draw_screen

	call os_color_selector
	jc .loop
	mov bl, al
	
	call os_color_selector
	jc .loop
	shl al, 4
	add bl, al
	
	mov di, buffer + 1
	mov cx, 80 * 25
	mov al, bl
	
.fill_loop:
	stosb
	inc di
	
	loop .fill_loop
	
	jmp .loop

	
.backspace:
	dec byte [cursor_x]
	cmp byte [cursor_x], 0
	jl .go_right
	call sub_get_mem_ptr
	mov al, 32
	stosb
	jmp .loop

.go_up:
	dec byte [cursor_y]
	mov al, [cursor_y]
	cmp al, [cursor_y_offset]
	jge .loop
	
	dec byte [cursor_y_offset]
	cmp al, 255
	jne .loop
	
	mov byte [cursor_y_offset], 2
	mov byte [cursor_y], 24
	jmp .loop

.go_down:
	inc byte [cursor_y]
	mov al, [cursor_y]
	mov bl, [cursor_y_offset]
	add bl, 23
	cmp al, bl
	jl .loop
	
	inc byte [cursor_y_offset]
	cmp al, 25
	jne .loop
	
	mov byte [cursor_y_offset], 0
	mov byte [cursor_y], 0
	jmp .loop
	
.go_left:
	dec byte [cursor_x]
	cmp byte [cursor_x], 0
	jge .loop
	
	mov byte [cursor_x], 79
	jmp .loop
	
.go_far_left:
	sub byte [cursor_x], 8
	cmp byte [cursor_x], 0
	jge .loop
	
	add byte [cursor_x], 80
	jmp .loop
	
.go_right:
	inc byte [cursor_x]
	cmp byte [cursor_x], 80
	jne .loop
	
	mov byte [cursor_x], 0
	jmp .loop
	
.go_far_right:
	add byte [cursor_x], 8
	cmp byte [cursor_x], 80
	jl .loop
	
	sub byte [cursor_x], 80
	jmp .loop
	
.help:
	mov ax, .help_list
	mov bx, .help_msg
	mov cx, .help_msg2
	call os_list_dialog
	jmp .loop
	
	.help_list		db '[F1] - File,[F2] - Color picker,[F3] - Fill screen with color,[F4] - Character picker,[F5] - Use the chosen character,[F6] - Fill screen with the chosen character', 0
	.help_msg		db 'Helpful shortcuts:', 0
	.help_msg2		db 0
	
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
	
	mov si, .asc_extension
	mov cx, 3
	rep cmpsb			; Does the extension contain 'PCX'?
	je .valid_asc_extension		; Skip ahead if so
	
	popa
					; Otherwise show error dialog
	clr dx				; One button for dialog box
	mov ax, .err_string
	mov bx, .err_string2
	clr cx
	call os_dialog_box
	jmp .open
	
.valid_asc_extension:
	popa
	mov ax, bx
	mov si, ax
	mov di, .load_file
	call os_string_copy
	mov cx, buffer
	call os_load_file
	mov byte [.save_flag], 1
	jmp .loop
	
.save:
	cmp byte [.save_flag], 0
	je .save_as
	
	mov ax, .load_file
	call os_remove_file
	jc .save_error
	
	mov ax, .load_file
	mov cx, 80 * 25 * 2
	mov bx, buffer
	call os_write_file
	jc .save_error
	
.save_ok:
	mov ax, .save_ok_msg
	clr bx
	clr cx
	clr dx
	call os_dialog_box
	
	jmp .loop

.save_error:
	mov ax, .save_error_msg
	clr bx
	clr cx
	clr dx
	call os_dialog_box
	jmp .loop
	
.save_as:
	mov ax, .filenamebuff
	mov bx, .save_msg
	call os_input_dialog
	
	call os_string_uppercase
	
	mov cx, 80 * 25 * 2
	mov bx, buffer
	call os_write_file
	jc .save_error
	
	mov byte [.save_flag], 1
	mov si, .filenamebuff
	mov di, .load_file
	call os_string_copy
	jmp .save_ok

	.file_list			db 'New,Open...,Save,Save as...,Exit', 0
	.save_error_msg		db 'Error saving the file!', 0
	.save_msg			db 'Enter a filename (PICTURE.ASC):', 0
	.load_file			db 'Unnamed picture', 0
	.filenamebuff		times 60 db 0
	.save_flag			db 0
	.extension_number	db 1
	.asc_extension		db 'ASC', 0
	.err_string			db 'Invalid file type!', 0
	.err_string2		db '80x25 ASC only!', 0
	.save_ok_msg		db 'File saved.', 0
	
char_picker:
	mov bl, [57001]
	mov dx, 2 * 256 + 11
	mov si, 58
	mov di, 23
	call os_draw_block
	
	mov bl, 0F0h
	mov dx, 3 * 256 + 12
	mov si, 36
	mov di, 22
	call os_draw_block
	
	mov dx, 5 * 256 + 13
	clr al
	
.vert_loop:
	call os_move_cursor
	call os_print_1hex
	inc al
	inc dh
	cmp al, 16
	jne .vert_loop
	
	mov dx, 4 * 256 + 15
	clr al
	
.horiz_loop:
	call os_move_cursor
	call os_print_1hex
	inc al
	add dl, 2
	cmp al, 16
	jne .horiz_loop
	
.redraw:
	clr al
	mov dx, 5 * 256 + 15
	mov bl, 0F0h
	
.char_loop:
	call os_move_cursor

	call sub_putchar
	
	add dl, 2
	inc al
	cmp dl, 15 + 2 * 16
	jne .char_loop
	
	mov dl, 15
	inc dh
	test al, al
	jnz .char_loop
	
	mov dx, 3 * 256 + 50
	call os_move_cursor
	mov si, .ascii_msg
	call os_print_string
	
	mov al, [.selected_char]
	call os_print_2hex
	
	mov dx, 5 * 256 + 50
	call os_move_cursor
	mov si, .char_msg
	call os_print_string
	
	mov al, [.selected_char]
	mov bl, [57001]
	call sub_putchar
	
	mov dh, [.selected_char]
	and dh, 0F0h
	shr dh, 4
	add dh, 5
	
	mov dl, [.selected_char]
	and dl, 0Fh
	shl dl, 1
	add dl, 15
	call os_move_cursor
	
.loop:
	call os_wait_for_key
	
	cmp ah, 72
	je .go_up
	
	cmp ah, 75
	je .go_left
	
	cmp ah, 77
	je .go_right
	
	cmp ah, 80
	je .go_down

	cmp al, 13
	je start.loop
	
	cmp al, 27
	je start.loop
	
	jmp .loop
	
.go_up:
	sub byte [.selected_char], 16
	jmp .redraw
	
.go_down:
	add byte [.selected_char], 16
	jmp .redraw
	
.go_left:
	dec byte [.selected_char]
	jmp .redraw
	
.go_right:
	inc byte [.selected_char]
	jmp .redraw
	
	.ascii_msg		db 'ASCII code: ', 0
	.char_msg		db 'Character: ', 0
	.selected_char	db 0
	
draw_background:
	mov ax, .title_msg
	mov bx, .footer_msg
	mov cx, 7
	call os_draw_background
	ret
	
	.title_msg			db 'MichalOS ASCII Artist - ', 0
	.footer_msg			db '[F1] - File, [F2] - Change color, [F3] - Fill with color, [F12] - More help', 0
	
sub_draw_screen:
	call os_hide_cursor
	mov si, buffer	

	mov ax, 160			; Get the drawable screen area
	movzx bx, byte [cursor_y_offset]
	mul bx
	add si, ax
	
	clr bh
	mov cx, 1
	mov dx, 100h
	
.loop:
	lodsw
	
	call os_move_cursor

	mov bl, ah
	mov ah, 9
	int 10h
	
	inc dl
	cmp dl, 80
	jne .loop
	
	clr dl
	inc dh
	cmp dh, 24
	jne .loop
	
	mov dx, 51
	call os_move_cursor
	
	mov si, .x_msg
	call os_print_string
	
	movzx ax, byte [cursor_x]
	call os_print_int
	
	mov si, .y_msg
	call os_print_string
	
	movzx ax, byte [cursor_y]
	call os_print_int
	call os_print_space
	
	mov dx, 25
	call os_move_cursor
	
	mov ax, 0920h
	mov bx, 70h
	mov cx, 20
	int 10h
	
	mov si, start.load_file
	call os_print_string
	
	mov dx, [cursor_x]
	inc dh
	sub dh, [cursor_y_offset]
	call os_move_cursor	
	call os_show_cursor
	ret
	
	.x_msg		db 'X: ', 0
	.y_msg		db ' Y: ', 0
	
	
sub_get_mem_ptr:
	pusha
	movzx ax, [cursor_y]
	mov bx, 80
	mul bx
	movzx bx, [cursor_x]
	add ax, bx
	shl ax, 1
	add ax, buffer
	mov [.tmp], ax
	popa
	mov di, [.tmp]
	ret
	
	.tmp	dw 0
	
sub_putchar:
	pusha
	mov ah, 09h
	clr bh
	mov cx, 1
	int 10h
	popa
	ret
	
	cursor_x			db 0
	cursor_y			db 0
	cursor_y_offset		db 0
	current_attrib		db 7
	
; ------------------------------------------------------------------

buffer:
