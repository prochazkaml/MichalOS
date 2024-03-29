; ------------------------------------------------------------------
; MichalOS Memory Editor
; ------------------------------------------------------------------

	%INCLUDE "include/program.inc"

start:
	mov [.segment], cs

	call .draw_background
	
	mov16 dx, 11, 4
	call os_move_cursor
	
	clr al

.hexcharsloop1:
	call os_print_2hex
	call os_print_space
	
	inc al
	cmp al, 16
	jl .hexcharsloop1
	
	call os_print_space
	clr al
	
.hexcharsloop2:
	call os_print_1hex
	
	inc al
	cmp al, 16
	jl .hexcharsloop2
	
.loop:
	call .draw
	call .runprompt

	lodsb
	cmp al, 'Q'				; 'Q' typed?
	je .exit
	cmp al, 'O'
	je .inputaddress
	cmp al, 'S'
	je .inputsegment
	cmp al, 'D'
	je .inputdata
	cmp al, 'H'
	je .help
	cmp al, 'W'
	je .save
	cmp al, 'L'
	je .load
	jmp .loop
	
.save:
	lodsb
	cmp al, 'D'
	je .savedecimal
	cmp al, 'H'
	je .savehexadecimal
	jmp .loop
	
.savedecimal:
	sub si, 2
	call os_string_parse
	add ax, 2
	mov si, ax
	call os_string_to_int
	
	jmp .copy
	
.savehexadecimal:
	sub si, 2
	call os_string_parse
	add ax, 2
	mov si, ax
	call os_string_to_hex
	
.copy:
	mov cx, ax		; File size
	mov ax, bx		; Filename
	
	; Save the file

	push es
	mov es, [.segment]
	mov bx, [.offset]
	call os_write_file
	pop es
	
	jc .error
	
	jmp .loop	

.load:
	mov ax, si
	
	push es
	mov es, [.segment]
	mov cx, [.offset]
	call os_load_file
	pop es
	
	jc .error
	
	jmp .loop	


.help:
	mov ax, .help_msg0
	mov bx, .help_title0
	mov cx, .help_title1
	call os_list_dialog
	
	jmp start
	
.inputaddress:
	lodsb
	cmp al, 'D'
	je .addressdecimal
	cmp al, 'H'
	je .addresshexadecimal
	jmp .loop
	
.addressdecimal:
	call os_string_to_int
	mov [.offset], ax
	jmp .loop
	
.addresshexadecimal:
	call os_string_to_hex
	mov [.offset], ax
	jmp .loop
	
.inputsegment:
	lodsb
	cmp al, 'D'
	je .segmentdecimal
	cmp al, 'H'
	je .segmenthexadecimal
	jmp .loop
	
.segmentdecimal:
	call os_string_to_int
	mov [.segment], ax
	jmp .loop
	
.segmenthexadecimal:
	call os_string_to_hex
	mov [.segment], ax
	jmp .loop
	
.inputdata:
	lodsb
	cmp al, 'D'
	je .datadecimal
	cmp al, 'H'
	je .datahexadecimal
	jmp .loop
	
.datadecimal:
	mov byte [.data_mode], 1
	call .draw
	call .runprompt
	mov byte [.data_mode], 0
	
	cmp byte [si], 'Q'
	je .loop

	call os_string_to_int
	
	push es
	mov si, [.offset]
	mov es, [.segment]
	mov [es:si], al
	pop es

	inc word [.offset]
	
	jmp .datadecimal
	
.datahexadecimal:
	mov byte [.data_mode], 1
	call .draw
	call .runprompt
	mov byte [.data_mode], 0
	
	cmp byte [si], 'Q'
	je .loop

	call os_string_to_hex

	push es
	mov si, [.offset]
	mov es, [.segment]
	mov [es:si], al
	pop es

	inc word [.offset]
	
	jmp .datahexadecimal
	
.statusdraw:
	mov16 dx, 40, 2
	call os_move_cursor
	
	mov ax, [.segment]
	call os_print_4hex
	
	mov si, .semicolon
	call os_print_string
	
	mov ax, [.offset]
	call os_print_4hex
	ret

.draw:
	call .bardraw
	call .datadraw
	call .asciidraw
	jmp .statusdraw

.runprompt:
	mov16 dx, 0, 2	; Print the input label
	call os_move_cursor
	cmp byte [.data_mode], 0
	je .normal_label
	
	mov si, .data_label
	call os_print_string
	
	jmp .finish_label
	
.normal_label:
	mov si, .input_label
	call os_print_string
	
.finish_label:
	mov ax, 0920h				; Clear the screen for the next input
	clr bh
	mov bl, [CONFIG_DESKTOP_BG_COLOR]
	mov cx, 30
	int 10h
	
	; Display the prompt

	mov al, 30
	call os_set_max_input_length

	mov16 dx, 2, 2
	call os_move_cursor
	call os_show_cursor		; Get a command from the user
	mov ax, .input_buffer
	mov si, .callback
	clr ch
	call os_input_string_ex
	
	mov si, .input_buffer	; Decode the command
	call os_string_uppercase

	ret


