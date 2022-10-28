; ==================================================================
; MichalOS Text display output functions
; ==================================================================

; ------------------------------------------------------------------
; os_putchar -- Puts a character on the screen
; IN: AL = character
; OUT: None, registers preserved

os_putchar:
	pusha

.no_pusha:
	mov ah, 0Eh
	mov bx, 15
	int 10h
	popa
	ret

; ------------------------------------------------------------------
; os_put_chars -- Puts up to a set amount of characters on the screen
; IN: BL = terminator, SI = location, CX = character count
; OUT: None, registers preserved

os_put_chars:
	pusha
	
.no_pusha:
.loop:
	lodsb
	cmp al, bl
	je int_popa_ret
	
	call os_putchar
	
	loop .loop
	popa
	ret

; ------------------------------------------------------------------
; os_print_string -- Displays text
; IN: SI = message location (zero-terminated string)
; OUT: None, registers preserved

os_print_string:
	pusha

	clr bl
	clr cx

	jmp os_put_chars.no_pusha

; ------------------------------------------------------------------
; os_print_string_box -- Displays text inside a text-box.
; IN: SI = message location (zero-terminated string), DL = left alignment
; OUT: None, registers preserved

os_print_string_box:
	pusha
	mov cl, dl

.repeat:
	lodsb				; Get char from string
	test al, al
	jz int_popa_ret		; If char is zero, end of string

	cmp al, 13
	je .cr
	
	call os_putchar
	jmp .repeat			; And move on to next char

.cr:
	call os_get_cursor_pos
	mov dl, cl
	call os_move_cursor
	jmp .repeat

; ------------------------------------------------------------------
; os_format_string -- Displays colored text
; IN: BL/SI = text color/message location (zero-terminated string)
; OUT: None, registers preserved

os_format_string:
	pusha

	mov ah, 09h			; int 09h
	clr bh
	mov cx, 1
	call os_get_cursor_pos
	
.repeat:
	lodsb				; Get char from string
	cmp al, 13
	je .cr
	cmp al, 10
	je .lf
	test al, al
	jz int_popa_ret		; If char is zero, end of string

	int 10h				; Otherwise, print it

	inc dl
	call os_move_cursor
	
	jmp .repeat			; And move on to next char
	
.cr:
	clr dl
	call os_move_cursor
	jmp .repeat

.lf:
	inc dh
	call os_move_cursor
	jmp .repeat
	

; ------------------------------------------------------------------
; os_clear_screen -- Clears the screen to background
; IN/OUT: None, registers preserved

os_clear_screen:
	pusha

	clr dx				; Position cursor at top-left
	call os_move_cursor

	mov16 ax, 0, 6		; Scroll full-screen
	mov bh, 7
	mov16 cx, 0, 0		; Top-left
	mov16 dx, 79, 24	; Bottom-right
	int 10h

	mov byte [0082h], 1	; Assume that an application clearing 
						; the screen doesn't want to refresh time		
	popa
	ret


; ------------------------------------------------------------------
; os_move_cursor -- Moves cursor in text mode
; IN: DH, DL = row, column
; OUT: None, registers preserved

os_move_cursor:
	pusha

.no_pusha:
	clr bh
	mov ah, 2
	int 10h				; BIOS interrupt to move cursor

	popa
	ret


; ------------------------------------------------------------------
; os_get_cursor_pos -- Return position of text cursor
; IN: None
; OUT: DH, DL = row, column

os_get_cursor_pos:
	pusha

	clr bh
	mov ah, 3
	int 10h				; BIOS interrupt to get cursor position

	mov bx, sp
	mov [ss:bx + 10], dx
	popa
	ret


; ------------------------------------------------------------------
; os_show_cursor -- Turns on cursor in text mode
; IN/OUT: None, registers preserved

os_show_cursor:
	pusha

.no_pusha:
	mov16 cx, 7, 6
	mov16 ax, 3, 1
	int 10h

	popa
	ret


; ------------------------------------------------------------------
; os_hide_cursor -- Turns off cursor in text mode
; IN/OUT: None, registers preserved

os_hide_cursor:
	pusha

	mov ch, 32
	mov16 ax, 3, 1	; AL must be video mode for buggy BIOSes!
	int 10h

	popa
	ret


; ------------------------------------------------------------------
; os_draw_block -- Render block of specified colour
; IN: BL/DL/DH/SI/DI = colour/start X pos/start Y pos/width/finish Y pos
; OUT: None, registers preserved

os_draw_block:
	pusha

.more:
	call os_move_cursor		; Move to block starting position

	mov16 ax, ' ', 09h			; Draw colour section
	clr bh
	mov cx, si
	int 10h

	inc dh				; Get ready for next line

	movzx ax, dh		; Get current Y position into DL
	cmp ax, di			; Reached finishing point (DI)?
	jne .more			; If not, keep drawing

	popa
	ret


; ------------------------------------------------------------------
; os_file_selector -- Show a file selection dialog
; IN: None
; OUT: AX = location of filename string (or carry set if Esc pressed)

os_file_selector:
	pusha
	clr bx
	jmp os_file_selector_filtered.no_pusha

; ------------------------------------------------------------------
; os_file_selector_filtered -- Show a file selection dialog only 
; with files mathing the filter
; IN: BX = location of file extension list (0 if none)
; OUT: AX = location of filename string (or carry set if Esc pressed)

os_file_selector_filtered:
	pusha

