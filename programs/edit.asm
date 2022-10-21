; ------------------------------------------------------------------
; MichalOS Text Editor
; ------------------------------------------------------------------

	%INCLUDE "michalos.inc"

start:
	call setup_screen

	cmp byte [0E0h], 0				; Were we passed a filename?
	je .no_param_passed
	
	mov ax, 0E0h

	call os_string_uppercase
	
	mov si, ax
	mov di, userfile
	call os_string_copy

	jmp file_chosen
	
.error:
	mov ax, file_load_fail_msg		; If fail, show message and exit
	clr bx
	clr cx
	clr dx
	call os_dialog_box

	call os_clear_screen
	ret					; Back to the OS

.no_param_passed:
	mov si, untitled
	mov di, userfile
	call os_string_copy
	clr bx
	jmp file_load_success
	
file_chosen:
	mov si, ax				; Save it for later usage
	mov di, filename
	call os_string_copy

	; Now we need to make sure that the file extension is TXT or BAS...

	mov di, ax
	call os_string_length
	add di, ax

	dec di					; Make DI point to last char in filename
	dec di
	dec di

	mov si, txt_extension			; Check for .TXT extension
	mov cx, 3
	rep cmpsb
	je valid_extension

	dec di

	mov si, bas_extension			; Check for .BAS extension
	mov cx, 3
	rep cmpsb
	je valid_extension

	mov byte [0085h], 1
	mov dx, 1
	mov ax, wrong_ext_msg
	mov bx, wrong_ext_msg2
	clr cx
	call os_dialog_box
	mov byte [0085h], 0

	test ax, ax
	jz valid_extension
	
	mov byte [0E0h], 0
	
	clr si
	jmp start



valid_extension:
	mov ax, filename
	mov cx, 4096				; Load the file 4K after the program start point
	call os_load_file

	jc start.error
	
file_load_success:
	mov word [filesize], bx


	; Now BX contains the number of bytes in the file, so let's add
	; the load offset to get the last byte of the file in RAM

	add bx, 4096

	cmp bx, 4096
	jne .not_empty
	mov byte [bx], 10			; If the file is empty, insert a newline char to start with

	inc bx
	inc word [filesize]

.not_empty:
	mov word [last_byte], bx		; Store position of final data byte


	clr cx			; Lines to skip when rendering (scroll marker)
	mov word [skiplines], 0

	mov byte [cursor_x], 0			; Initial cursor position will be start of text
	mov byte [cursor_y], 2			; The file starts being displayed on line 2 of the screen


	; Now we need to display the text on the screen; the following loop is called
	; whenever the screen scrolls, but not just when the cursor is moved

render_text:
	call update_screen

	mov16 dx, 0, 1
	call os_move_cursor
	
	mov ah, 09h
	mov al, ' '
	mov16 bx, 240, 0
	mov cx, 1840
	int 10h	
	
	mov16 dx, 0, 2				; Move cursor to near top
	call os_move_cursor


	mov si, 4096				; Point to start of text data
	mov ah, 0Eh				; BIOS char printing routine


	mov word cx, [skiplines]		; We're now going to skip lines depending on scroll level

redraw:
	test cx, cx				; Do we have any lines to skip?
	jz display_loop				; If not, start the displaying
	dec cx					; Otherwise work through the lines

.skip_loop:
	lodsb					; Read bytes until newline, to skip a line
	cmp al, 10
	jne .skip_loop				; Move on to next line
	jmp redraw


display_loop:					; Now we're ready to display the text
	lodsb					; Get character from file data

	cmp al, 10				; Go to start of line if it's a carriage return character
	jne skip_return

	call os_get_cursor_pos
	clr dl			; Set DL = 0 (column = 0)
	call os_move_cursor

skip_return:
	call os_get_cursor_pos			; Don't wrap lines on screen
	cmp dl, 79
	je .no_print

	int 10h					; Print the character via the BIOS

.no_print:
	mov word bx, [last_byte]
	cmp si, bx				; Have we printed all characters in the file?
	je get_input

	call os_get_cursor_pos			; Are we at the bottom of the display area?
	cmp dh, 23
	je get_input				; Wait for keypress if so

	jmp display_loop			; If not, keep rendering the characters



	; When we get here, now we've displayed the text on the screen, and it's time
	; to put the cursor at the position set by the user (not where it has been
	; positioned after the text rendering), and get input

