; ==================================================================
; SCREEN HANDLING SYSTEM CALLS
; ==================================================================

; ------------------------------------------------------------------
; os_putchar -- Puts a character on the screen
; IN: AL = character
; OUT: Nothing (registers preserved)

os_putchar:
	pusha
	mov ah, 0Eh
	int 10h
	popa
	ret

; ------------------------------------------------------------------
; os_put_chars -- Puts up to a set amount of characters on the screen
; IN: BL = terminator, SI = location, CX = character count
; OUT: Nothing (registers preserved)

os_put_chars:
	pusha
	
.loop:
	lodsb
	cmp al, bl
	je .done
	
	call os_putchar
	
	loop .loop
	
.done:
	popa
	ret

; ------------------------------------------------------------------
; os_print_string -- Displays text
; IN: SI = message location (zero-terminated string)
; OUT: Nothing (registers preserved)

os_print_string:
	pusha

.repeat:
	lodsb				; Get char from string
	cmp al, 0
	je .done			; If char is zero, end of string

	call os_putchar
	jmp .repeat			; And move on to next char

.done:
	popa
	ret

; ------------------------------------------------------------------
; os_print_string_box -- Displays text inside a text-box.
; IN: SI = message location (zero-terminated string), DL = left alignment
; OUT: Nothing (registers preserved)

os_print_string_box:
	pusha
	mov cl, dl

.repeat:
	lodsb				; Get char from string
	cmp al, 0
	je .done			; If char is zero, end of string

	cmp al, 13
	je .cr
	
	call os_putchar
	jmp .repeat			; And move on to next char

.done:
	popa
	ret
	
.cr:
	call os_get_cursor_pos
	mov dl, cl
	call os_move_cursor
	jmp .repeat

; ------------------------------------------------------------------
; os_format_string -- Displays colored text
; IN: BL/SI = text color/message location (zero-terminated string)
; OUT: Nothing (registers preserved)

os_format_string:
	pusha

	mov ah, 09h			; int 09h
	mov bh, 0
	mov cx, 1
	call os_get_cursor_pos
	
.repeat:
	lodsb				; Get char from string
	cmp al, 13
	je .cr
	cmp al, 10
	je .lf
	cmp al, 0
	je .done			; If char is zero, end of string

	int 10h				; Otherwise, print it

	inc dl
	call os_move_cursor
	
	jmp .repeat			; And move on to next char
	
.cr:
	mov dl, 0
	call os_move_cursor
	jmp .repeat

.lf:
	inc dh
	call os_move_cursor
	jmp .repeat
	
.done:
	popa
	ret


; ------------------------------------------------------------------
; os_clear_screen -- Clears the screen to background
; IN/OUT: Nothing (registers preserved)

os_clear_screen:
	pusha

	mov dx, 0			; Position cursor at top-left
	call os_move_cursor

	mov16 ax, 0, 6		; Scroll full-screen
	mov bh, 7
	mov16 cx, 0, 0		; Top-left
	mov16 dx, 79, 24	; Bottom-right
	int 10h

	popa
	ret


; ------------------------------------------------------------------
; os_move_cursor -- Moves cursor in text mode
; IN: DH, DL = row, column; OUT: Nothing (registers preserved)

os_move_cursor:
	pusha

	mov bh, 0
	mov ah, 2
	int 10h				; BIOS interrupt to move cursor

	popa
	ret


; ------------------------------------------------------------------
; os_get_cursor_pos -- Return position of text cursor
; OUT: DH, DL = row, column

os_get_cursor_pos:
	pusha

	mov bh, 0
	mov ah, 3
	int 10h				; BIOS interrupt to get cursor position

	mov [.tmp], dx
	popa
	mov dx, [.tmp]
	ret


	.tmp dw 0


; ------------------------------------------------------------------
; os_print_horiz_line -- Draw a horizontal line on the screen
; IN: AX = line type (1 for double (-), otherwise single (=))
; OUT: Nothing (registers preserved)

os_print_horiz_line:
	pusha

	mov cx, ax			; Store line type param
	mov al, 196			; Default is single-line code

	cmp cx, 1			; Was double-line specified in AX?
	jne .ready
	mov al, 205			; If so, here's the code

.ready:
	mov cx, 80			; Counter
	mov ah, 0Eh			; BIOS output char routine
	mov bh, 0
	
.loop:
	int 10h
	loop .loop
	
	popa
	ret


; ------------------------------------------------------------------
; os_show_cursor -- Turns on cursor in text mode
; IN/OUT: Nothing

os_show_cursor:
	pusha

	mov16 cx, 7, 6
	mov16 ax, 3, 1
	int 10h

	popa
	ret


; ------------------------------------------------------------------
; os_hide_cursor -- Turns off cursor in text mode
; IN/OUT: Nothing

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

os_draw_block:
	pusha

.more:
	call os_move_cursor		; Move to block starting position

	mov16 ax, ' ', 09h			; Draw colour section
	mov bh, 0
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
; IN: If [0087h] = 1, then BX = location of file extension list
; OUT: AX = location of filename string (or carry set if Esc pressed)

os_file_selector:
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
	
	pusha
	mov word [.filename], 0		; Terminate string in case user leaves without choosing

	call os_report_free_space
	shr ax, 1					; Sectors -> kB
	mov [.freespace], ax
	
	; Add the filters, if desired

	mov di, 0051h
	mov byte [di], 0
	
	cmp byte [0087h], 1
	jne .no_filter
	
	mov [.extension_list], bx

	mov si, .filter_msg
	mov di, 0051h
	call os_string_copy

	pusha
	mov di, 0051h + 9
	mov si, bx
	mov bl, [si]
	inc si
	mov cl, 0
	
.filter_loop:
	call os_string_copy
	mov byte [di + 3], ' '
	add di, 4
	add si, 4
	inc cl
	cmp cl, bl
	jne .filter_loop
	
	mov byte [di], 0
	popa
	
.no_filter:
	; Create the filename index list

	call disk_read_root_dir		; Get the files into the buffer

	mov si, disk_buffer			; Raw directory buffer
	mov di, 64512				; Buffer for indexes
	mov cx, 0					; Number of found files

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

	cmp al, 0			; 1st byte = entry never used
	je .done

	pusha

	cmp byte [0087h], 1	; Check if we are supposed to filter the filenames
	jne .no_extension_check
	
	mov bx, [.extension_list]
	movzx cx, byte [bx]

