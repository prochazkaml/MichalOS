; ------------------------------------------------------------------
; MichalOS Demo tour & initial setup
; ------------------------------------------------------------------

	%INCLUDE "michalos.inc"

os_demotour:
	mov si, .test_data_bgcolor
	mov di, 57000
	mov cx, .test_data_end - .test_data_bgcolor
	rep movsb

	clr cx
	call .draw_background

	mov si, .box0msg1
	mov ax, .box0msg2
	mov bx, .box0msg3
	mov cx, .box0msg4
	clr dx
	call os_temp_box
	
	call os_wait_for_key
	
	cmp al, 'a'
	je near .setup
	
	cmp al, 'b'
	je near .tutorial
	
	cmp al, 'p'
	je near .skip
	
	jmp os_demotour
	
.skip:
	mov si, .test_data_bgcolor
	mov di, 57000
	mov cx, .test_data_end - .test_data_bgcolor
	rep movsb
	
	call .update_config
	jmp .exit
	
.tutorial:
	mov cx, 1
	call .draw_background

	mov16 dx, 0, 2
	call os_move_cursor
	mov si, .t0l0
	call os_print_string

	mov16 dx, 0, 22
	call os_move_cursor
	mov si, .continue
	call os_print_string
	call os_wait_for_key

	mov cx, 1
	call .draw_background
	
	mov16 dx, 0, 2
	call os_move_cursor
	mov si, .tsl0
	call os_print_string

	mov16 dx, 0, 22
	call os_move_cursor
	mov si, .continue
	call os_print_string
	call os_wait_for_key
	
	mov cx, 2
	call .draw_background
	mov ax, .t1l0
	mov bx, .t1l1
	clr cx
	clr dx
	call os_dialog_box
	
	mov cx, 3
	call .draw_background
	mov ax, .t2l0
	mov bx, .t2l1
	mov cx, .t2l2
	mov dx, 1
	call os_dialog_box

	cmp ax, 1
	je near .cancel_pressed
	
.ok_pressed:
	mov ax, .t2cancel
	clr bx
	clr cx
	mov dx, 1
	call os_dialog_box
	
	cmp ax, 0
	je near .ok_pressed
	jmp .pressed
	
.cancel_pressed:
	mov ax, .t2ok
	clr bx
	clr cx
	mov dx, 1
	call os_dialog_box
	
	cmp ax, 1
	je near .cancel_pressed
	
.pressed:
	mov cx, 4
	call .draw_background
	mov ax, .t3l0
	mov bx, .t3l1
	mov cx, .t3l2
	clr dx
	call os_dialog_box
	
	mov cx, 4
	call .draw_background
	call .reset_name
	call .change_name
	
	mov ax, .t3output1
	mov bx, 57036
	mov cx, 4096
	call os_string_join
	mov ax, cx
	mov bx, .t3output2
	call os_string_join
	push cx
	
	mov cx, 4
	call .draw_background
	pop ax
	clr bx
	clr cx
	clr dx
	call os_dialog_box
	
	mov cx, 5
	call .draw_background
	mov ax, .t4list
	mov bx, .t4l0
	mov cx, .t4l1
	call list_dialog
	
	mov cx, 6
	call .draw_background

	mov ax, .t5l0
	mov bx, .t5l1
	clr cx
	clr dx
	call os_dialog_box
	
	mov cx, 6
	call .draw_background

	call .change_sound

	jmp .setup_password
	
.setup:
	call os_show_cursor
	mov cx, 6
	call .draw_background

	call .change_sound

	mov cx, 7
	call .draw_background

	call .change_name

.setup_password:
	mov cx, 8
	call .draw_background
	
	call .disable_password
	
	mov ax, .enablepass_msg1
	clr bx
	clr cx
	mov dx, 1
	call os_dialog_box
	
	cmp ax, 1
	je .setup_done
	
	call .set_password
	
.setup_done:
	call .update_config

	mov cx, 9
	call .draw_background
	
	mov ax, .t6l0
	mov bx, .t6l1
	mov cx, .t6l2
	mov dx, 0
	call os_dialog_box
	
	jmp .exit
	
;------------------------------------------

.change_sound:
	mov ax, .adlib_list
	mov bx, .adlib_msg
	mov cx, .adlib_msg2
	call os_list_dialog
	
	jc .err
	
	dec al
	mov [57070], al

.err:
	ret
	

.change_name:
	call .reset_name
	mov ax, 57036
	mov bx, .name_msg
	mov byte [0088h], 32
	call os_input_dialog
	mov byte [0088h], 255
	ret
	
.disable_password:
	mov al, 0
	mov [57002], al
	ret
	
