; ------------------------------------------------------------------
; MichalOS Font Editor
; ------------------------------------------------------------------

	%INCLUDE "michalos.inc"

start:
	push ds
	
	mov ax, 160h
	mov ds, ax
	
	mov cx, 4096 / 4
	clr si
	mov di, 16384

	rep movsd
	
	pop ds
	
	jmp .decode

.redraw_entire:
	call .draw_background

.main_loop:
	call .draw_box_16
	call os_hide_cursor
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
	
	cmp al, 'q'
	je .black
	
	cmp al, 'w'
	je .white
	
	cmp al, 'p'
	je .import
	
	jmp .main_loop

.import:
	call char_picker
	jc .redraw_entire

	movzx ax, byte [char_picker.selected_char]

	mov bx, 16
	mul bx
	add ax, 16384
	mov si, ax

	movzx ax, byte [.current_char]
	
	mov bx, 16
	mul bx
	add ax, 16384
	mov di, ax

	mov cx, 16
	rep movsb
	jmp .decode
	
.black:	
	call .get_buffer
	mov byte [si], 0
	jmp .main_loop
	
.white:	
	call .get_buffer
	mov byte [si], 1
	jmp .main_loop
	
.file_menu:
	mov ax, .file_list
	mov bx, 27
	call os_option_menu
	
	jc .redraw_entire
	
	cmp ax, 1
	je .new
	
	cmp ax, 2
	je .open
	
	cmp ax, 3
	je .save
	
	cmp ax, 4
	je .exit
	
.new:
	mov di, buffer
	clr al
	mov cx, 256 * 16
	rep stosb
	mov si, buffer
	jmp .redraw_entire
	
.open:
	call char_picker
	jc .redraw_entire

	mov al, [char_picker.selected_char]
	mov [.current_char], al
	
.decode:	
	movzx ax, byte [.current_char]
	
	mov bx, 16
	mul bx
	add ax, 16384
	mov si, ax
	
	clr dx
	mov di, buffer
	
.open_loop:
	lodsb
	mov bl, al
	clr cx

.decode_loop:
	rol bl, 1
	mov al, bl
	and al, 01h
	stosb
	inc cx
	cmp cx, 8
	jl .decode_loop
	
	inc dx
	cmp dx, 16
	jl .open_loop
	
	jmp .redraw_entire
	
.save:
	movzx di, byte [.current_char]
	shl di, 4
	add di, 16384

	clr dx
	mov si, buffer
	
.save_loop:
	clr cx
	clr bl
	
.encode_loop:
	lodsb
	add bl, al
	rol bl, 1
	inc cx
	cmp cx, 8
	jl .encode_loop
	
	mov al, bl
	ror al, 1
	stosb
	inc dx
	cmp dx, 16
	jl .save_loop

	push es
	
	mov ax, 160h
	mov es, ax
	
	mov cx, 4096 / 4
	clr di
	mov si, 16384

	rep movsd

	pop es
	
	mov ax, .font_file
	call os_remove_file
	jc .save_error

	mov ax, .font_file
	mov cx, 4096
	mov bx, 16384
	call os_write_file
	jc .save_error
	
	mov ax, .save_ok_msg
	clr bx
	clr cx
	clr dx
	call os_dialog_box
	
	call os_reset_font
	jmp .redraw_entire
	
.save_error:
	mov ax, .save_error_msg
	clr bx
	clr cx
	clr dx
	call os_dialog_box
	jmp .redraw_entire
	
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
	cmp byte [.cursor_x], 7
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
	movzx ax, byte [.cursor_x]
	and al, 07h
	movzx bx, byte [.cursor_y]
	and bl, 0Fh
	rol bl, 3
	add al, bl
	mov si, buffer
	add si, ax
	pop bx
	pop ax
	ret

.draw_box_16:
	mov16 ax, 0C4h, 09h
	mov cx, 16
	mov16 dx, 2, 2
	mov bx, 7
	call os_move_cursor
	int 10h				; Clear the upper cursor area
	
	mov16 ax, 0C4h, 09h
	mov cx, 16
	mov16 dx, 2, 19
	mov bx, 7
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
	mov16 dx, 18, 3

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
	mov dl, 18
	
	call os_move_cursor
	int 10h

	mov cx, 1			; Draw the corners
	mov al, 0DAh
	mov16 dx, 1, 2
	call os_move_cursor
	int 10h
	mov al, 0C0h
	mov16 dx, 1, 19
	call os_move_cursor
	int 10h
	mov al, 0BFh
	mov16 dx, 18, 2
	call os_move_cursor
	int 10h
	mov al, 0D9h
	mov dh, 19
	call os_move_cursor
	int 10h
	
	mov16 ax, 32, 09h	; int 10h function + Full character
	mov cx, 2			; Print 2 characters
	mov16 dx, 2, 3		; Sprite position
	clr bh				; Video page
	mov si, buffer		; Buffer location

.draw_loop:
	call .getcolor		; Get the color
	call os_move_cursor
	int 10h
	inc si
	add dl, 2
	cmp dl, 2 + 2 * 8	; End of X?
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

	ret

.getcolor:
	mov bl, [si]
	cmp bl, 01h
	jne .gotcolor
	
	mov bl, 0Fh

.gotcolor:
	push ax
	mov al, bl
	xor al, 0Fh
	rol bl, 4
	or bl, al
	pop ax
	ret
	
.draw_background:
	mov ax, .title_msg
	mov bx, .footer_msg
	mov cx, 7
	call os_draw_background

	mov16 dx, 24, 0
	call os_move_cursor
	mov al, [.current_char]
	call os_print_2hex
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
	
	.font_file			db 'FONT.SYS', 0
	.file_msg			db 'Choose an option...', 0
	.file_list			db 'Clear current character,Open a character,Save changes,Exit', 0
	.save_error_msg		db 'Error saving the file!', 0
	.title_msg			db 'MichalOS Font Editor -', 0
	.footer_msg			db '[F1] - File', 0
	.save_ok_msg		db 'File saved.', 0
	.help0				db 'Controls:', 0
	.help1				db 'Q/W - Black/White', 0
	.help2				db 'P - Import from another character', 0
	.blank				db 0
	.cursor_x			db 0
	.cursor_y			db 0
	.current_char		db 0
	.number_msg			db 'Enter character number:', 0
	.number_buffer		times 8 db 0
	.driversgmt			dw 0
	
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
	cmp al, 0
	jne .char_loop
	
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
	je .apply
	
	cmp al, 27
	je .exit
	
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
	
.apply:
	clc
	ret

.exit:
	stc
	ret

	.ascii_msg		db 'ASCII code: ', 0
	.char_msg		db 'Character: ', 0
	.selected_char	db 0
	
sub_putchar:
	pusha
	mov ah, 09h
	clr bh
	mov cx, 1
	int 10h
	popa
	ret
	
buffer:
	
; ------------------------------------------------------------------