get_input:
;	call showbytepos			; USE FOR DEBUGGING (SHOWS CURSOR INFO AT TOP-RIGHT)

	mov byte dl, [cursor_x]			; Move cursor to user-set position
	mov byte dh, [cursor_y]
	call os_move_cursor

	call os_wait_for_key			; Get input

	cmp ah, KEY_UP				; Cursor key pressed?
	je go_up
	cmp ah, KEY_DOWN
	je go_down
	cmp ah, KEY_LEFT
	je go_left
	cmp ah, KEY_RIGHT
	je go_right

	cmp ah, 71					; Home key
	je go_home
	cmp ah, 79
	je go_end
	
	cmp al, KEY_ESC				; Quit if Esc pressed
	je close

	jmp text_entry				; Otherwise it was probably a text entry char


; ------------------------------------------------------------------
; Move cursor left on the screen, and backward in data bytes

go_home:
	cmp byte [cursor_x], 0			; Are we at the start of a line?
	je .cant_move_left
	dec byte [cursor_x]			; If not, move cursor and data position
	dec word [cursor_byte]
	jmp go_home
	
.cant_move_left:
	jmp get_input
	
	
; ------------------------------------------------------------------
; Move cursor left on the screen, and backward in data bytes

go_left:
	cmp byte [cursor_x], 0			; Are we at the start of a line?
	je .cant_move_left
	dec byte [cursor_x]			; If not, move cursor and data position
	dec word [cursor_byte]

.cant_move_left:
	jmp get_input


; ------------------------------------------------------------------
; Move cursor right on the screen, and forward in data bytes

go_right:
	pusha

	cmp byte [cursor_x], 79			; Far right of display?
	je .nothing_to_do			; Don't do anything if so

	mov word ax, [cursor_byte]
	mov si, 4096
	add si, ax				; Now SI points to the char under the cursor

	inc si

	cmp word si, [last_byte]		; Can't move right if we're at the last byte of data
	je .nothing_to_do

	dec si

	cmp byte [si], 0Ah			; Can't move right if we are on a newline character
	je .nothing_to_do

	inc word [cursor_byte]			; Move data byte position and cursor location forwards
	inc byte [cursor_x]

.nothing_to_do:
	popa
	jmp get_input

	
; ------------------------------------------------------------------
; Move cursor right on the screen, and forward in data bytes

go_end:
	pusha
.loop:
	cmp byte [cursor_x], 79			; Far right of display?
	je .nothing_to_do			; Don't do anything if so

	mov word ax, [cursor_byte]
	mov si, 4096
	add si, ax				; Now SI points to the char under the cursor

	inc si

	cmp word si, [last_byte]		; Can't move right if we're at the last byte of data
	je .nothing_to_do

	dec si

	cmp byte [si], 0Ah			; Can't move right if we are on a newline character
	je .nothing_to_do

	inc word [cursor_byte]			; Move data byte position and cursor location forwards
	inc byte [cursor_x]

	jmp .loop
	
.nothing_to_do:
	popa
	jmp get_input


; ------------------------------------------------------------------
; Move cursor down on the screen, and forward in data bytes

go_down:
	; First up, let's work out which character in the RAM file data
	; the cursor will point to when we try to move down

	pusha

	mov word cx, [cursor_byte]
	mov si, 4096
	add si, cx				; Now SI points to the char under the cursor

.loop:
	inc si
	cmp word si, [last_byte]		; Is it pointing to the last byte in the data?
	je .do_nothing				; Quit out if so

	dec si

	lodsb					; Otherwise grab a character from the data
	inc cx					; Move our position along
	cmp al, 0Ah				; Look for newline char
	jne .loop				; Keep trying until we find a newline char

	mov word [cursor_byte], cx
	
.nowhere_to_go:
	popa

	cmp byte [cursor_y], 22			; If down pressed and cursor at bottom, scroll view down
	je .scroll_file_down
	inc byte [cursor_y]			; If down pressed elsewhere, just move the cursor
	mov byte [cursor_x], 0			; And go to first column in next line
	jmp render_text

.scroll_file_down:
	inc word [skiplines]			; Increment the lines we need to skip
	mov byte [cursor_x], 0			; And go to first column in next line
	jmp render_text				; Redraw the whole lot