.no_pusha:
	; Get volume name

	pusha
	mov cx, 1					; Load first disk sector into RAM
	movzx dx, byte [0084h]
	mov bx, disk_buffer

	mov16 ax, 1, 2
	stc
	int 13h						; BIOS load sector call

	mov si, disk_buffer + 2Bh	; Disk label starts here

	mov di, .volname
	mov cx, 11					; Copy 11 chars of it
	rep movsb
	popa
	
	mov word [.filename], 0		; Terminate string in case user leaves without choosing

	call os_report_free_space
	shr ax, 1					; Sectors -> kB
	mov [.freespace], ax
	
	; Remember the filter list for later

	mov [.extension_list], bx

	; Create the filename index list

	call int_read_root_dir		; Get the files into the buffer

	mov si, disk_buffer			; Raw directory buffer
	mov di, 64512				; Buffer for indexes
	clr cx						; Number of found files

.index_loop:
	cmp si, 64512			; Are we done looping through the directory?
	je .done

	mov al, [si+11]			; File attributes for entry
	cmp al, 0Fh			; Windows marker, skip it
	je .skip

	test al, 08h			; Is this a directory entry or volume label?
	jnz .skip			; Yes, ignore it

	mov al, [si]
	cmp al, 229			; If we read 229 = deleted filename
	je .skip

	test al, al			; 1st byte = entry never used
	jz .done

	pusha

	mov bx, [.extension_list]

	test bx, bx			; Check if we are supposed to filter the filenames
	jz .no_extension_check

	movzx cx, byte [bx]	; Cycle through all filters

	mov di, bx
	sub di, 3			; 1 - 4 = -3 (skip header, prepare for addition)

	add si, 8			; Extension

.extension_loop:
	add di, 4

	pusha
	mov cx, 3
	rep cmpsb
	popa
	je .no_extension_check
	
	loop .extension_loop
	
	popa
	jmp .skip

.no_extension_check:
	popa

	inc cx				; Increment the number of discovered files
	mov ax, si			; Store the filename pointer into the buffer
	stosw

.skip:
	add si, 32		; Skip to the next file
	jmp .index_loop

.done:
	; Let the user select a file

	mov ax, cx			; Pass the number of files
	test cx, cx
	jz .empty_list
	mov bx, .root
	mov cx, .help_msg2
	mov dx, .history
	mov di, .callback
	mov si, .print_filename
	call os_cb_list_dialog_tooltip

	jc .esc_pressed

	call .get_filename
	
	popa
	mov ax, .filename
	clc
	ret

.empty_list:
	mov ax, .nofilesmsg
	clr bx
	clr cx
	clr dx
	call os_dialog_box

	popa
	stc
	ret

	.nofilesmsg		db "There are no files available.", 0

.esc_pressed:				; Set carry flag if Escape was pressed
	popa
	stc
	ret

.print_filename:
	mov ax, cx
	call .get_filename
	mov si, .filename
	call os_print_string
	ret

.get_ptr_from_index:
	dec ax				; Result from os_list_dialog starts from 1, but
						; for our file list offset we want to start from 0
	
	shl ax, 1
	add ax, 64512
	mov si, ax			; Get the pointer to the string in the index

	mov si, [si]		; Our resulting pointer
	ret

.get_filename:
	call .get_ptr_from_index
	clr cx
	mov di, .filename
	
.loopy:
	lodsb
	cmp al, ' '
	je .ignore_space
	stosb
	
.ignore_space:
	inc cx
	cmp cx, 8
	jne .no_add_dot

	mov al, '.'
	stosb

.no_add_dot:
	cmp cx, 11
	jne .loopy

	mov al, 0
	stosb
	ret

.callback:
	pusha

	; Display if there are any filters

	mov bx, [.extension_list]

	test bx, bx
	jz .no_filter

	mov16 dx, 3, 4
	call os_move_cursor
	
	mov si, .filter_msg
	call os_print_string

	mov si, bx
	movzx cx, byte [si]
	inc si
	
.filter_loop:
	push cx
	clr bl
	mov cx, 3
	call os_put_chars
	pop cx

	add si, 4

	call os_print_space

	loop .filter_loop
	
.no_filter:
	popa

	; Draw the box on the right
	mov bl, [57001]		; Color from RAM
	mov16 dx, 41, 2		; Start X/Y position
	mov si, 37			; Width
	mov di, 23			; Finish Y position
	call os_draw_block

	; Draw the icon's background
	mov bl, 0F0h
	mov16 dx, 50, 3
	mov si, 19			; Width
	mov di, 13			; Finish Y position
	call os_draw_block

	; Draw the icon
	
	mov16 dx, 52, 4
	call os_move_cursor
	
	mov si, filelogo
	call os_draw_icon

	; Display the filename

	mov16 dx, 42, 14
	call os_move_cursor

	push ax
	mov cx, ax
	call .print_filename
	pop ax
	
	; Find the correct directory entry for this file

	call .get_ptr_from_index

	push si
	
	; Display the file size
	
	mov eax, [si + 28]
	call os_32int_to_string
	push ax
	call os_string_length

	mov dl, 77 - 6
	sub dl, al
	call os_move_cursor

	pop si
	call os_print_string

	mov si, .byte_msg
	call os_print_string
	
	; Display the file write date/time
	
	mov16 dx, 42, 16
	call os_move_cursor

	mov si, .time_msg
	call os_print_string
	
	pop si
	mov bx, [si + 14]
	mov cx, [si + 16]
	
	push bx
	mov ax, cx		; Days
	and ax, 11111b
	
	mov dl, '/'
	call .cb_print_num
	
	mov ax, cx		; Months
	shr ax, 5
	and ax, 1111b
	
	call .cb_print_num
	
	mov ax, cx		; Years
	shr ax, 9
	add ax, 1980
	
	mov dl, ' '
	call .cb_print_num
	pop cx
	
	mov ax, cx		; Hours
	shr ax, 11

	mov dl, ':'
	call .cb_print_num
	
	mov ax, cx		; Minutes
	shr ax, 5
	and ax, 111111b
	
	call .cb_print_num

	mov ax, cx		; Seconds
	and ax, 11111b
	shl ax, 1

	mov dl, ' '
	call .cb_print_num
	
	; Display volume information
	
	mov16 dx, 42, 20
	call os_move_cursor

	mov ax, 09C4h
	movzx bx, byte [57001]
	mov cx, 35
	int 10h
	
	inc dh
	call os_move_cursor

	mov si, .vol_msg
	call os_print_string
	
	mov ax, [.freespace]
	call os_int_to_string
	mov si, ax
	call os_string_length
	
	add dl, 27
	sub dl, al
	call os_move_cursor
		
	call os_print_string
		
	mov si, .free_msg
	call os_print_string
	ret
	