.extension_loop:
	pusha
	add si, 8
	
	dec cx
	mov di, cx
	shl di, 2	; Each entry is 4 bytes long
	inc di		; The entry list starts with a 1-byte header
	add di, [.extension_list]
	
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

	mov byte [si+11], 0	; Zero-terminate the string

.skip:
	add si, byte 32		; Skip to the next file
	jmp .index_loop

.done:
	; Let the user select a file

	call os_file_dialog

	jc .esc_pressed

	call .get_filename
	
	popa
	mov ax, .filename
	clc
	ret

.esc_pressed:				; Set carry flag if Escape was pressed
	popa
	stc
	ret

.get_filename:
	dec ax				; Result from os_list_dialog starts from 1, but
						; for our file list offset we want to start from 0
	
	mov si, ax			; Get the pointer to the string in the index
	shl si, 1
	add si, 64512

	lodsw
	mov si, ax			; Our resulting pointer
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
	je .add_dot
	cmp cx, 11
	je .done_copy
	jmp .loopy

.add_dot:
	mov byte [di], '.'
	inc di
	jmp .loopy

.done_copy:
	mov byte [di], 0

	ret
	
.callback:
	; Draw the box on the right
	mov bl, [57001]		; Color from RAM
	mov16 dx, 41, 2		; Start X/Y position
	mov si, 37			; Width
	mov di, 23			; Finish Y position
	call os_draw_block	; Draw option selector window

	; Draw the icon's background
	mov bl, 0F0h
	mov16 dx, 50, 3
	mov si, 19			; Width
	mov di, 13			; Finish Y position
	call os_draw_block	; Draw option selector window	

	; Draw the icon
	
	mov16 dx, 52, 4
	call os_move_cursor
	
	mov si, filelogo
	call os_draw_icon

	; Display the filename

	mov16 dx, 42, 14
	call os_move_cursor

	push ax
	call .get_filename
	
	mov si, .filename
	call os_print_string
	
	; Find the correct directory entry for this file

	pop ax

	dec ax
	mov si, ax
	shl si, 1
	add si, 64512
	mov si, [si]			; Get the pointer to the entry in the index list

	push si
	
	; Display the file size
	
	mov eax, [si + 28]
	call os_32int_to_string
	
	mov si, ax
	mov di, .filename
	call os_string_copy
	
	mov ax, .filename
	mov bx, .byte_msg
	call os_string_add
	
	call os_string_length

	mov dl, 77
	sub dl, al
	call os_move_cursor
	
	mov si, .filename
	call os_print_string
	
	; Display the file write date/time
	
	mov byte [.filename], 0
	
	pop si
	mov bx, [si + 14]
	mov cx, [si + 16]
	
	push bx
	mov ax, cx		; Days
	and ax, 11111b
	
	mov dx, .dateseparator
	call .cb_add_num
	
	mov ax, cx		; Months
	shr ax, 5
	and ax, 1111b
	
	call .cb_add_num
	
	mov ax, cx		; Years
	shr ax, 9
	add ax, 1980
	
	mov dx, .whiteseparator
	call .cb_add_num
	
	pop cx
	
	mov ax, cx		; Hours
	shr ax, 11

	mov dx, .timeseparator
	call .cb_add_num
	
	mov ax, cx		; Minutes
	shr ax, 5
	and ax, 111111b
	
	call .cb_add_num

	mov ax, cx		; Seconds
	and ax, 11111b
	shl ax, 1

	mov dx, .help_msg2
	call .cb_add_num
	
	mov16 dx, 42, 16
	call os_move_cursor

	mov si, .time_msg
	call os_print_string
	
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
	
.cb_add_num:
	cmp ax, 10
	jge .no_zero
	
	push ax
	mov bx, .zerofill
	mov ax, .filename
	call os_string_add
	pop ax
	
.no_zero:
	call os_int_to_string
	mov bx, ax
	mov ax, .filename
	call os_string_add
	
	mov bx, dx
	call os_string_add

	ret
	
	.help_msg2		db 0
	.filter_msg		db 'Filters: ', 0
	.byte_msg		db ' bytes', 0
	.free_msg		db ' kB free', 0
	.timeseparator	db ':', 0
	.dateseparator	db '/', 0
	.whiteseparator	db ' ', 0
	.zerofill		db '0', 0

	.time_msg		db 'Written to on:  '
	.filename		times 20 db 0
	
	.vol_msg		db 'Volume '
	.volname		times 12 db 0
	.freespace		dw 0
	.extension_list	dw 0

	.file_selector_cursorpos		db 0
	.file_selector_skipnum			db 0
	.file_selector_numofentries		db 0

; ------------------------------------------------------------------
; os_file_dialog -- A modified version of os_list_dialog specifically created to display files.
; IN: CX = number of files
; OUT: AX = number (starts from 1) of entry selected; carry set if Esc pressed

os_file_dialog:
	pusha

	cmp cx, 0
	jne .continue

	popa

	mov ax, .nofilesmsg
	clr bx
	clr cx
	clr dx
	call os_dialog_box

	stc
	ret

	.nofilesmsg	db "There are no files to select.", 0

.continue:
	call os_hide_cursor
	mov byte [.num_of_entries], cl

	mov bl, [57001]		; Color from RAM
	mov16 dx, 2, 2		; Start X/Y position
	mov si, 37			; Width
	mov di, 23			; Finish Y position
	call os_draw_block	; Draw option selector window

	mov16 dx, 3, 3		; Show first line of help text...
	call os_move_cursor

	mov si, .root
	call os_print_string

	inc dh
	call os_move_cursor

	mov si, 0051h		; Filter message
	call os_print_string


	; Now that we've drawn the list, highlight the currently selected
	; entry and let the user move up and down using the cursor keys

	mov byte [.skip_num], 0		; Not skipping any lines at first showing

	mov16 dx, 25, 6			; Set up starting position for selector

	cmp cl, [os_file_selector.file_selector_numofentries]
	jne .no_load_position
	
	mov dh, [os_file_selector.file_selector_cursorpos]
	mov al, [os_file_selector.file_selector_skipnum]
	mov [.skip_num], al
	
.no_load_position:
	call os_move_cursor

