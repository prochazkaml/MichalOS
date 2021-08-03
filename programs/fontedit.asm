; ------------------------------------------------------------------
; MichalOS Font Editor
; ------------------------------------------------------------------

	%INCLUDE "michalos.inc"

start:
	call .draw_background

	push ds
	
	mov ax, 160h
	mov ds, ax
	
	mov cx, 4096 / 4
	mov si, 0
	mov di, 16384

	rep movsd
	
	pop ds
	
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
	mov ax, .number_buffer
	mov bx, .number_msg
	call os_input_dialog
	
	mov si, .number_buffer
	call os_string_to_hex
	
	mov bx, 16
	mul bx
	add ax, 16384
	mov si, ax

	mov al, [.current_char]
	mov ah, 0
	
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
	mov bx, .file_msg
	mov cx, .blank
	call os_list_dialog
	
	jc start
	
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
	mov al, 0
	mov cx, 256 * 16
	rep stosb
	mov si, buffer
	jmp start
	
.open:
	mov ax, .number_buffer
	mov bx, .number_msg
	call os_input_dialog
	
	mov si, .number_buffer
	call os_string_to_hex
	
	mov [.current_char], al
	
.decode:	
	mov al, [.current_char]
	mov ah, 0
	
	mov bx, 16
	mul bx
	add ax, 16384
	mov si, ax
	
	mov dx, 0
	mov di, buffer
	
.open_loop:
	lodsb
	mov bl, al
	mov cx, 0

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
	
	jmp start
	
.save:
	movzx di, byte [.current_char]
	shl di, 4
	add di, 16384

	mov dx, 0
	mov si, buffer
	
.save_loop:
	mov cx, 0
	mov bl, 0
	
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
	
	mov ax, 800h
	mov es, ax
	
	mov cx, 4096 / 4
	mov di, 0
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
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	
	jmp start
	
.save_error:
	mov ax, .save_error_msg
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	jmp start
	
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
	mov ah, 0
	mov bh, 0
	mov al, [.cursor_x]
	and al, 07h
	mov bl, [.cursor_y]
	and bl, 0Fh
	rol bl, 3
	add al, bl
	mov si, buffer
	add si, ax
	pop bx
	pop ax
	ret

.draw_box_16:
	mov al, 0C4h
	mov cx, 16
	mov dl, 2
	mov dh, 2
	mov ah, 09h
	mov bh, 0
	mov bl, 7
	call os_move_cursor
	int 10h				; Clear the upper cursor area
	
	mov al, 0C4h
	mov cx, 16
	mov dl, 2
	mov dh, 19
	mov ah, 09h
	mov bh, 0
	mov bl, 7
	call os_move_cursor
	int 10h				; Clear the bottom cursor area
	
	mov cx, 1
	mov al, 0B3h
	mov dl, 1
	mov dh, 3
.clear_left:
	call os_move_cursor
	int 10h				; Clear the left cursor area
	
	inc dh
	cmp dh, 3 + 16
	jl .clear_left
	
	mov al, 0B3h
	mov dl, 18
	mov dh, 3
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
	mov dl, 1
	mov dh, 2
	call os_move_cursor
	int 10h
	mov al, 0C0h
	mov dl, 1
	mov dh, 19
	call os_move_cursor
	int 10h
	mov al, 0BFh
	mov dl, 18
	mov dh, 2
	call os_move_cursor
	int 10h
	mov al, 0D9h
	mov dh, 19
	call os_move_cursor
	int 10h
	
	mov al, 219			; Full character
	mov cx, 2			; Print 2 characters
	mov dl, 2			; Sprite X position
	mov dh, 3			; Sprite Y position
	mov ah, 09h			; int 10h function
	mov bh, 0			; Video page
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
	
.getcolor:
	mov bl, [si]
	cmp bl, 01h
	jne .gotcolor
	
	mov bl, 0Fh
.gotcolor:
	ret
	
.draw_background:
	mov ax, .title_msg
	mov bx, .footer_msg
	mov cx, 7
	call os_draw_background
	mov dl, 24
	mov dh, 0
	call os_move_cursor
	mov al, [.current_char]
	call os_print_2hex
	mov dl, 40
	mov dh, 5
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
	call os_reset_font
	
	ret
	
	.font_file			db 'FONT.SYS', 0
	.file_msg			db 'Choose an option...', 0
	.file_list			db 'New,Open...,Save,Exit', 0
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
	
buffer:
	
; ------------------------------------------------------------------