.cb_print_num:
	cmp ax, 10
	jge .no_zero
	
	push ax
	mov al, '0'
	call os_putchar
	pop ax

.no_zero:
	call os_print_int

	mov al, dl
	call os_putchar
	ret
	
	.help_msg2		db 0
	.filter_msg		db 'Filters: ', 0
	.byte_msg		db ' bytes', 0
	.free_msg		db ' kB free', 0
	.root			db 'A:/', 0

	.time_msg		db 'Written to on:  ', 0
	.filename		times 13 db 0	; 8 + 1 + 3 + term
	
	.vol_msg		db 'Volume '
	.volname		times 12 db 0
	.freespace		dw 0
	.extension_list	dw 0

	.history		times 5 db 0

; ------------------------------------------------------------------
; os_list_dialog_tooltip -- Show a dialog with a list of options and a tooltip.
; That means, when the user changes the selection, the application will be called back
; to change the tooltip's contents.
; IN: AX = comma-separated list of strings to show (zero-terminated),
;     BX = first help string, CX = second help string
;     SI = key/display callback (see os_cb_list_dialog)
; OUT: AX = number (starts from 1) of entry selected; carry set if Esc pressed

os_list_dialog_tooltip:
	push di
	push si
	push dx

	mov di, si
	push cx
	call os_string_callback_tokenizer
	mov ax, cx
	pop cx

	clr dx
	call os_cb_list_dialog_tooltip

	pop dx
	pop si
	pop di
	ret

; ------------------------------------------------------------------
; os_cb_list_dialog_tooltip -- Show a dialog with a list of options and a tooltip.
; That means, when the user changes the selection, the application will be called back
; to change the tooltip's contents.
; IN: AX = number of entries,
;     BX = first help string, CX = second help string, DX = history data (ptr to 5 bytes)
;     DI = key/display callback, SI = entry callback (see os_cb_list_dialog)
; OUT: AX = number (starts from 1) of entry selected; carry set if Esc pressed

os_cb_list_dialog_tooltip:
	push di

	mov word [0089h], 37
	
	mov [.callbackaddr], di

	mov di, .callback
	call os_cb_list_dialog

	mov word [0089h], 76
	pop di
	ret
	
.callback:
	pusha
	; Draw the box on the right
	mov bl, [57001]		; Color from RAM
	mov16 dx, 41, 2		; Start X/Y position
	mov si, 37			; Width
	mov di, 23			; Finish Y position
	call os_draw_block	; Draw option selector window	

	mov16 dx, 42, 3
	call os_move_cursor
	popa

	jmp [.callbackaddr]
	
	.callbackaddr	dw 0
	
; ------------------------------------------------------------------
; os_list_dialog -- Show a dialog with a list of options
; IN: AX = comma-separated list of strings to show (zero-terminated),
;     BX = first help string, CX = second help string
; OUT: AX = number (starts from 1) of entry selected; carry set if Esc pressed

os_list_dialog:
	pusha
	push cx
	call os_string_callback_tokenizer
	mov ax, cx
	pop cx

	clr di
	jmp os_cb_list_dialog.no_pusha

; ------------------------------------------------------------------
; os_cb_list_dialog -- Show a dialog with a list of options
; IN: SI = entry callback (accepts CX as entry ID, prints out result),
;     DI = key/display callback (accepts AX as entry ID, CX as keypress) AX = number of entries,
;     BX = first help string, CX = second help string, DX = history data (ptr to 5 bytes)
; OUT: AX = number (starts from 1) of entry selected; carry set if Esc pressed

os_cb_list_dialog:
	pusha

.no_pusha:
	push dx
	mov [.displaycb], di
	mov [.parsercb], si
	mov [.num_of_entries], ax

	push cx				; And help strings
	push bx

	call os_hide_cursor

	; Draw the window

	mov bl, [57001]		; Color from RAM
	mov16 dx, 2, 2		; Start X/Y position
	mov si, [0089h]		; Width
	mov di, 23			; Finish Y position
	call os_draw_block	; Draw option selector window

	mov16 dx, 3, 3		; Show first line of help text...
	call os_move_cursor

	pop si				; Get back first string
	call os_print_string

	inc dh
	call os_move_cursor

	pop si				; ...and the second
	call os_print_string

	mov al, [0089h]
	sub al, 6
	mov ah, 15
	mov bl, 11110000b		; Black on white for option list box
	mov16 dx, 3, 5
	mov cx, [.num_of_entries]
	mov si, .callbackroutine
	pop di
	jmp os_select_list.no_pusha