.set_password:
	mov al, 1
	mov [57002], al
	call .reset_password
	mov ax, 57003
	mov bx, .password_msg
	mov byte [0088h], 32
	call os_password_dialog
	mov byte [0088h], 255
	
	mov si, 57003
	call os_string_encrypt
	ret
	
.exit:
	call os_clear_screen
	ret

.reset_password:
	mov di, 57003	
	mov al, 0
.reset_password_loop:
	stosb
	cmp di, 57036
	jl .reset_password_loop
	ret

.reset_name:
	mov di, 57036	
	mov al, 0
.reset_name_loop:
	stosb
	cmp di, 57069
	jl .reset_name_loop
	ret

.draw_background:
	pusha
	mov ax, .title_msg
	mov bx, .footer_msg
	mov cx, 7
	call os_draw_background
	popa
	pusha
	call .draw_side
	popa
	ret

.update_config:
	mov ax, .config_name
	mov bx, 57000
	mov cx, 83				; SYSTEM.CFG file size
	call os_write_file
	jc .write_error
	mov ax, .donemsg1
	mov bx, .donemsg2
	mov cx, .donemsg3
	mov dx, 0
	call os_dialog_box
	ret
	
.write_error:
	mov ax, .errmsg1
	mov bx, .errmsg2
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	ret
	
.draw_side:
	pusha
	mov dh, 1
	mov dl, 70
	mov si, .list0
	add cx, 1
	
.draw_data:
	call os_move_cursor
	cmp dh, 11
	je near .draw_end
	cmp cl, dh
	
	jg .gray
	je .white
	jl .black
	
.gray:
	mov bl, 10001111b
	call os_format_string
	inc dh
	add si, 11
	jmp .draw_data
	
.white:
	mov bl, 11110000b
	call os_format_string
	inc dh
	add si, 11
	jmp .draw_data
	
.black:
	mov bl, 00000111b
	call os_format_string
	inc dh
	add si, 11
	jmp .draw_data
	
.draw_end:
	popa
	ret
	
	.changedone			db 'Changes have been saved.', 0
		
	.box0msg1			db 'Thanks for trying out MichalOS!', 0
	.box0msg2			db 'If you are unfamiliar with the system,', 0
	.box0msg3			db 'press B to start the tutorial. Otherwise', 0
	.box0msg4			db 'press A to skip straight to the setup.', 0
	
	.t0l0				db ' Welcome to MichalOS!', 13, 10
						db 10
						db ' MichalOS was designed to be a quick, efficient and easy-to-use', 13, 10
						db ' keyboard controlled operating system.', 13, 10
						db 10
						db ' Now you will be taught how to use this system. It is quite easy', 13, 10
						db ' to understand, because the UI mainly consists of these 4 elements:', 13, 10
						db '  ', 1Ah, ' an information dialog', 13, 10
						db '  ', 1Ah, ' a 2-button dialog', 13, 10
						db '  ', 1Ah, ' a text input dialog', 13, 10
						db '  ', 1Ah, ' a list dialog', 13, 10
						db 10
						db ' This operating system is mainly controlled by these keys:', 13, 10
						db 32, 32, 17, ' ', 16, ': Move the cursor (left/right)', 13, 10
						db 32, 32, 30, ' ', 31, ': Move the cursor (up/down)', 13, 10
						db '  Enter: Select/Choose', 13, 10
						db '  Esc: Go back/Quit', 13, 10
						db 10
						db ' If an application uses any other keys, they will be shown in the bottom panel.', 0
	
	.tsl0				db ' In MichalOS, there also are some handy shortcuts, which can be', 13, 10
						db ' used by holding down the Alt key and pressing a function key:', 13, 10
						db 10
						db '  ', 1Ah, ' Alt + F2: Mute the PC speaker', 13, 10
						db '  ', 1Ah, ' Alt + F3: Unmute the PC speaker', 13, 10
						db '  ', 1Ah, ' Alt + F4: Force-quit the application', 13, 10, 0
	
	.t1l0				db 'This is an information dialog.', 0
	.t1l1				db 'To close it, press Enter.', 0
	
	.t2l0				db 'This is a 2-button dialog.', 0
	.t2l1				db 'Choose a button with the arrow keys,', 0
	.t2l2				db 'and then press Enter.', 0
	
	.t2cancel			db 'Now try to choose Cancel.', 0
	.t2ok				db 'Now try to choose OK.', 0
	
	.t3l0				db 'Now you will see a text input dialog.', 0
	.t3l1				db 'When you see it, type what it wants', 0
	.t3l2				db 'and then press Enter.', 0
	
	.t3output1			db 'Greetings, ', 0
	.t3output2			db '!', 0

	.t4l0				db 'This is a list dialog. Choose an option with the arrow keys', 0
	.t4l1				db 'and use the Enter key to select it. The Tab key returns to the top.', 0
	.t4list				db "1. Choose me!+2. No, choose me!+3. It doesn't matter...+4. I'm also an option!", 0
	
	.t5l0				db 'Now we will have to go through some', 0
	.t5l1				db 'basic setup.', 0
	
	.t6l0				db 'MichalOS Setup has finished.', 0
	.t6l1				db 'We hope that you will enjoy using this', 0
	.t6l2				db 'system.', 0
	
	.list0				db ' Start    ', 0
	.list1				db ' Intro    ', 0
	.list2				db ' Win. #1  ', 0
	.list3				db ' Win. #2  ', 0
	.list4				db ' Win. #3  ', 0
	.list5				db ' Win. #4  ', 0
	.list6				db ' Sound    ', 0
	.list7				db ' Name     ', 0
	.list8				db ' Password ', 0
	.list9				db ' The end  ', 0
	
	.continue			db ' Press any key to continue...', 0
	
	.enablepass_msg1	db 'Do you wish to set up a password?', 0
	
	.adlib_msg			db 'Some applications may want to play multi-channel music.', 0
	.adlib_msg2			db 'Which sound device would you want to use?', 0
	
	.adlib_list			db 'Standard Adlib card (ports 0x388-0x389),9-voice PC speaker square wave generator (PWM),9-voice PC speaker square wave generator (PWM - max volume)', 0

	.password_msg		db 'Enter a new password (32 chars max.):', 0
	.name_msg			db 'Please enter your name (32 chars max.):', 0
	
	.donemsg1			db 'Changes have been saved.', 0
	.donemsg2			db 'If you wish to change anything, choose', 0
	.donemsg3			db 'the Settings app from the main menu.', 0
	
	.errmsg1			db 'Error writing to the disk!', 0
	.errmsg2			db 'Make sure it is not read only!', 0
	
	.title_msg			db 'MichalOS Demo tour & Initial setup', 0
	.footer_msg			db 0

	.config_name		db 'SYSTEM.CFG', 0

	.test_data_bgcolor	db 9Fh
	.test_data_wincolor	db 4Fh
	.test_pass_enabled	db 0
	.test_pass_data		times 33 db 0
	.test_username		db 'Test'
	.test_usernamepad	times 33 - 4 db 0
	.test_sndenable		db 1
	.test_adlibdrv		db 0
	.test_menudim		db 1
	.test_menucolor		db 0F0h
	.test_dosfont		db 0
	.test_scrnsave		db 3
	.test_blank			times 6 db 0
	.test_minute_offset	dw 0
	
	.test_data_end:
	