.more_select:
	pusha
	mov bl, 11110000b		; Black on white for option list box
	mov16 dx, 3, 5
	mov si, 35
	mov di, 22
	call os_draw_block
	popa

	call .draw_black_bar

 	call .draw_list

.another_key:
	call os_wait_for_key		; Move / select option
	cmp ah, 48h			; Up pressed?
	je .go_up
	cmp ah, 50h			; Down pressed?
	je .go_down
	cmp al, 13			; Enter pressed?
	je .option_selected
	cmp al, 27			; Esc pressed?
	je .esc_pressed
	cmp al, 9			; Tab pressed?
	je .tab_pressed
	jmp .more_select	; If not, wait for another key

.tab_pressed:
	mov dh, 6
	mov byte [.skip_num], 0
	jmp .more_select
	
.go_up:
	cmp dh, 6			; Already at top?
	jle .hit_top

	call .draw_white_bar

	mov dl, 25
	call os_move_cursor

	dec dh				; Row to select (increasing down)
	jmp .more_select


.go_down:				; Already at bottom of list?
	cmp dh, 20
	je .hit_bottom

	clr cx
	mov byte cl, dh

	sub cl, 6
	inc cl
	add byte cl, [.skip_num]

	mov byte al, [.num_of_entries]
	cmp cl, al
	je .hit_bottom

	call .draw_white_bar

	mov dl, 25
	call os_move_cursor

	inc dh
	jmp .more_select


.hit_top:
	mov byte cl, [.skip_num]	; Any lines to scroll up?
	cmp cl, 0
	je .skip_to_bottom			; If not, wait for another key

	dec byte [.skip_num]		; If so, decrement lines to skip
	jmp .more_select


.hit_bottom:				; See if there's more to scroll
	clr cx
	mov byte cl, dh

	sub cl, 6
	inc cl
	add byte cl, [.skip_num]

	mov byte al, [.num_of_entries]
	cmp cl, al
	je .skip_to_top

	inc byte [.skip_num]		; If so, increment lines to skip
	jmp .more_select

.skip_to_top:
	mov byte [.skip_num], 0
	mov dh, 6
	jmp .more_select

.skip_to_bottom:
	mov al, [.num_of_entries]
	cmp al, 15
	jle .basic_skip
	
.no_basic_skip:
	mov dh, 20
	sub al, 15
	mov [.skip_num], al

	jmp .more_select
	
.basic_skip:
	cmp al, 0
	jl .no_basic_skip
	mov dh, al
	add dh, 5
	jmp .more_select
	
.option_selected:
	call os_show_cursor

	mov [os_file_selector.file_selector_cursorpos], dh
	mov al, [.skip_num]
	mov [os_file_selector.file_selector_skipnum], al
	mov al, [.num_of_entries]
	mov [os_file_selector.file_selector_numofentries], al
	
	sub dh, 6

	movzx ax, dh

	inc al				; Options start from 1
	add byte al, [.skip_num]	; Add any lines skipped from scrolling

	mov word [.tmp], ax		; Store option number before restoring all other regs

	popa

	mov word ax, [.tmp]
	clc				; Clear carry as Esc wasn't pressed
	ret

.esc_pressed:
	call os_show_cursor

	mov [os_file_selector.file_selector_cursorpos], dh
	mov al, [.skip_num]
	mov [os_file_selector.file_selector_skipnum], al
	mov al, [.num_of_entries]
	mov [os_file_selector.file_selector_numofentries], al
	
	popa
	stc				; Set carry for Esc
	ret


.draw_list:
	pusha

	mov16 dx, 5, 6		; Get into position for option list text
	call os_move_cursor

	mov cx, 0			; Skip lines scrolled off the top of the dialog
	mov byte cl, [.skip_num]

	clr bx

.more:
	push cx
	mov ax, cx
	inc ax
	call os_file_selector.get_filename
	mov si, os_file_selector.filename
	call os_print_string
	pop cx

	mov dl, 5			; Go back to starting X position
	inc dh				; But jump down a line
	call os_move_cursor

	inc cx
	cmp cl, [.num_of_entries]
	je .done_list

	inc bx				; Update the number-of-options counter
	cmp bx, 15			; Limit to one screen of options
	jl .more

.done_list:
	popa

	; Print the current position on the bottom

	pusha
	push dx
	mov16 dx, 5, 22
	call os_move_cursor
	
	mov si, .string1
	call os_print_string
	
	pop dx
	mov al, [.skip_num]
	add al, dh
	sub al, 5
	movzx ax, al
	call os_int_to_string
	mov si, ax
	call os_print_string
	
	mov si, .string2
	call os_print_string
	
	movzx ax, byte [.num_of_entries]
	call os_int_to_string
	mov si, ax
	call os_print_string
	
	mov si, .string3
	call os_print_string
	
	; Issue a callback
	
	mov al, [.skip_num]
	add al, dh
	sub al, 5
	movzx ax, al
	call os_file_selector.callback
	
	popa
	ret

.draw_black_bar:
	pusha

	mov dl, 4
	call os_move_cursor

	mov16 ax, ' ', 09h			; Draw white bar at top
	mov16 bx, 00001111b, 0	; White text on black background
	mov cx, 33
	int 10h

	popa
	ret



.draw_white_bar:
	pusha

	mov dl, 4
	call os_move_cursor

	mov16 ax, ' ', 09h			; Draw white bar at top
	mov16 bx, 11110000b, 0	; White text on black background
	mov cx, 33
	int 10h

	popa
	ret

	.tmp			equ os_list_dialog.tmp
	.num_of_entries	equ os_list_dialog.num_of_entries
	.skip_num		equ os_list_dialog.skip_num
	.string1		equ os_list_dialog.string1
	.string2		equ os_list_dialog.string2
	.string3		equ os_list_dialog.string3
	.root			db 'A:/', 0


; ------------------------------------------------------------------
; os_list_dialog_tooltip -- Show a dialog with a list of options and a tooltip.
; That means, when the user changes the selection, the application will be called back
; to change the tooltip's contents.
; IN: AX = comma-separated list of strings to show (zero-terminated),
;     BX = first help string, CX = second help string
;     SI = callback pointer
; OUT: AX = number (starts from 1) of entry selected; carry set if Esc pressed

os_list_dialog_tooltip:
	mov word [0089h], 37
	
	mov [.callbackaddr], si
	
	mov word [os_list_dialog.callback], .callback
	call os_list_dialog
	mov word [os_list_dialog.callback], 0
	mov word [0089h], 76
	ret
	