.callbackroutine:
	jc .cbdisplay

	jmp word [.parsercb]

.cbdisplay:
	pusha
	xchg ax, cx
	call word [.displaycb]
	popa

	test ax, ax
	jnz .cbexit

	mov16 dx, 5, 22
	call os_move_cursor

	mov al, '('
	call os_putchar

	mov ax, cx
	call os_print_int
	
	mov al, '/'
	call os_putchar
	
	mov ax, [.num_of_entries]
	call os_print_int
	
	mov si, .str_pos_end
	call os_print_string
	
.cbexit:
	ret

	.num_of_entries	dw 0
	.parsercb		dw 0
	.displaycb		dw 0
	.str_pos_end	db ')  ', 0

; ------------------------------------------------------------------
; os_select_list -- Draws a list of entries (defined by a callback) to select from.
; IN: AX = width/height, BL = color, CX = number of entries, DX = X/Y pos,
;     SI = callback (if C clear = accepts an entry ID in CX, returns a string in SI,
;     if C set = accepts key input in AX, entry ID in CX; not required to preserve regs),
;     DI = pointer to a history struct (word .num_of_entries, word .skip_num, byte .cursor) or 0 if none
; OUT: AX = number (starts from 1) of entry selected; carry set if Esc pressed

os_select_list:
	pusha

.no_pusha:
	call os_hide_cursor

	; Initialize vars

	mov [.callback], si
	mov [.xpos], dx
	mov [.width], ax
	
	add dx, 101h	; Increment both X and Y

	add ah, dh
	mov [.endypos], ah

	mov word [.skip_num], 0

	; If history is enabled, check if it matches the data

	mov [.history], di

	test di, di
	jz .no_history

	cmp [di], cx
	jne .no_history

	mov ax, [di + 2]
	mov [.skip_num], ax

	mov dh, [di + 4]

.no_history:
	mov [.num_of_entries], cx

.redraw:
	; Draw the BG

	pusha
	mov dx, [.xpos]
	mov al, [.width]
	add al, 4
	movzx si, al
	mov al, [.endypos]
	inc al
	movzx di, al
	call os_draw_block
	popa

	; Draw the selected entry BG

	pusha
	ror bl, 4				; Invert the selection color
	mov al, [.width]
	add al, 2
	movzx si, al
	movzx di, dh
	inc di
	call os_draw_block
	popa

	; Draw the list

	pusha
	mov dh, [.ypos]
	inc dl
	movzx cx, [.height]
	mov ax, [.skip_num]

.entry_draw_loop:
	inc ax
	inc dh

	cmp ax, [.num_of_entries]
	jg .no_draw

	call os_move_cursor
	pusha
	clc
	call .call_callback
	popa

.no_draw:
	loop .entry_draw_loop
	popa

	; Draw arrows indicating that there may be entries outside the visible area

	pusha
	mov bx, [.skip_num]			; Are we at the top?
	test bx, bx
	je .no_draw_top_arrow

	mov dx, [.xpos]
	add dl, 2
	call os_move_cursor
	mov al, 1Eh
	call os_putchar

.no_draw_top_arrow:
	movzx cx, byte [.height]
	add bx, cx

	cmp bx, [.num_of_entries]	; Are we at the bottom?
	jge .no_draw_bottom_arrow

	mov dx, [.xpos]
	add dh, [.height]
	add dx, 102h
	call os_move_cursor
	mov al, 1Fh
	call os_putchar

.no_draw_bottom_arrow:
	popa

	pusha
	clr ax
	stc
	call .call_callback
	popa

.another_key:
	call os_wait_for_key	; Move / select option
	cmp al, 'j'
	je .go_down
	cmp al, 'k'
	je .go_up
	cmp al, 'l'
	je .option_selected
	cmp al, 'h'
	je .esc_pressed

	cmp ah, 48h				; Up pressed?
	je .go_up
	cmp ah, 50h				; Down pressed?
	je .go_down
	cmp ah, 47h				; Home pressed?
	je .home_pressed
	cmp ah, 4Fh				; End pressed?
	je .end_pressed
	cmp ah, 49h				; PgUp pressed?
	je .pgup_pressed
	cmp ah, 51h				; PgDn pressed?
	je .pgdn_pressed
	cmp al, 13				; Enter pressed?
	je .option_selected
	cmp al, 27				; Esc pressed?
	je .esc_pressed

	pusha
	stc
	call .call_callback
	popa

	jmp .another_key		; If not, wait for another key

.call_callback:
	; Calculate the current entry ID

	pushf
	movzx cx, dh
	sub cl, [.ypos]
	add cx, [.skip_num]
	popf

	call word [.callback]
	ret

.go_up:
	call .move_up
	jmp .redraw

.go_down:
	call .move_down
	jmp .redraw

.home_pressed:
	call .jump_up
	jmp .redraw

.end_pressed:
	call .jump_down
	jmp .redraw

.pgup_pressed:
	mov si, .move_up
	jmp .pgxx_start

.pgdn_pressed:
	mov si, .move_down

.pgxx_start:
	mov cx, 16

.pgxx_loop:
	push cx
	call si
	pop cx
	loop .pgxx_loop

	jmp .redraw

