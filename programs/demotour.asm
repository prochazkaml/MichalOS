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
	je .setup
	
	cmp al, 'b'
	je .tutorial
	
	cmp al, 'p'
	je .skip
	
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
	je .cancel_pressed
	
.ok_pressed:
	mov ax, .t2cancel
	clr bx
	clr cx
	mov dx, 1
	call os_dialog_box
	
	test ax, ax
	jz .ok_pressed
	jmp .pressed
	
.cancel_pressed:
	mov ax, .t2ok
	clr bx
	clr cx
	mov dx, 1
	call os_dialog_box
	
	cmp ax, 1
	je .cancel_pressed
	
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
	call os_list_dialog
	
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
	clr dx
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
	clr al
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
	clr al
.reset_password_loop:
	stosb
	cmp di, 57036
	jl .reset_password_loop
	ret

.reset_name:
	mov di, 57036	
	clr al
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
	clr dx
	call os_dialog_box
	ret
	
.write_error:
	mov ax, .errmsg1
	mov bx, .errmsg2
	clr cx
	clr dx
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
	je .draw_end
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
		
	.box0msg1			db 'Thank you for trying out MichalOS!', 0
	.box0msg2			db 'If you are not familiar with the system,', 0
	.box0msg3			db 'press B to start the tutorial. Otherwise', 0
	.box0msg4			db 'press A to skip straight to the setup.', 0
	
	.t0l0				db ' Welcome to MichalOS!', 13, 10
						db 10
						db ' MichalOS was designed to be a quick, efficient and easy-to-use', 13, 10
						db ' keyboard controlled operating system.', 13, 10
						db 10
						db ' Now, you will be taught how to use this system. It is quite easy', 13, 10
						db ' to understand, as the UI mainly consists of these 4 elements:', 13, 10
						db '  ', 1Ah, ' an information dialog', 13, 10
						db '  ', 1Ah, ' a 2-button dialog', 13, 10
						db '  ', 1Ah, ' a text input dialog', 13, 10
						db '  ', 1Ah, ' a list dialog', 13, 10
						db 10
						db ' The UI of MichalOS is mainly controlled with the following keys:', 13, 10
						db 32, 32, 17, ' ', 16, ': Move the cursor (left/right)', 13, 10
						db 32, 32, 30, ' ', 31, ': Move the cursor (up/down)', 13, 10
						db '  Enter: Select/Choose', 13, 10
						db '  Esc: Go back/Quit', 13, 10
						db 10
						db ' If an application uses any other keys, they will be shown in the bottom panel.', 0
	
	.tsl0				db ' Throughout the entire OS, you may also use the following shortcuts, which can', 13, 10
						db ' be used by holding down the Alt key and then pressing a function key:', 13, 10
						db 10
						db '  ', 1Ah, ' Alt + F2: Mute the PC speaker', 13, 10
						db '  ', 1Ah, ' Alt + F3: Unmute the PC speaker', 13, 10
						db '  ', 1Ah, ' Alt + F4: Force-quit the application', 13, 10, 0
	
	.t1l0				db 'This is an information dialog.', 0
	.t1l1				db 'To close it, press Enter.', 0
	
	.t2l0				db 'This is a 2-button dialog.', 0
	.t2l1				db 'Choose a button with the arrow keys,', 0
	.t2l2				db 'and then press Enter to confirm.', 0
	
	.t2cancel			db 'Now try to choose Cancel.', 0
	.t2ok				db 'Now try to choose OK.', 0
	
	.t3l0				db 'You will now see a text input dialog.', 0
	.t3l1				db 'When you see it, type what it asks', 0
	.t3l2				db 'you to and then press Enter.', 0
	
	.t3output1			db 'Greetings, ', 0
	.t3output2			db '!', 0

	.t4l0				db 'This is a list dialog. Choose an option with the arrow keys and press', 0
	.t4l1				db 'Enter to select it. You may also navigate with Home, End, PgUp and PgDn.', 0
	.t4list				db "1. Choose me!,2. No - choose me!,3. It doesn't matter...,4. I'm also an option!", 0
	
	.t5l0				db 'We will now have to go through some', 0
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
	.test_username		db 'Test user'
	.test_usernamepad	times 33 - 9 db 0
	.test_sndenable		db 1
	.test_adlibdrv		db 0
	.test_menudim		db 1
	.test_menucolor		db 0F0h
	.test_dosfont		db 0
	.test_scrnsave		db 3
	.test_blank			times 6 db 0
	.test_minute_offset	dw 0
	
	.test_data_end:
	