.callback:
	; Draw the box on the right
	mov bl, [57001]		; Color from RAM
	mov16 dx, 41, 2		; Start X/Y position
	mov si, 37			; Width
	mov di, 23			; Finish Y position
	call os_draw_block	; Draw option selector window	

	mov16 dx, 42, 3
	call os_move_cursor

	call [.callbackaddr]
	ret
	
	.callbackaddr	dw 0
	
; ------------------------------------------------------------------
; os_list_dialog -- Show a dialog with a list of options
; IN: AX = comma-separated list of strings to show (zero-terminated),
;     BX = first help string, CX = second help string
; OUT: AX = number (starts from 1) of entry selected; carry set if Esc pressed

os_list_dialog:
	pusha

	push ax				; Store string list for now

	push cx				; And help strings
	push bx

	call os_hide_cursor

	mov si, ax
	cmp byte [si], 0
	jne .count_entries

	add sp, 6
	popa
	mov ax, .empty
	call os_list_dialog
	ret
	
.count_entries:	
	mov cl, 0			; Count the number of entries in the list
	
.count_loop:
	mov al, [es:si]
	inc si
	cmp al, 0
	je .done_count
	cmp al, ','
	jne .count_loop
	inc cl
	jmp .count_loop

.done_count:
	inc cl
	mov byte [.num_of_entries], cl


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


	pop si				; SI = location of option list string (pushed earlier)
	mov word [.list_string], si


	; Now that we've drawn the list, highlight the currently selected
	; entry and let the user move up and down using the cursor keys

	mov byte [.skip_num], 0		; Not skipping any lines at first showing

	mov16 dx, 25, 6			; Set up starting position for selector

	call os_move_cursor

.more_select:
	pusha
	mov bl, 11110000b		; Black on white for option list box
	mov16 dx, 3, 5
	mov si, [0089h]
	sub si, byte 2
	mov di, 22
	call os_draw_block
	popa

	call .draw_black_bar

	mov word si, [.list_string]
 	call .draw_list

.another_key:
	call os_wait_for_key		; Move / select option
	cmp ah, 48h			; Up pressed?
	je .go_up
	cmp ah, 50h			; Down pressed?
	je .go_down
	cmp al, 13			; Enter pressed?
	je .option_selected
	cmp al, 27			; Esc pressed?
	je .esc_pressed
	cmp al, 9			; Tab pressed?
	je .tab_pressed
	jmp .more_select	; If not, wait for another key

.tab_pressed:
	mov dh, 6
	mov byte [.skip_num], 0
	jmp .more_select
	
.go_up:
	cmp dh, 6			; Already at top?
	jle .hit_top

	call .draw_white_bar

	mov dl, 25
	call os_move_cursor

	dec dh				; Row to select (increasing down)
	jmp .more_select


.go_down:				; Already at bottom of list?
	cmp dh, 20
	je .hit_bottom

	clr cx
	mov byte cl, dh

	sub cl, 6
	inc cl
	add byte cl, [.skip_num]

	mov byte al, [.num_of_entries]
	cmp cl, al
	je .hit_bottom

	call .draw_white_bar

	mov dl, 25
	call os_move_cursor

	inc dh
	jmp .more_select


.hit_top:
	mov byte cl, [.skip_num]	; Any lines to scroll up?
	cmp cl, 0
	je .skip_to_bottom			; If not, wait for another key

	dec byte [.skip_num]		; If so, decrement lines to skip
	jmp .more_select


.hit_bottom:				; See if there's more to scroll
	clr cx
	mov byte cl, dh

	sub cl, 6
	inc cl
	add byte cl, [.skip_num]

	mov byte al, [.num_of_entries]
	cmp cl, al
	je .skip_to_top

	inc byte [.skip_num]		; If so, increment lines to skip
	jmp .more_select

.skip_to_top:
	mov byte [.skip_num], 0
	mov dh, 6
	jmp .more_select

.skip_to_bottom:
	mov al, [.num_of_entries]
	cmp al, 15
	jle .basic_skip
	
.no_basic_skip:
	mov dh, 20
	sub al, 15
	mov [.skip_num], al

	jmp .more_select
	
.basic_skip:
	cmp al, 0
	jl .no_basic_skip
	mov dh, al
	add dh, 5
	jmp .more_select
	
.option_selected:
	call os_show_cursor

	sub dh, 6

	movzx ax, dh

	inc al				; Options start from 1
	add byte al, [.skip_num]	; Add any lines skipped from scrolling

	mov word [.tmp], ax		; Store option number before restoring all other regs

	popa

	mov word ax, [.tmp]
	clc				; Clear carry as Esc wasn't pressed
	ret



.esc_pressed:
	call os_show_cursor

	popa
	stc				; Set carry for Esc
	ret



.draw_list:
	pusha

	mov16 dx, 5, 6		; Get into position for option list text
	call os_move_cursor


	mov cx, 0			; Skip lines scrolled off the top of the dialog
	mov byte cl, [.skip_num]

.skip_loop:
	cmp cx, 0
	je .skip_loop_finished
.more_lodsb:
	mov al, [es:si]
	inc si
	cmp al, ','
	jne .more_lodsb
	dec cx
	jmp .skip_loop


.skip_loop_finished:
	mov bx, 0			; Counter for total number of options


.more:
	mov al, [es:si]		; Get next character in file name, increment pointer
	inc si
	
	cmp al, 0			; End of string?
	je .done_list

	cmp al, ','			; Next option? (String is comma-separated)
	je .newline

	mov ah, 0Eh
	int 10h
	jmp .more

.newline:
	mov dl, 5			; Go back to starting X position
	inc dh				; But jump down a line
	call os_move_cursor

	inc bx				; Update the number-of-options counter
	cmp bx, 15			; Limit to one screen of options
	jl .more

.done_list:
	popa
	call os_move_cursor

	pusha
	push dx
	mov16 dx, 5, 22
	call os_move_cursor
	
	mov si, .string1
	call os_print_string
	
	pop dx
	mov al, [.skip_num]
	add al, dh
	sub al, 5
	movzx ax, al
	call os_int_to_string
	mov si, ax
	call os_print_string
	
	mov si, .string2
	call os_print_string
	
	movzx ax, byte [.num_of_entries]
	call os_int_to_string
	mov si, ax
	call os_print_string
	
	mov si, .string3
	call os_print_string
	
	
	mov al, [.skip_num]
	add al, dh
	sub al, 5
	movzx ax, al
	call [.callback]
	
	popa
	ret