.move_up:
	dec dh					; Move the cursor up
	cmp dh, [.ypos]			; Have we reached the top?
	jg .sub_exit

	cmp word [.skip_num], 0	; Are we at the top of the list?
	je .jump_down

	dec word [.skip_num]	; If not, then just move the selection window up
	inc dh
	ret

.jump_down:
	mov ax, [.num_of_entries]
	movzx cx, byte [.height]
	cmp ax, cx				; Is the dialog smaller than its allowed number of entries?
	jg .transpose_skip_num	; If so, then shift the skip num

	add al, [.ypos]			; Set the cursor position to the last visible value
	mov dh, al
	ret

.transpose_skip_num:
	sub ax, cx
	mov [.skip_num], ax

	mov dh, [.height]		; Scroll the list all the way down
	add dh, [.ypos]

	ret

.move_down:
	inc dh					; Move the cursor down

	movzx cx, byte [.height]	; Figure out whether the list is scrollable or not
	cmp cx, [.num_of_entries]
	jg .move_down_not_scrollable

	cmp dh, [.endypos]		; Have we reached the bottom?
	jl .sub_exit

	mov ax, [.skip_num]		; Check if the list is scrolled all the way down
	movzx cx, byte [.height]
	add ax, cx

	cmp ax, [.num_of_entries]
	jge .jump_up

	inc word [.skip_num]	; If not, then scroll the list down
	dec dh
	ret

.move_down_not_scrollable:
	mov cl, [.ypos]
	add cl, [.num_of_entries]

	cmp dh, cl
	jle .sub_exit

.jump_up:
	mov word [.skip_num], 0
	mov dh, [.ypos]
	inc dh

.sub_exit:
	ret

.option_selected:
	call .dialog_end
	
	sub dh, [.ypos]		; Options start from 1
	shr dx, 8
	add dx, [.skip_num]	; Add any lines skipped from scrolling

	mov bx, sp
	mov [ss:bx + 14], dx

	popa
	clc					; Clear carry as Esc wasn't pressed
	ret

.esc_pressed:
	call .dialog_end
	popa
	stc					; Set carry for Esc
	ret

.dialog_end:
	call os_show_cursor

	mov di, [.history]
	test di, di
	jz .no_save_history

	; Save the history data

	mov si, .num_of_entries
	mov cx, 4
	rep movsb

	mov al, dh
	stosb

.no_save_history:
	ret

	.num_of_entries	dw 0
	.skip_num		dw 0

	.history		dw 0

	.callback		dw 0
	.xpos			db 0
	.ypos			db 0
	.endypos		db 0
	.width			db 0
	.height			db 0

; ------------------------------------------------------------------
; os_draw_background -- Clear screen with white top and bottom bars
; containing text, and a coloured middle section.
; IN: AX/BX = top/bottom string locations, CX = colour (256 if the app wants to display the default background)
; OUT: None, registers preserved

os_draw_background:
	pusha
	
	push ax				; Store params to pop out later
	push bx
	push cx

	mov16 dx, 0, 0
	call .draw_bar

	mov dx, 256
	call os_move_cursor
	
	pop bx				; Get colour param (originally in CX)
	cmp bx, 256
	je .draw_default_background

.fill_bg:	
	mov ax, 0920h			; Draw colour section
	mov cx, 1840
	clr bh
	int 10h

.bg_drawn:
	mov16 dx, 0, 24
	call .draw_bar

	mov16 dx, 1, 24
	call os_move_cursor
	pop si				; Get bottom string param
	call os_print_string

	mov16 dx, 1, 0
	call os_move_cursor
	pop si				; Get top string param
	call os_print_string

	call os_print_clock

	mov byte [0082h], 0	; Assume that an application drawing 
						; the background wants to refresh time		

	mov16 dx, 0, 1		; Ready for app text
	jmp os_move_cursor.no_pusha

.draw_default_background:
	mov bl, byte [57000] ; In case it is necessary

	cmp byte [fs:DESKTOP_BACKGROUND], 0
	je .fill_bg
	
	push ds
	push es
	
	push fs	; Set up source pointer
	pop ds

	mov si, DESKTOP_BACKGROUND

	push 0B800h ; Set up destination pointer
	pop es

	mov di, 160
	
	mov cx, 80 * 23 * 2
	
	rep movsb
	
	pop es
	pop ds
	jmp .bg_drawn
	
.draw_bar:
	call os_move_cursor

	mov ax, 0920h			; Draw white bar at top
	mov cx, 80
	mov bx, 01110000b
	int 10h
	ret

; ------------------------------------------------------------------
; os_print_newline -- Reset cursor to start of next line
; IN/OUT: None, registers preserved

os_print_newline:
	pusha

	mov al, 13
	call os_putchar
	mov al, 10
	jmp os_putchar.no_pusha


; ------------------------------------------------------------------
; os_dump_registers -- Displays register contents in hex on the screen
; IN: EAX/EBX/ECX/EDX/ESI/EDI = registers to show
; OUT: None, registers preserved

os_dump_registers:
	pushad

	push edi
	push .di_string
	push esi
	push .si_string
	push edx
	push .dx_string
	push ecx
	push .cx_string
	push ebx
	push .bx_string
	push eax
	push .ax_string
	
	mov cx, 6
	
.loop:
	pop si
	call os_print_string
	pop eax
	call os_print_8hex
	loop .loop
	
	call os_print_newline

	popad
	ret


	.ax_string		db 'EAX:', 0
	.bx_string		db ' EBX:', 0
	.cx_string		db ' ECX:', 0
	.dx_string		db ' EDX:', 0
	.si_string		db ' ESI:', 0
	.di_string		db ' EDI:', 0