.do_nothing:
	popa

	jmp render_text


; ------------------------------------------------------------------
; Move cursor up on the screen, and backward in data bytes

go_up:
	pusha

	mov word cx, [cursor_byte]
	mov si, 4096
	add si, cx				; Now SI points to the char under the cursor

	cmp si, 4096				; Do nothing if we're already at the start of the file
	je .start_of_file

	mov byte al, [si]			; Is the cursor already on a newline character?
	cmp al, 0Ah
	je .starting_on_newline

	jmp .full_monty				; If not, go back two newline chars


.starting_on_newline:
	cmp si, 4097
	je .start_of_file

	cmp byte [si-1], 0Ah			; Is the char before this one a newline char?
	je .another_newline_before
	dec si
	dec cx
	jmp .full_monty


.another_newline_before:			; And the one before that a newline char?
	cmp byte [si-2], 0Ah
	jne .go_to_start_of_line

	; If so, it means that the user pressed up on a newline char with another newline
	; char above, so we just want to move back to that one, and do nothing else

	dec word [cursor_byte]
	jmp .display_move



.go_to_start_of_line:
	dec si
	dec cx
	cmp si, 4096
	je .start_of_file
	dec si
	dec cx
	cmp si, 4096				; Do nothing if we're already at the start of the file
	je .start_of_file
	jmp .loop2



.full_monty:
	cmp si, 4096
	je .start_of_file

	mov byte al, [si]
	cmp al, 0Ah				; Look for newline char
	je .found_newline
	dec cx
	dec si
	jmp .full_monty


.found_newline:
	dec si
	dec cx

.loop2:
	cmp si, 4096
	je .start_of_file

	mov byte al, [si]
	cmp al, 0Ah				; Look for newline char
	je .found_done
	dec cx
	dec si
	jmp .loop2


.found_done:
	inc cx
	mov word [cursor_byte], cx
	jmp .display_move


.start_of_file:
	mov word [cursor_byte], 0
	mov byte [cursor_x], 0


.display_move:
	popa
	cmp byte [cursor_y], 2			; If up pressed and cursor at top, scroll view up
	je .scroll_file_up
	dec byte [cursor_y]			; If up pressed elsewhere, just move the cursor
	mov byte [cursor_x], 0			; And go to first column in previous line
	jmp get_input

.scroll_file_up:
	cmp word [skiplines], 0			; Don't scroll view up if we're at the top
	jle get_input
	dec word [skiplines]			; Otherwise decrement the lines we need to skip
	jmp render_text


; ------------------------------------------------------------------
; When an key (other than cursor keys or Esc) is pressed...

text_entry:
	pusha

	cmp ah, 3Bh				; F1 pressed?
	je .f1_pressed

	cmp ah, 3Ch				; F2 pressed?
	je .f2_pressed

	cmp ah, 3Fh				; F5 pressed?
	je .f5_pressed

	cmp ah, 53h				; Delete?
	je .delete_pressed

	cmp al, 8
	je .backspace_pressed

	cmp al, 13
	je .enter_pressed

	cmp al, 14				; Ctrl+N
	je new_file
	
	cmp al, 15				; Ctrl+O
	je load_file
	
	cmp al, 19				; Ctrl+S
	je save_file
	
	cmp ax, 1F00h			; Alt+S
	je save_new_file
	
	cmp al, 17				; Ctrl+Q
	je close_file
	
	cmp al, 20h
	jl .nothing_to_do
	
	call os_get_cursor_pos
	cmp dl, 77
	jng .end_of_line
	
	push ax

	call move_all_chars_forward

	mov word cx, [cursor_byte]
	mov si, 4096
	add si, cx				; Now SI points to the char under the cursor

	pop ax

	mov byte [si], al
	inc word [cursor_byte]
	inc byte [cursor_x]

	jmp .enter_pressed
	
.end_of_line:	
	push ax

	call move_all_chars_forward

	mov word cx, [cursor_byte]
	mov si, 4096
	add si, cx				; Now SI points to the char under the cursor

	pop ax

	mov byte [si], al
	inc word [cursor_byte]
	inc byte [cursor_x]

.nothing_to_do:
	popa
	jmp render_text