.draw_black_bar:
	pusha

	mov dl, 4
	call os_move_cursor

	mov16 ax, ' ', 09h			; Draw white bar at top
	mov16 bx, 00001111b, 0	; White text on black background
	mov cx, [0089h]
	sub cx, byte 4
	int 10h

	popa
	ret



.draw_white_bar:
	pusha

	mov dl, 4
	call os_move_cursor

	mov16 ax, ' ', 09h			; Draw white bar at top
	mov16 bx, 11110000b, 0	; White text on black background
	mov cx, [0089h]
	sub cx, byte 4
	int 10h

	popa
	ret


	.tmp			dw 0
	.num_of_entries		db 0
	.skip_num		db 0
	.list_string		dw 0
	.string1		db '(', 0
	.string2		db '/', 0
	.string3		db ')  ', 0
	.empty			db '< The list is empty. >', 0
	.callback		dw 0
	
; ------------------------------------------------------------------
; os_draw_background -- Clear screen with white top and bottom bars
; containing text, and a coloured middle section.
; IN: AX/BX = top/bottom string locations, CX = colour (256 if the app wants to display the default background)

os_draw_background:
	pusha
	
	push ax				; Store params to pop out later
	push bx
	push cx

	mov dx, 0
	call os_move_cursor

	mov ax, 0920h			; Draw white bar at top
	mov cx, 80
	mov bx, 01110000b
	int 10h

	mov dx, 256
	call os_move_cursor
	
	pop bx				; Get colour param (originally in CX)
	cmp bx, 256
	je .draw_default_background
	
	mov ax, 0920h			; Draw colour section
	mov cx, 1840
	mov bh, 0
	int 10h

.bg_drawn:
	mov16 dx, 0, 24
	call os_move_cursor

	mov ax, 0920h			; Draw white bar at top
	mov cx, 80
	mov bx, 01110000b
	int 10h

	mov16 dx, 1, 24
	call os_move_cursor
	pop si				; Get bottom string param
	call os_print_string

	mov dx, 1
	call os_move_cursor
	pop si				; Get top string param
	call os_print_string

	mov bx, tmp_string
	call os_get_date_string
	
	mov dx, 69			; Display date
	call os_move_cursor
	mov si, bx
	call os_print_string
	
	mov bx, tmp_string
	call os_get_time_string

	mov dx, 63			; Display time
	call os_move_cursor
	mov si, bx
	call os_print_string
	
	mov dl, 79			; Print the little speaker icon
	call os_move_cursor
	
	mov ax, 0E17h
	sub al, [0083h]
	mov bh, 0
	int 10h
	
	mov16 dx, 0, 1		; Ready for app text
	call os_move_cursor

	popa
	ret

.draw_default_background:
	cmp byte [fs:DESKTOP_BACKGROUND], 0
	je .fill_color
	
	push ds
	push es
	
	mov ds, [driversgmt]
	mov si, DESKTOP_BACKGROUND

	mov ax, 0B800h
	mov es, ax
	mov di, 160
	
	mov cx, 80 * 23 * 2
	
	rep movsb
	
	pop es
	pop ds
	jmp .bg_drawn
	
.fill_color:
	movzx bx, byte [57000]
	mov ax, 0920h
	mov cx, 1840

	int 10h
	jmp .bg_drawn

	tmp_string			times 15 db 0


; ------------------------------------------------------------------
; os_print_newline -- Reset cursor to start of next line
; IN/OUT: Nothing (registers preserved)

os_print_newline:
	pusha

	mov ah, 0Eh			; BIOS output char code

	mov al, 13
	int 10h
	mov al, 10
	int 10h

	popa
	ret


; ------------------------------------------------------------------
; os_dump_registers -- Displays register contents in hex on the screen
; IN/OUT: EAX/EBX/ECX/EDX/ESI/EDI = registers to show

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
; IN: AX = string location, BX = message to show; OUT: AX = string location

os_input_dialog:
	pusha

	push ax				; Save string location
	push bx				; Save message to show


	mov16 dx, 12, 10			; First, draw red background box

.redbox:				; Loop to draw all lines of box
	call os_move_cursor

	pusha
	mov16 ax, ' ', 09h
	mov cx, 55
	movzx bx, byte [57001]		; Color from RAM
	int 10h
	popa

	inc dh
	cmp dh, 16
	je .boxdone
	jmp .redbox


.boxdone:
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


	pop ax				; Get input string back
	call os_input_string

	popa
	ret

; ------------------------------------------------------------------
; os_password_dialog -- Get a password from user via a dialog box
; IN: AX = string location, BX = message to show; OUT: AX = string location

os_password_dialog:
	pusha

	push ax				; Save string location
	push bx				; Save message to show


	mov16 dx, 12, 10			; First, draw red background box

.redbox:				; Loop to draw all lines of box
	call os_move_cursor

	pusha
	mov16 ax, ' ', 09h
	mov cx, 55
	movzx bx, byte [57001]		; Color from RAM
	int 10h
	popa

	inc dh
	cmp dh, 16
	je .boxdone
	jmp .redbox


.boxdone:
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


	pop ax				; Get input string back
	mov bl, 240
	call os_input_password

	popa
	ret


; ------------------------------------------------------------------
; os_dialog_box -- Print dialog box in middle of screen, with button(s)
; IN: AX, BX, CX = string locations (set registers to 0 for no display),
; IN: DX = 0 for single 'OK' dialog, 1 for two-button 'OK' and 'Cancel'
; IN: [0085h] = Default button for 2-button dialog (0 or 1)
; OUT: If two-button mode, AX = 0 for OK and 1 for cancel
; NOTE: Each string is limited to 40 characters

os_dialog_box:
	pusha

	push dx

	push cx
	push bx
	push ax
	
	call os_hide_cursor

	pusha
	mov bl, [57001]		; Color from RAM
	mov16 dx, 19, 9			; First, draw red background box
	mov si, 42
	mov di, 16
	call os_draw_block
	popa
	
	mov16 dx, 20, 9
	mov cx, 3
	
.loop:
	inc dh
	call os_move_cursor
	
	pop si
	cmp si, 0
	je .no_string
	
	call os_print_string
	