; ------------------------------------------------------------------
; os_input_dialog -- Get text string from user via a dialog box
; IN: AX = string location, BX = message to show
; OUT: None, registers preserved

os_input_dialog:
	pusha
	clr ch
	jmp int_input_dialog

; ------------------------------------------------------------------
; os_password_dialog -- Get a password from user via a dialog box
; IN: AX = string location, BX = message to show
; OUT: None, registers preserved

os_password_dialog:
	pusha
	mov ch, 1

; ------------------------------------------------------------------
; int_input_dialog -- Get text string from user via a dialog box
; IN: AX = string location, BX = message to show,
;     CH = CH = 0 if normal input, 1 if password input
; OUT: None, registers preserved

int_input_dialog:
	pusha

	mov dl, [0088h]
	mov [.og_value], dl

	cmp dl, 50			; If there is no limit set, set it now
	jb .no_adjust

	mov dl, 50

.no_adjust:
	mov [0088h], dl

	push bx				; Save message to show

	mov bl, [57001]		; Color from RAM
	mov16 dx, 12, 10			; First, draw red background box
	mov si, 55
	mov di, 16
	call os_draw_block

	mov16 dx, 14, 14
	call os_move_cursor

	mov16 ax, ' ', 09h
	mov bx, 240
	mov cx, 51
	int 10h
	
	mov16 dx, 14, 11
	call os_move_cursor
	
	pop bx				; Get message back and display it
	mov si, bx
	call os_print_string

	mov16 dx, 14, 14
	call os_move_cursor

	popa

	push .retptr		; Don't worry too much about this
	pusha
	clr si
	jmp os_input_string_ex.no_pusha

.retptr:
	mov dl, [.og_value]
	mov [0088h], dl
	popa
	ret

	.og_value		db 0

; ------------------------------------------------------------------
; os_dialog_box -- Print dialog box in middle of screen, with button(s)
; IN: AX, BX, CX = string locations (set registers to 0 for no display),
; IN: DX = 0 for single 'OK' dialog,
;          1 for two-button 'OK' and 'Cancel' ('OK' selected by default),
;          2 for two-button 'OK' and 'Cancel' ('Cancel' selected by default)
; OUT: If two-button mode, AX = 0 for OK and 1 for cancel
; NOTE: Each string is limited to 40 characters

os_dialog_box:
	pusha
	mov si, ax
	mov ax, bx
	mov bx, cx
	clr cx
	clr dx
	call os_temp_box
	popa

	pusha
	cmp dx, 1
	jge .two_button

.one_button:
	mov16 dx, 35, 14
	call os_move_cursor

	mov bl, 0F0h
	mov si, .ok_button_string
	call os_format_string

.one_button_wait:
	call os_wait_for_key
	cmp al, 13			; Wait for enter key (13) to be pressed
	jne .one_button_wait

	jmp os_show_cursor.no_pusha

.two_button:
	cmp dx, 2
	je .draw_right
	jne .draw_left
	
.two_button_wait:
	call os_wait_for_key

	cmp ah, 75			; Left cursor key pressed?
	je .draw_left
	cmp ah, 77			; Right cursor key pressed?
	je .draw_right
	
	cmp al, 27			; Escape, automatically select "Cancel"
	je .cancel
	cmp al, 13			; Wait for enter key (13) to be pressed
	jne .two_button_wait

.exit:	
	call os_show_cursor

	mov [.tmp], cl			; Keep result after restoring all regs
	popa
	movzx ax, byte [.tmp]

	ret

.cancel:
	mov cl, 1
	jmp .exit

.draw_left:
	clr cl
	mov bl, 11110000b
	mov bh, [57001]

	jmp .draw_buttons

.draw_right:
	mov cl, 1
	mov bl, [57001]
	mov bh, 11110000b

	jmp .draw_buttons

.draw_buttons:
	mov16 dx, 27, 14
	call os_move_cursor

	mov si, .ok_button_string
	call os_format_string

	mov16 dx, 42, 14
	call os_move_cursor

	mov bl, bh
	mov si, .cancel_button_string
	call os_format_string

	jmp .two_button_wait

	.ok_button_string	db '   OK   ', 0
	.cancel_button_string	db ' Cancel ', 0

	.tmp db 0

; ------------------------------------------------------------------
; os_print_space -- Print a space to the screen
; IN/OUT: None, registers preserved

os_print_space:
	pusha
	mov al, ' '
	jmp os_putchar.no_pusha


; ------------------------------------------------------------------
; os_print_digit -- Displays contents of AX as a single digit
; Works up to base 37, ie digits 0-Z
; IN: AX = "digit" to format and print
; OUT: None, registers preserved

os_print_digit:
	push ax

.no_push_ax:
	cmp al, 9			; There is a break in ASCII table between 9 and A
	jle .digit_format

	add al, 'A'-'9'-1		; Correct for the skipped punctuation

.digit_format:
	add al, '0'			; 0 will display as '0', etc.	

	call os_putchar
	pop ax
	ret


; ------------------------------------------------------------------
; os_print_1hex -- Displays low nibble of AL in hex format
; IN: AL = number to format and print
; OUT: None, registers preserved

os_print_1hex:
	push ax

.no_push_ax:
	and al, 0Fh			; Mask off data to display
	jmp os_print_digit.no_push_ax


; ------------------------------------------------------------------
; os_print_2hex -- Displays AL in hex format
; IN: AL = number to format and print
; OUT: None, registers preserved