.f1_pressed:
	mov ax, chooselist
	mov bx, 14
	call os_option_menu
	
	jc .nothing_to_do
	
	cmp ax, 1
	je new_file
	
	cmp ax, 2
	je load_file
	
	cmp ax, 3
	je save_file
	
	cmp ax, 4
	je save_new_file
	
	jmp close_file

.delete_pressed:
	mov si, 4097
	add si, word [cursor_byte]

	cmp si, word [last_byte]
	je .end_of_file

	cmp byte [si], 00h
	jl .not_at_final_char_in_line

	cmp byte [si], 0Ah
	jl .at_final_char_in_line
	
.not_at_final_char_in_line:
	call move_all_chars_backward
	popa
	jmp render_text

.at_final_char_in_line:
	call move_all_chars_backward		; Char and newline character too
	call move_all_chars_backward		; Char and newline character too
	popa
	jmp render_text



.backspace_pressed:
	cmp word [cursor_byte], 0
	je .nothing_to_do

	cmp byte [cursor_x], 0
	je .nothing_to_do

	dec word [cursor_byte]
	dec byte [cursor_x]

	mov si, 4096
	add si, word [cursor_byte]

	cmp si, word [last_byte]
	je .end_of_file
	
	cmp byte [si], 00h
	jl .not_at_final_char_in_line2

	cmp byte [si], 0Ah					; Thanks, little endian!
	jl .at_final_char_in_line2
	
.not_at_final_char_in_line2:
	call move_all_chars_backward
	popa
	jmp render_text

.at_final_char_in_line2:
	call move_all_chars_backward		; Char and newline character too
	call move_all_chars_backward		; Char and newline character too
	popa
	jmp render_text

.end_of_file:
	popa
	jmp render_text

.enter_pressed:
	call move_all_chars_forward

	mov word cx, [cursor_byte]
	mov di, 4096
	add di, cx				; Now SI points to the char under the cursor

	mov byte [di], 0Ah			; Add newline char

	popa
	jmp go_down

.f2_pressed:				; Cut line
	cmp byte [cursor_x], 0
	je .done_going_left
	dec byte [cursor_x]
	dec word [cursor_byte]
	jmp .f2_pressed

.done_going_left:
	mov si, 4096
	add si, word [cursor_byte]
	inc si
	cmp si, word [last_byte]
	je .do_nothing_here

	dec si
	cmp byte [si], 10
	je .final_char

	call move_all_chars_backward
	jmp .done_going_left

.final_char:
	call move_all_chars_backward

.do_nothing_here:
	popa
	jmp render_text

.f5_pressed:				; Run BASIC
	mov word ax, [filesize]
	cmp ax, 4
	jl .not_big_enough

	call os_clear_screen

	mov ax, 4096
	clr si
	mov word bx, [filesize]

	call os_run_basic

	call os_print_newline
	mov si, .basic_finished_msg
	call os_print_string
	call os_wait_for_key
	call os_show_cursor
	
	mov byte [0082h], 0
	
	call setup_screen
	
	popa
	jmp render_text

.not_big_enough:
	mov ax, .fail1_msg
	clr bx
	clr cx
	clr dx
	call os_dialog_box

	popa
	jmp render_text

	.basic_finished_msg		db 'BASIC program ended', 0
	.fail1_msg				db 'At least an END command is required to run BASIC.', 0


; ------------------------------------------------------------------
; Move data from current cursor one character ahead

move_all_chars_forward:
	pusha

	mov si, 4096
	add si, word [filesize]			; SI = final byte in file

	mov di, 4096
	add di, word [cursor_byte]

.loop:
	mov byte al, [si]
	mov byte [si+1], al
	dec si
	cmp si, di
	jl .finished
	jmp .loop

.finished:
	inc word [filesize]
	inc word [last_byte]

	popa
	ret


; ------------------------------------------------------------------
; Move data from current cursor + 1 to end of file back one char

move_all_chars_backward:
	pusha

	mov si, 4096
	add si, word [cursor_byte]

.loop:
	mov byte al, [si+1]
	mov byte [si], al
	inc si
	cmp word si, [last_byte]
	jne .loop

.finished:
	dec word [filesize]
	dec word [last_byte]

	popa
	ret

; ------------------------------------------------------------------
; LOAD FILE