.no_string:
	loop .loop
	
	pop dx
	cmp dx, 1
	je .two_button

	
.one_button:
	mov bl, 11110000b		; Black on white
	mov16 dx, 35, 14
	mov si, 8
	mov di, 15
	call os_draw_block

	mov16 dx, 38, 14		; OK button, centred at bottom of box
	call os_move_cursor
	mov si, .ok_button_string
	call os_print_string

.one_button_wait:
	call os_wait_for_key
	cmp al, 13			; Wait for enter key (13) to be pressed
	jne .one_button_wait

	call os_show_cursor

	popa
	ret

.two_button:
	mov bl, 11110000b		; Black on white
	mov16 dx, 27, 14
	mov si, 8
	mov di, 15
	call os_draw_block

	mov16 dx, 30, 14			; OK button
	call os_move_cursor
	mov si, .ok_button_string
	call os_print_string

	mov16 dx, 44, 14			; Cancel button
	call os_move_cursor
	mov si, .cancel_button_string
	call os_print_string

	cmp byte [0085h], 1
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
	
	call os_show_cursor

	mov [.tmp], cx			; Keep result after restoring all regs
	popa
	mov ax, [.tmp]

	ret

.cancel:
	call os_show_cursor
	popa
	mov ax, 1
	ret

.draw_left:
	mov bl, 11110000b		; Black on white
	mov16 dx, 27, 14
	mov si, 8
	mov di, 15
	call os_draw_block

	mov16 dx, 30, 14		; OK button
	call os_move_cursor
	mov si, .ok_button_string
	call os_print_string

	mov bl, [57001]
	mov16 dx, 42, 14
	mov si, 9
	mov di, 15
	call os_draw_block

	mov16 dx, 44, 14		; Cancel button
	call os_move_cursor
	mov si, .cancel_button_string
	call os_print_string

	mov cx, 0			; And update result we'll return
	jmp .two_button_wait

.draw_right:
	mov bl, [57001]
	mov16 dx, 27, 14
	mov si, 8
	mov di, 15
	call os_draw_block

	mov16 dx, 30, 14			; OK button
	call os_move_cursor
	mov si, .ok_button_string
	call os_print_string

	mov bl, 11110000b
	mov16 dx, 43, 14
	mov si, 8
	mov di, 15
	call os_draw_block

	mov16 dx, 44, 14			; Cancel button
	call os_move_cursor
	mov si, .cancel_button_string
	call os_print_string

	mov cx, 1			; And update result we'll return
	jmp .two_button_wait



	.ok_button_string	db 'OK', 0
	.cancel_button_string	db 'Cancel', 0

	.tmp dw 0

; ------------------------------------------------------------------
; os_print_space -- Print a space to the screen
; IN/OUT: Nothing

os_print_space:
	pusha

	mov ax, 0E20h			; BIOS teletype function
	int 10h

	popa
	ret


; ------------------------------------------------------------------
; os_print_digit -- Displays contents of AX as a single digit
; Works up to base 37, ie digits 0-Z
; IN: AX = "digit" to format and print

os_print_digit:
	pusha

	cmp ax, 9			; There is a break in ASCII table between 9 and A
	jle .digit_format

	add ax, 'A'-'9'-1		; Correct for the skipped punctuation

.digit_format:
	add ax, '0'			; 0 will display as '0', etc.	

	mov ah, 0Eh			; May modify other registers
	int 10h

	popa
	ret


; ------------------------------------------------------------------
; os_print_1hex -- Displays low nibble of AL in hex format
; IN: AL = number to format and print

os_print_1hex:
	pusha

	and ax, 0Fh			; Mask off data to display
	call os_print_digit

	popa
	ret


; ------------------------------------------------------------------
; os_print_2hex -- Displays AL in hex format
; IN: AL = number to format and print

os_print_2hex:
	pusha

	push ax				; Output high nibble
	shr ax, 4
	call os_print_1hex

	pop ax				; Output low nibble
	call os_print_1hex

	popa
	ret


; ------------------------------------------------------------------
; os_print_4hex -- Displays AX in hex format
; IN: AX = number to format and print

os_print_4hex:
	pusha

	push ax				; Output high byte
	mov al, ah
	call os_print_2hex

	pop ax				; Output low byte
	call os_print_2hex

	popa
	ret


; ------------------------------------------------------------------
; os_input_string -- Take string from keyboard entry
; IN/OUT: AX = location of string, other regs preserved
; (Location will contain up to [0088h] characters, zero-terminated)

os_input_string:
	pusha

	call os_show_cursor
	
	mov di, ax			; DI is where we'll store input (buffer)
	mov cx, 0			; Character received counter for backspace


.more:					; Now onto string getting
	call os_wait_for_key

	cmp al, 13			; If Enter key pressed, finish
	je .done

	cmp al, 8			; Backspace pressed?
	je .backspace			; If not, skip following checks

	cmp al, ' '			; In ASCII range (32 - 127)?
	jl .more			; Ignore most non-printing characters

	jmp .nobackspace


.backspace:
	cmp cx, 0			; Backspace at start of string?
	je .more			; Ignore it if so

	call os_get_cursor_pos		; Backspace at start of screen line?
	cmp dl, 0
	je .backspace_linestart

	pusha
	mov ax, 0E08h		; If not, write space and move cursor back
	int 10h				; Backspace twice, to clear space
	mov al, 32
	int 10h
	mov al, 8
	int 10h
	popa

	dec di				; Character position will be overwritten by new
						; character or terminator at end

	dec cx				; Step back counter

	jmp .more


.backspace_linestart:
	dec dh				; Jump back to end of previous line
	mov dl, 79
	call os_move_cursor

	mov ax, 0E20h		; Print space there
	int 10h

	mov dl, 79			; And jump back before the space
	call os_move_cursor

	dec di				; Step back position in string
	dec cx				; Step back counter

	jmp .more


.nobackspace:
	movzx bx, byte [0088h]
	cmp cx, bx			; Make sure we don't exhaust buffer
	jge near .more

	pusha
	mov ah, 0Eh			; Output entered, printable character
	int 10h
	popa

	stosb				; Store character in designated buffer
	inc cx				; Characters processed += 1
	
	jmp near .more			; Still room for more

.done:
	mov al, 0
	stosb

	popa
	ret