os_print_2hex:
	push ax

.no_push_ax:
	push ax				; Output high nibble
	shr ax, 4
	call os_print_1hex

	pop ax				; Output low nibble
	jmp os_print_1hex.no_push_ax


; ------------------------------------------------------------------
; os_print_4hex -- Displays AX in hex format
; IN: AX = number to format and print
; OUT: None, registers preserved

os_print_4hex:
	push ax

	push ax				; Output high byte
	mov al, ah
	call os_print_2hex

	pop ax				; Output low byte
	jmp os_print_2hex.no_push_ax

; ------------------------------------------------------------------
; os_print_8hex - Displays EAX in hex format
; IN: EAX = unsigned integer
; OUT: None, registers preserved

os_print_8hex:
	pushad
	shr eax, 16
	call os_print_4hex
	popad
	call os_print_4hex
	ret

; ------------------------------------------------------------------
; os_print_int -- Prints an integer in decimal.
; IN: AX = unsigned integer
; OUT: None, registers preserved

os_print_int:
	pusha
	call os_int_to_string
	mov si, ax
	call os_print_string
	popa
	ret

; ------------------------------------------------------------------
; os_print_32int -- Prints a 32 bit integer in decimal.
; IN: EAX = unsigned integer
; OUT: None, registers preserved

os_print_32int:
	pushad
	call os_32int_to_string
	mov si, ax
	call os_print_string
	popad
	ret

; ------------------------------------------------------------------
; os_input_string -- Take string from keyboard entry
; IN: AX = location of string
; (Location will contain up to [0088h] characters, zero-terminated)
; OUT: None, registers preserved

os_input_string:
	pusha

.no_pusha:
	clr ch
	clr si
	jmp os_input_string_ex.no_pusha

; ------------------------------------------------------------------
; os_input_password -- Take password from keyboard entry
; IN: AX = location of string
; (Location will contain up to [0088h] characters, zero-terminated)
; OUT: None, registers preserved

os_input_password:
	pusha

.no_pusha:
	mov ch, 1
	clr si
	jmp os_input_string_ex.no_pusha

; ------------------------------------------------------------------
; os_input_string_ex -- Take string from keyboard entry
; IN: AX = location of string, CH = 0 if normal input, 1 if password input,
;     SI = callback on keys where AL = 0 (input: AX = keypress)
; (Location will contain up to [0088h] characters, zero-terminated)
; OUT: None, registers preserved

os_input_string_ex:
	pusha

.no_pusha:
	call os_show_cursor
	
	mov di, ax			; DI is where we'll store input (buffer)
	clr cl				; Received characters counter for backspace

.more:
	call os_wait_for_key

	cmp al, 13			; If Enter key pressed, finish
	je .done

	cmp al, 8			; Backspace pressed?
	je .backspace		; If so, skip following checks

	cmp al, ' '			; If an incompatible key pressed, call the callback
	jl .callback

	cmp cl, [0088h]		; Make sure we don't exhaust buffer
	je .more

	stosb				; Store character in designated buffer

	cmp ch, 0
	je .no_star

	mov al, '*'			; If password input was selected, print stars instead

.no_star:
	call os_putchar

	inc cl				; Characters processed += 1
	
	jmp .more			; Still room for more

.callback:
	test si, si
	jz .more

	pusha
	call si
	popa
	jmp .more

.backspace:
	test cl, cl			; Backspace at start of string?
	jz .more			; Ignore it if so

	call os_get_cursor_pos		; Backspace at start of screen line?
	test dl, dl
	jz .backspace_linestart

	dec dl
	call os_move_cursor
	mov al, ' '
	call os_putchar
	call os_move_cursor

	dec di				; Character position will be overwritten by new
						; character or terminator at end

	dec cl				; Step back counter

	jmp .more

.backspace_linestart:
	dec dh				; Jump back to end of previous line
	mov dl, 79
	call os_move_cursor

	mov al, ' '			; Clear the character there
	call os_putchar

	mov dl, 79			; And jump back before the space
	call os_move_cursor

	dec di				; Step back position in string
	dec cl				; Step back counter

	jmp .more

.done:
	clr al
	stosb

	popa
	ret
	
; ------------------------------------------------------------------
; os_color_selector - Pops up a color selector.
; IN: None
; OUT: color number (0-15)

os_color_selector:
	pusha
	mov ax, .colorlist			; Call os_list_dialog with colors
	mov bx, .colormsg0
	mov cx, .colormsg1

	mov si, .callback
	call os_list_dialog_tooltip
	pushf
	
	dec al						; Output from os_list_dialog starts with 1, so decrement it
	mov bx, sp
	mov [ss:bx + 16], al
	popf
	popa
	ret

.callback:
	dec al
	mov bl, al			; Selected color
	shl bl, 4
	mov16 dx, 41, 2		; Start X/Y position
	mov si, 37			; Width
	mov di, 23			; Finish Y position
	call os_draw_block	; Draw option selector window	
	ret

	.colorlist	db 'Black,Blue,Green,Cyan,Red,Magenta,Brown,Light Gray,Dark Gray,Light Blue,Light Green,Light Cyan,Light Red,Pink,Yellow,White', 0
	.colormsg0	db 'Choose a color...' ; termination not necessary here
	.colormsg1	db 0
	
; ------------------------------------------------------------------
; os_temp_box -- Draws a dialog box with up to 5 lines of text.
; IN: SI/AX/BX/CX/DX = string locations (or 0 for no display)
; OUT: None, registers preserved