load_file:
	popa
	mov byte [0087h], 1
	mov bx, extension_filter
	call os_file_selector		; Get filename
	mov byte [0087h], 0
	jc render_text

	mov si, ax				; Save it for later usage
	mov di, filename
	call os_string_copy

	mov si, ax
	mov di, userfile
	call os_string_copy

	; Now we need to make sure that the file extension is TXT or BAS...

	mov di, ax
	call os_string_length
	add di, ax

	dec di					; Make DI point to last char in filename
	dec di
	dec di

	mov si, txt_extension			; Check for .TXT extension
	mov cx, 3
	rep cmpsb
	je valid_extension

	dec di

	mov si, bas_extension			; Check for .BAS extension
	mov cx, 3
	rep cmpsb
	je valid_extension

	mov byte [0085h], 1
	mov dx, 1
	mov ax, wrong_ext_msg
	mov bx, wrong_ext_msg2
	clr cx
	call os_dialog_box
	mov byte [0085h], 0

	test ax, ax
	jz valid_extension
	
	jmp render_text
	
; ------------------------------------------------------------------
; SAVE FILE

save_file:
	mov si, userfile
	mov di, untitled
	call os_string_compare
	jc save_new_file
	
	mov ax, filename			; Delete the file if it already exists
	call os_remove_file
	jc .no_delete
	
	mov ax, filename
	mov word cx, [filesize]
	mov bx, 4096
	call os_write_file

	jc .failure				; If we couldn't save file...

	mov ax, file_save_succeed_msg
	clr bx
	clr cx
	clr dx
	call os_dialog_box

	popa
	jmp render_text

.no_delete:
	mov ax, .delete_failed
	mov bx, file_save_fail_msg2
	clr cx
	clr dx
	call os_dialog_box

	popa
	jmp render_text
	
.failure:
	mov ax, file_save_fail_msg1
	mov bx, file_save_fail_msg2
	clr cx
	clr dx
	call os_dialog_box

	popa
	jmp render_text

	.delete_failed			db 'Error deleting the previous file.', 0
	
; ------------------------------------------------------------------
; SAVE AS A NEW FILE

save_new_file:
	mov ax, newname
	mov bx, new_file_msg
	call os_input_dialog
	mov ax, newname
	call os_string_uppercase
	
	mov ax, newname
	mov word cx, [filesize]
	mov bx, 4096
	call os_write_file

	jc .failure				; If we couldn't save file...

	mov si, newname
	mov di, userfile

	call os_string_copy
	mov ax, file_save_succeed_msg
	clr bx
	clr cx
	clr dx
	call os_dialog_box

	popa
	jmp render_text


.failure:
	clr ax
	clr bx
	clr cx
	clr dx

	cmp byte [0086h], 0
	je .failure0
	cmp byte [0086h], 1
	je .failure1
	cmp byte [0086h], 2
	je .failure2
	cmp byte [0086h], 3
	je .failure3
	cmp byte [0086h], 4
	je .failure4
	
	mov ax, file_save_fail_msg1
	mov bx, file_save_fail_msg2
	call os_dialog_box

	popa
	jmp render_text

.failure0:
	mov ax, failure0msg
	call os_dialog_box
	popa
	jmp render_text
	
.failure1:
	mov ax, failure1msg
	call os_dialog_box
	popa
	jmp render_text
	
.failure2:
	mov ax, failure2msg
	call os_dialog_box
	popa
	jmp render_text
	
.failure3:
	mov ax, failure3msg
	call os_dialog_box
	popa
	jmp render_text
	
.failure4:
	mov ax, failure4msg
	call os_dialog_box
	popa
	jmp render_text
	
	
	
; ------------------------------------------------------------------
; NEW FILE

new_file:
	mov ax, confirm_msg
	mov bx, confirm_msg1
	clr cx
	mov dx, 1
	call os_dialog_box
	cmp ax, 1
	je .do_nothing

	mov di, 4096			; Clear the entire text buffer
	clr al
	mov cx, 28672
	rep stosb

	mov word [filesize], 1

	mov bx, 4096			; Store just a single newline char
	mov byte [bx], 10
	inc bx
	mov word [last_byte], bx

	clr cx		; Reset other values
	mov word [skiplines], 0

	mov byte [cursor_x], 0
	mov byte [cursor_y], 2

	mov word [cursor_byte], 0