; Input password(displays it as *s)
; IN: AX = location of string, other regs preserved, BL = color
; OUT: nothing
; (Location will contain up to [0088h] characters, zero-terminated)

os_input_password:
	pusha

	call os_get_cursor_pos	; Store the cursor position
	mov [.cursor], dx
	
	mov di, ax			; DI is where we'll store input (buffer)
	mov cx, 0			; Character received counter for backspace

.more:					; Now onto string getting
	call os_wait_for_key

	cmp al, 13			; If Enter key pressed, finish
	je .done

	cmp al, 8			; Backspace pressed?
	je .backspace			; If not, skip following checks

	cmp al, ' '			; In ASCII range (32 - 126)?
	jge .nobackspace	; Ignore most non-printing characters
	
	cmp al, 0
	jl .nobackspace
	
	jmp .more


.backspace:
	cmp cx, 0			; Backspace at start of string?
	je .more			; Ignore it if so

	dec di				; Character position will be overwritten by new
						; character or terminator at end

	dec cx				; Step back counter

	call .update
	
	jmp near .more


.nobackspace:
	movzx dx, byte [0088h]
	cmp cx, dx			; Make sure we don't exhaust buffer
	jge near .more

	stosb				; Store character in designated buffer
	inc cx				; Characters processed += 1

	call .update
	
	jmp near .more		; Still room for more

.done:
	mov al, 0
	stosb

	popa
	clc
	ret

.update:
	pusha
	mov dx, [.cursor]
	call os_move_cursor
	mov ax, 0920h		; Clear the line
	mov bh, 0
	mov cx, 32
	int 10h
	popa

	pusha
	mov dx, [.cursor]
	call os_move_cursor
	mov ax, 092Ah		; Print *s(amount in CX)
	mov bh, 0
	int 10h
	add dl, cl
	call os_move_cursor
	popa
	ret
	
	.cursor			dw 0
	
; Opens up os_list_dialog with color.
; IN: nothing
; OUT: color number(0-15)

os_color_selector:
	pusha
	mov ax, .colorlist			; Call os_list_dialog with colors
	mov bx, .colormsg0
	mov cx, .colormsg1
	call os_list_dialog
	
	dec ax						; Output from os_list_dialog starts with 1, so decrement it
	mov [.tmp_word], ax
	popa
	mov al, [.tmp_word]
	ret
	
	.colorlist	db 'Black,Blue,Green,Cyan,Red,Magenta,Brown,Light Gray,Dark Gray,Light Blue,Light Green,Light Cyan,Light Red,Pink,Yellow,White', 0
	.colormsg0	db 'Choose a color...', 0
	.colormsg1	db 0
	.tmp_word	dw 0
	
; Displays EAX in hex format
; IN: EAX = unsigned integer
; OUT: nothing
os_print_8hex:
	pushad
	pushad
	shr eax, 16
	call os_print_4hex
	popad
	call os_print_4hex
	popad
	ret
	
; Displays a dialog similar to os_dialog_box, but without the buttons.
; IN: SI/AX/BX/CX/DX = string locations(or 0 for no display)
; OUT: nothing
os_temp_box:
	pusha

	push dx
	push cx
	push bx
	push ax
	push si
	
	call os_hide_cursor

	mov16 dx, 19, 9			; First, draw red background box

.redbox:				; Loop to draw all lines of box
	call os_move_cursor

	pusha
	mov ax, 0920h
	movzx bx, byte [57001]		; Color from RAM
	mov cx, 42
	int 10h
	popa

	inc dh
	cmp dh, 16
	je .boxdone
	jmp .redbox


.boxdone:
	mov16 dx, 20, 9
	mov cx, 5

.loop:
	inc dh
	call os_move_cursor

	pop si
	cmp si, 0			; Skip string params if zero
	je .no_string

	call os_print_string

.no_string:
	loop .loop
	popa
	ret

; Prints a message on the footer.
; IN: SI = Message location(if 0, then it restores the previous message)
; OUT: nothing
os_print_footer:
	pusha
	mov al, [0082h]
	cmp al, 1
	je near .exit
	
	call os_get_cursor_pos
	push dx
	
	mov di, 1
	cmp si, 0
	je near .restore
	
	mov16 dx, 0, 24
	
.loop:
	call os_move_cursor
	
	mov ah, 08h
	mov bh, 0
	int 10h
	
	stosb
	
	inc dl
	cmp di, 81
	jnge near .loop
	
	mov byte [80], 0
	
	mov16 dx, 0, 24
	call os_move_cursor
	
	mov ax, 0920h
	mov bx, 70h
	mov cx, 80
	int 10h
	
	mov16 dx, 0, 24
	call os_move_cursor
	
	call os_print_string
	
	pop dx
	call os_move_cursor

.exit:	
	popa
	ret
	
.restore:
	mov16 dx, 0, 24
	call os_move_cursor
	mov si, 1
	call os_print_string
	
	pop dx
	call os_move_cursor
	
	popa
	ret
	
; Resets the font to the selected default.
; IN = nothing
; OUT = nothing
os_reset_font:
	pusha
	
	cmp byte [57073], 1
	je near .bios
	
	push es
	mov ax, 1100h
	mov bx, 1000h
	mov cx, 0100h
	clr dx
	mov es, [driversgmt]
	mov bp, SYSTEM_FONT
	int 10h
	pop es
	popa
	ret
	
.bios:
	popa
	ret

; Draws the MichalOS logo.
; IN: nothing
; OUT: a very beautiful logo :-)
os_draw_logo:
	pusha
	
	mov16 dx, 0, 2
	call os_move_cursor

	mov ax, 0920h
	mov bx, 00000100b
	mov cx, 560
	int 10h

	mov si, logo
	call os_draw_icon
	popa
	ret

; Draws an icon (in the MichalOS format).
; IN: SI = address of the icon
; OUT: nothing
os_draw_icon:
	pusha
	
	call os_get_cursor_pos
	mov [.cursor], dx
	
	lodsw
	mov [.size], ax
	
	clr cx
	