os_temp_box:
	pusha

	push dx
	push cx
	push bx
	push ax
	push si
	
	call os_hide_cursor

	mov bl, [57001]		; Color from RAM
	mov16 dx, 19, 9			; First, draw red background box
	mov si, 42
	mov di, 16
	call os_draw_block

	mov16 dx, 20, 9
	mov cx, 5

.loop:
	inc dh
	call os_move_cursor

	pop si
	test si, si			; Skip string params if zero
	jz .no_string

	call os_print_string

.no_string:
	loop .loop

	popa
	ret

; ------------------------------------------------------------------
; int_save_footer -- Saves the current footer & prepares cursor, if applicable.
; IN: None
; OUT: DX = cursor position where to return, CF = 1 if no message should be printed

int_save_footer:
	pusha
	cmp byte [0082h], 1
	stc
	je int_popa_ret

	call os_get_cursor_pos
	mov [int_footer_cursor], dx

	mov di, int_footer_data
	mov16 dx, 0, 24
	
.loop:
	call os_move_cursor
	
	mov ah, 08h
	clr bh
	int 10h
	
	stosb
	
	inc dl
	cmp dl, 79
	jl .loop

	mov16 dx, 1, 24
	call os_move_cursor

	clc
	popa
	ret

; ------------------------------------------------------------------
; int_restore_footer -- Restores the saved footer, if applicable.
; IN: DX = cursor position where to return
; OUT: None, registers preserved

int_restore_footer:
	pusha
	cmp byte [0082h], 1
	je int_popa_ret

	mov16 dx, 0, 24
	call os_move_cursor
	
	mov ax, 0920h
	mov bx, 70h
	mov cx, 80
	int 10h
	
	mov si, int_footer_data
	call os_print_string

	mov dx, [int_footer_cursor]
	jmp os_move_cursor.no_pusha

	int_footer_data		times 80 db 0	; 80 chars + zero term.
	int_footer_cursor	dw 0

; ------------------------------------------------------------------
; os_reset_font -- Resets the font to the selected default.
; IN/OUT = None, registers preserved

os_reset_font:
	pusha
	
	cmp byte [57073], 1
	je .bios
	
	push es
	mov ax, 1100h
	mov bx, 1000h
	mov cx, 0100h
	clr dx
	mov es, [driversgmt]
	mov bp, SYSTEM_FONT
	int 10h
	pop es

.bios:
	popa
	ret

; ------------------------------------------------------------------
; os_draw_logo -- Draws the MichalOS logo.
; IN: None
; OUT: A very beautiful logo :-)

os_draw_logo:
	pusha
	
	mov ax, 0920h
	mov bx, 00000100b
	mov cx, 560
	int 10h

	mov si, logo
	jmp os_draw_icon.no_pusha

; ------------------------------------------------------------------
; os_draw_icon -- Draws an icon (in the MichalOS format).
; IN: SI = address of the icon
; OUT: None, registers preserved

os_draw_icon:
	pusha
	
.no_pusha:
	call os_get_cursor_pos
	
	lodsw
	
	clr cx
	
.loop:
	push ax
	push cx

	lodsb
		
	mov cx, 4
	mov ah, al

.byteloop:
	movzx bx, ah
	and bl, 11000000b
	shr bl, 6
	mov al, [.chars + bx]
	call os_putchar

	shl ah, 2

	loop .byteloop

	pop cx
	pop ax

	inc cl
	cmp cl, al
	jne .loop

	inc dh
	call os_move_cursor
	
	clr cl
	inc ch
	cmp ch, ah
	jne .loop
	
	popa
	ret

	.chars		db 32, 220, 223, 219
	
; ------------------------------------------------------------------
; os_option_menu -- Show a menu with a list of options
; IN: AX = comma-separated list of strings to show (zero-terminated)
; OUT: AX = number (starts from 1) of entry selected; carry set if Esc, left or right pressed

os_option_menu:
	pusha
	cmp byte [57071], 0	; "Blur" the background if requested
	je .skip
	
	mov16 dx, 0, 1

	call os_move_cursor
	
	mov ah, 08h
	clr bh
	int 10h				; Get the character's attribute (X = 0, Y = 1)
	
	and ah, 0F0h		; Keep only the background, set foreground to 0
	
	movzx bx, ah
	mov ax, 09B1h
	mov cx, 1840
	int 10h
	
	popa
	pusha

.skip:
	call os_string_callback_tokenizer

	mov ah, cl

	cmp cx, 20			; Would the list overflow?
	jle .good

	mov ah, 20			; If so, shrink it to fit on the screen

.good:
	mov16 dx, 1, 1
	mov bl, [57072]
	clr di
	jmp os_select_list.no_pusha

; ------------------------------------------------------------------
; os_print_clock -- Prints the time/date/speaker status in the
; top right corner of the screen
; IN/OUT: None, registers preserved

os_print_clock:
	pusha
	call os_get_cursor_pos
	push dx
	
	mov bx, .tmp_buffer
	call os_get_time_string

	mov dx, 63			; Display time
	call os_move_cursor
	mov si, bx
	call os_print_string

	mov bx, .tmp_buffer
	call os_get_date_string

	call os_print_space
	mov si, bx
	call os_print_string
	
	mov al, 17h
	sub al, [0083h]
	call os_putchar

	pop dx
	jmp os_move_cursor.no_pusha
		
	.tmp_buffer		times 12 db 0

; ==================================================================