.retry_filename:
	mov ax, filename
	mov bx, new_file_msg
	call os_input_dialog
	call os_string_uppercase
	mov si, filename
	mov di, userfile
	call os_string_copy

	mov ax, filename			; Delete the file if it already exists
	call os_remove_file

	mov ax, filename
	mov word cx, [filesize]
	mov bx, 4096
	call os_write_file
	jc .failure				; If we couldn't save file...

.do_nothing:
	popa
	jmp render_text


.failure:
	mov ax, file_save_fail_msg1
	mov bx, file_save_fail_msg2
	clr cx
	clr dx
	call os_dialog_box

	jmp .retry_filename


; ------------------------------------------------------------------
; Quit

close_file:
	popa

close:
	mov word [gs:4094], 0
	call os_clear_screen
	ret

; ------------------------------------------------------------------
; Setup screen with colours, titles and horizontal lines

setup_screen:
	pusha

	mov ax, txt_title_msg			; Set up the screen with info at top and bottom
	mov bx, txt_footer_msg
	mov cx, BLACK_ON_WHITE
	call os_draw_background

	mov16 dx, 24, 0
	call os_move_cursor
	mov si, userfile
	call os_print_string
	
	popa
	ret

update_screen:
	pusha

	mov bl, BLACK_ON_WHITE
	mov dx, 0200h
	mov si, 80
	mov di, 23
	call os_draw_block
	
	mov16 dx, 24, 0
	call os_move_cursor
	mov si, userfile
	call os_print_string
	
	mov si, userfile
	mov di, untitled
	call os_string_compare
	
	jc .exit
	
	mov ax, userfile
	call os_string_length
	
	mov16 dx, 24, 0
	add dl, al
	call os_move_cursor
	
	mov ax, 0920h
	mov16 bx, 70h, 00h
	mov cx, 18h
	int 10h
	
.exit:
	popa
	ret
	
; ------------------------------------------------------------------
; DEBUGGING -- SHOW POSITION OF BYTE IN FILE AND CHAR UNDERNEATH CURSOR
; ENABLE THIS IN THE get_input SECTION ABOVE IF YOU NEED IT

showbytepos:
	pusha

	mov word ax, [cursor_byte]
	call os_int_to_string
	mov si, ax

	mov16 dl, 60, 0
	call os_move_cursor

	call os_print_string
	call os_print_space

	mov si, 4096
	add si, word [cursor_byte]
	lodsb

	call os_print_2hex
	call os_print_space

	mov ah, 0Eh
	int 10h

	call os_print_space

	popa
	ret


; ------------------------------------------------------------------
; Data section

	txt_title_msg			db 'MichalOS Text Editor - ', 0
	txt_footer_msg			db '[F1] File [F2] Delete a line [F5] Run BASIC', 0

	txt_extension			db 'TXT', 0
	bas_extension			db 'BAS', 0
	wrong_ext_msg			db 'Invalid file type (TXT/BAS only)!', 0
	wrong_ext_msg2			db 'Are you sure you want to continue?', 0
	
	confirm_msg				db 'Are you sure? All unsaved changes will', 0
	confirm_msg1			db 'be lost!', 0
	
	file_load_fail_msg		db 'Error loading the file!', 0
	new_file_msg			db 'Choose a new filename (DOCUMENT.TXT):', 0
	file_save_fail_msg1		db 'Error saving the file!', 0
	file_save_fail_msg2		db '(Invalid filename/disk is read-only?)', 0
	file_save_succeed_msg	db 'File saved.', 0

	failure0msg				db 'Filename is too long!', 0
	failure1msg				db 'Filename is empty!', 0
	failure2msg				db 'Filename has no extension!', 0
	failure3msg				db 'Filename has no basename!', 0
	failure4msg				db 'Extension is too short!', 0
	
	chooselist				db 'New,Open...,Save,Save as...,Exit', 0
	
	untitled				db 'Unnamed document', 0
	userfile				times 60 db 0
	newname					times 60 db 0
	
	extension_filter	db 2
	.mmf_extension		db 'TXT', 0
	.dro_extension		db 'BAS', 0
	
	skiplines				dw 0

	cursor_x				db 0			; User-set cursor position
	cursor_y				db 0

	cursor_byte				dw 0			; Byte in file data where cursor is

	last_byte				dw 0			; Location in RAM of final byte in file

	filename				times 60 db 0		; 12 would do, but the user
												; might enter something daft
	filesize				dw 0

; ------------------------------------------------------------------