.loop:
	lodsb
	
	mov ah, 0Eh
	
	push cx
	mov cl, al
	movzx bx, cl
	and bl, 11000000b
	shr bl, 6
	mov al, [.chars + bx]
	int 10h
	
	movzx bx, cl
	and bl, 110000b
	shr bl, 4
	mov al, [.chars + bx]
	int 10h
	
	movzx bx, cl
	and bl, 1100b
	shr bl, 2
	mov al, [.chars + bx]
	int 10h
	
	movzx bx, cl
	and bl, 11b
	mov al, [.chars + bx]
	int 10h
	pop cx
	
	inc cl
	cmp cl, [.size]
	jne .loop

	inc byte [.cursor + 1]
	mov dx, [.cursor]
	call os_move_cursor
	
	mov cl, 0
	inc ch
	cmp ch, [.size + 1]
	jne .loop
	
	popa
	ret

	.cursor		dw 0
	.chars		db 32, 220, 223, 219
	.size		dw 0
	
; ------------------------------------------------------------------
; os_option_menu -- Show a menu with a list of options
; IN: AX = comma-separated list of strings to show (zero-terminated), BX = menu width
; OUT: AX = number (starts from 1) of entry selected; carry set if Esc, left or right pressed

os_option_menu:
	pusha

	cmp byte [57071], 0
	je .skip
	
	mov16 dx, 0, 1

	call os_move_cursor
	
	mov ah, 08h
	mov bh, 0
	int 10h				; Get the character's attribute (X = 0, Y = 1)
	
	and ah, 0F0h		; Keep only the background, set foreground to 0
	
	movzx bx, ah
	mov ax, 09B1h
	mov cx, 1840
	int 10h
	
	popa
	pusha

.skip:
	mov [.width], bx

	push ax				; Store string list for now

	call os_hide_cursor

	mov cl, 0			; Count the number of entries in the list
	mov si, ax
	
.count_loop:
	lodsb
	cmp al, 0
	je .done_count
	cmp al, ','
	jne .count_loop
	inc cl
	jmp .count_loop

.done_count:
	inc cl
	mov byte [.num_of_entries], cl


	pop si				; SI = location of option list string (pushed earlier)
	mov word [.list_string], si


	; Now that we've drawn the list, highlight the currently selected
	; entry and let the user move up and down using the cursor keys

	mov byte [.skip_num], 0		; Not skipping any lines at first showing

	mov16 dx, 25, 2			; Set up starting position for selector

	call os_move_cursor

.more_select:
	pusha
	mov bl, [57072]		; Black on white for option list box
	mov16 dx, 1, 1

	mov si, [.width]
	movzx di, [.num_of_entries]
	add di, 3
	call os_draw_block
	popa

	call .draw_black_bar

	mov word si, [.list_string]
	call .draw_list

.another_key:
	call os_wait_for_key		; Move / select option
	cmp ah, 48h			; Up pressed?
	je .go_up
	cmp ah, 50h			; Down pressed?
	je .go_down
	cmp al, 13			; Enter pressed?
	je .option_selected
	cmp al, 27			; Esc pressed?
	je .esc_pressed
	cmp ah, 75			; Left pressed?
	je .left_pressed
	cmp ah, 77			; Right pressed?
	je .right_pressed
	jmp .another_key		; If not, wait for another key


.go_up:
	cmp dh, 2			; Already at top?
	jle .hit_top

	call .draw_white_bar

	mov dl, 25
	call os_move_cursor

	dec dh				; Row to select (increasing down)
	jmp .more_select


.go_down:				; Already at bottom of list?
	mov bl, [.num_of_entries]
	inc bl
	cmp dh, bl
	je .hit_bottom

	mov cx, 0
	mov byte cl, dh

	sub cl, 6
	inc cl
	add byte cl, [.skip_num]

	mov byte al, [.num_of_entries]
	cmp cl, al
	je .another_key

	call .draw_white_bar

	mov dl, 25
	call os_move_cursor

	inc dh
	jmp .more_select


.hit_top:
	mov dh, 1
	add dh, [.num_of_entries]
	jmp .more_select


.hit_bottom:
	mov dh, 2
	jmp .more_select



.option_selected:
	call os_show_cursor

	sub dh, 2

	mov ax, 0
	mov al, dh

	inc al				; Options start from 1
	add byte al, [.skip_num]	; Add any lines skipped from scrolling

	mov word [.tmp], ax		; Store option number before restoring all other regs

	popa

	mov word ax, [.tmp]
	clc				; Clear carry as Esc wasn't pressed
	ret



.esc_pressed:
	call os_show_cursor
	popa
	mov ax, 0
	stc
	ret

.left_pressed:
	call os_show_cursor
	popa
	mov ax, 1
	stc
	ret

.right_pressed:
	call os_show_cursor
	popa
	mov ax, 2
	stc
	ret

.draw_list:
	pusha

	mov16 dx, 3, 2			; Get into position for option list text
	call os_move_cursor


	mov cx, 0			; Skip lines scrolled off the top of the dialog
	mov byte cl, [.skip_num]

.skip_loop:
	cmp cx, 0
	je .skip_loop_finished
	
.more_lodsb:
	lodsb
	cmp al, ','
	jne .more_lodsb
	dec cx
	jmp .skip_loop


.skip_loop_finished:
	mov bx, 0			; Counter for total number of options


.more:
	lodsb				; Get next character in file name, increment pointer

	cmp al, 0			; End of string?
	je .done_list

	cmp al, ','			; Next option? (String is comma-separated)
	je .newline

	mov ah, 0Eh
	int 10h
	jmp .more

.newline:
	mov dl, 3			; Go back to starting X position
	inc dh				; But jump down a line
	call os_move_cursor

	inc bx				; Update the number-of-options counter
	movzx di, [.num_of_entries]	; Low 8 bits of DI = [.items], high 8 bits = 0
	cmp bx, di			; Limit to one screen of options
	jl .more

.done_list:
	popa
	call os_move_cursor

	ret



.draw_black_bar:
	pusha

	mov dl, 2
	call os_move_cursor

	mov ax, 0920h			; Draw white bar at top
	mov cx, [.width]
	sub cx, 2
	mov bx, 00001111b		; White text on black background
	int 10h

	popa
	ret

.draw_white_bar:
	pusha

	mov dl, 2
	call os_move_cursor

	mov ax, 0920h			; Draw white bar at top
	mov cx, [.width]
	sub cx, 2
	movzx bx, byte [57072]	; Black text on white background
	int 10h

	popa
	ret

	.tmp					dw 0
	.num_of_entries			db 0
	.skip_num				db 0
	.list_string			dw 0
	.width					dw 0
	
; ==================================================================