.callback:
	clr bx
	
	cmp ah, 48h				; Up arrow
	je .cbup

	cmp ah, 50h				; Down arrow
	je .cbdown

	cmp ah, 4Bh				; Left arrow
	je .cbleft

	cmp ah, 4Dh				; Right arrow
	je .cbright

	cmp ah, 49h				; Page Up
	je .cbpgup

	cmp ah, 51h				; Page Down
	je .cbpgdown

	cmp ah, 3Fh				; Refresh
	je .cbrefresh

.cbfinish:
	test bx, bx
	jz .cbexit

	add [.offset], bx

.cbrefresh:
	call os_get_cursor_pos
	push dx
	call .draw
	pop dx
	call os_move_cursor

.cbexit:
	retf

.cbup:
	mov bx, -16
	jmp .cbfinish

.cbdown:
	mov bx, 16
	jmp .cbfinish

.cbleft:
	mov bx, -1
	jmp .cbfinish

.cbright:
	mov bx, 1
	jmp .cbfinish

.cbpgup:
	mov bx, -256
	jmp .cbfinish

.cbpgdown:
	mov bx, 256
	jmp .cbfinish


.asciidraw:
	pusha
	
	mov16 dx, 60, 6
	call os_move_cursor

	push es
	mov si, [.offset]
	sub si, 40h
	mov es, [.segment]
	
	and si, 0FFF0h			; Mask off the lowest 4 bits
	
.asciiloop:
	mov cx, 1
	call .adjust_sel_fmt

	mov al, [es:si]
	inc si

	cmp al, 32
	jge .asciichar
	mov al, '.'
	
.asciichar:
	call os_putchar
	
	call os_get_cursor_pos
	cmp dl, 76
	jl .asciiloop
	
	mov dl, 60
	inc dh	
	call os_move_cursor

	cmp dh, 22
	jl .asciiloop
	
	pop es
	
	popa
	ret

.datadraw:
	pusha

	mov16 dx, 11, 6
	call os_move_cursor
	
	push es
	
	mov si, [.offset]
	sub si, 40h
	mov es, [.segment]
	
	and si, 0FFF0h			; Mask off the lowest 4 bits

.dataloop:
	mov cx, 2
	call .adjust_sel_fmt

	mov al, [es:si]
	inc si
	
	call os_print_2hex
		
	call os_print_space
		
	call os_get_cursor_pos
	cmp dl, 59
	jl .dataloop
	
	mov dl, 11
	inc dh	
	call os_move_cursor

	cmp dh, 22
	jl .dataloop
	
	pop es
	
	popa
	ret

.adjust_sel_fmt:
	pusha
	mov bl, [CONFIG_DESKTOP_BG_COLOR]

	cmp si, [.offset]
	jne .no_adjust_sel_fmt

	ror bl, 4

.no_adjust_sel_fmt:
	mov ax, 0920h
	clr bh
	int 10h
	popa
	ret

.exit:
	call os_clear_screen
	ret

.draw_background:
	mov ax, .title_msg
	mov bx, .footer_msg
	mov cx, [CONFIG_DESKTOP_BG_COLOR]
	call os_draw_background
	ret

.bardraw:
	mov16 dx, 0, 6
	call os_move_cursor
	
	mov ax, [.offset]
	and ax, 0FFF0h
	sub ax, 40h

	mov bx, [.segment]
	
	clr cl

	mov si, .semicolon

.barloop:
	call os_print_space
	
	xchg ax, bx
	call os_print_4hex
	call os_print_string
	xchg ax, bx
	call os_print_4hex

	call os_print_newline
	
	add ax, 16
	
	inc cl
	cmp cl, 16
	jne .barloop
	
	ret
	
.error:
	mov ax, .error_msg
	clr bx
	clr cx
	clr dx
	call os_dialog_box
	jmp start
	
; DAAAAAAATAAAAAAA!
	
	.title_msg			db 'MichalOS Memory Editor', 0
	.footer_msg			db '[h], [Enter] Command list [F5] Refresh [', 18h, ',', 19h, ',', 1Ah, ',', 1Bh, ',PgUp,PgDn] Move selection', 0
	
	.input_label		db ' >', 0
	.data_label			db 'D>', 0
	
	.data_mode			db 0
	.offset				dw 0
	.segment			dw 0

	.semicolon			db ':', 0
	
	.help_title0		db 'Command list:', 0
	.help_title1		db 0
	.help_msg0			db 'q = Quit,'
	.help_msg1			db 'sd/shXXXX = Set the 16-bit segment (dec/hex),'
	.help_msg2			db 'od/ohXXXX = Set the 16-bit offset (dec/hex),'
	.help_msg3			db 'dd/dh = Enter the data write mode (dec/hex),'
	.help_msg4			db 'wd/whXXXX ABC.XYZ = Write a file (XXXX bytes; filename ABC.XYZ),'
	.help_msg5			db 'lABC.XYZ = Load a file (filename ABC.XYZ)', 0
	.error_msg			db 'File access error!', 0
	
	.input_buffer		db 0		; Has to be on the end!
; ------------------------------------------------------------------