list_dialog:
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
	cmp al, '+'
	jne .count_loop
	inc cl
	jmp .count_loop

.done_count:
	inc cl
	mov byte [.num_of_entries], cl


	mov bl, [57001]		; Color from RAM
	mov dl, 2			; Start X position
	mov dh, 2			; Start Y position
	mov si, 76			; Width
	mov di, 23			; Finish Y position
	call os_draw_block		; Draw option selector window

	mov dl, 3			; Show first line of help text...
	mov dh, 3
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

	mov dl, 25			; Set up starting position for selector
	mov dh, 6

	call os_move_cursor

.more_select:
	pusha
	mov bl, 11110000b		; Black on white for option list box
	mov dl, 3
	mov dh, 5
	mov si, 74
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

	mov cx, 0
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
	mov cx, 0
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
	stc				; Set carry for Esc
	ret



.draw_list:
	pusha

	mov dl, 5			; Get into position for option list text
	mov dh, 6
	call os_move_cursor


	mov cx, 0			; Skip lines scrolled off the top of the dialog
	mov byte cl, [.skip_num]

.skip_loop:
	cmp cx, 0
	je .skip_loop_finished
.more_lodsb:
	mov al, [es:si]
	inc si
	cmp al, '+'
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

	cmp al, '+'			; Next option? (String is comma-separated)
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
	mov dl, 5
	mov dh, 22
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
	
	popa
	ret



.draw_black_bar:
	pusha

	mov dl, 4
	call os_move_cursor

	mov ah, 09h			; Draw white bar at top
	mov bh, 0
	mov cx, 72
	mov bl, 00001111b		; White text on black background
	mov al, ' '
	int 10h

	popa
	ret



.draw_white_bar:
	pusha

	mov dl, 4
	call os_move_cursor

	mov ah, 09h			; Draw white bar at top
	mov bh, 0
	mov cx, 72
	mov bl, 11110000b		; Black text on white background
	mov al, ' '
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
