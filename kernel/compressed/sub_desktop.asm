; ==================================================================
; MichalOS Desktop
; ==================================================================

	%include "programs/michalos.inc"

	; Input parameters:
	; AX = 0 for displaying the login screen
	; AX = 1 for just showing the desktop
	; AX = 2 for displaying an error message that the application file is not valid

start:
	cmp ax, 1
	je checkformenu

	cmp ax, 2
	je program_error

logoinput:
	call os_get_os_name
	mov ax, si					; Set up the welcome screen
	mov bx, empty_string
	mov cx, 07h					; Colour: black
	call os_draw_background

	call os_hide_cursor

	mov dx, 9 * 256
	call os_move_cursor

	call os_draw_logo

	mov dx, 20 * 256 + 2
	call os_move_cursor

	mov si, greetingmsg
	call os_print_string

	mov si, 57036
	call os_print_string

	mov al, '!'
	call os_putchar

	mov dx, 22 * 256 + 2
	call os_move_cursor

	mov si, passwordmsg
	call os_print_string

	mov ax, 523
	mov cx, 2
	call os_speaker_note_length

	call os_wait_for_key
	
enterpressed:
	call os_show_cursor
	cmp byte [57002], 0				; Is the password disabled?
	je checkformenu				; If it is, continue

.try:	
	mov dx, 22 * 256					; Clean the text on the screen
	call os_move_cursor

	mov ax, 0920h
	mov bx, 7
	mov cx, 80
	int 10h
	
	mov dx, 22 * 256 + 2					; Ask for the password
	call os_move_cursor
	mov si, passentermsg
	call os_print_string
	
	mov ax, buffer
	mov bl, 7
	mov byte [0088h], 32
	call os_input_password
	mov byte [0088h], 255

	mov si, buffer
	call os_string_encrypt

	mov di, 57003
	call os_string_compare
	jnc .try
	
	jmp checkformenu

refresh_screen:
	call os_init_text_mode

checkformenu:
	call os_hide_cursor
	call background

checkformenuloop:	
	call os_wait_for_key
	cmp al, 32					; Space pressed?
	je option_screen		; Open the menu
	cmp al, 'a'					; a pressed?
	je load_fileman		; Open the file manager
	cmp al, 'r'					; r pressed?
	je refresh_screen		; Re-initialize the screen
	jmp checkformenuloop
	
	greetingmsg			db 'Greetings, ', 0
	passwordmsg			db 'Press any key to log in...', 0
	passentermsg		db 'Enter your password: ', 0

	os_init_msg			db 'MichalOS Desktop', 0
	os_version_msg		db '[Space] Open the main menu [A] Open the file manager [R] Reinitialize display', 0

option_screen:
	call menu_background

	mov ax, menuoptions
	call os_option_menu

	jc checkformenu
	
	cmp ax, 1
	je app_selector

	cmp ax, 2
	je game_selector
	
	cmp ax, 3
	je logoinput
	
	cmp ax, 4
	je os_reboot

	cmp ax, 5
	je os_shutdown

app_selector:
	call menu_background

	mov ax, progoptions
	call os_option_menu

	jc option_screen

	cmp ax, 1
	je load_fileman

	cmp ax, 13
	je debug_stuff
	
	mov si, ax
	sub si, 2
	shl si, 1
	add si, appindex1
	lodsw
	mov si, ax
	mov di, buffer
	call os_string_copy
	
	mov ax, buffer
	mov bx, app_prefix
	mov cx, 00F0h
	call os_string_join

	mov ax, cx
	ret
	
debug_stuff:
	call menu_background

	mov ax, debugoptions
	call os_option_menu
	
	jc app_selector
	
	mov si, ax
	dec si
	shl si, 1
	add si, debugindex1
	lodsw
	mov si, ax
	mov di, buffer
	call os_string_copy
	
	mov ax, buffer
	mov bx, app_prefix
	mov cx, 00F0h
	call os_string_join
	
	mov ax, cx
	ret
	
game_selector:
	call menu_background

	mov ax, gameoptions
	call os_option_menu

	jc option_screen

	mov si, ax
	dec si
	shl si, 1
	add si, gameindex1
	lodsw
	ret

background:
	pusha
	mov ax, os_init_msg		; Draw main screen layout
	mov bx, os_version_msg
	mov cx, 256				; Colour: white text on light blue
	call os_draw_background
	popa
	ret

menu_background:
	pusha
	cmp byte [57071], 1
	je .done
	
	call background
	
.done:
	popa
	ret
	
program_error:
	call background
	mov ax, prog_msg
	clr bx
	clr cx
	clr dx
	call os_dialog_box
	jmp checkformenu

load_fileman:
	clr ax
	ret

	appindex1				dw edit_name, viewer_name, calc_name, clock_name, cmd_name, config_name, ascii_name, pixel_name, player_name, hwcheck_name, about_name
	debugindex1				dw debug0_name, debug1_name, debug2_name, debug3_name, debug4_name, debug5_name, debug6_name, debug7_name, debug8_name, debug9_name, debug10_name, debug11_name, debug12_name, debug13_name
	gameindex1				dw cf_name, inkspill_name, spaceinv_name, asmtris_name, sudoku_name, fisher_name, miketron_name, muncher_name, hangman_name, snake_name
	
	edit_name				db 'EDIT', 0
	viewer_name				db 'VIEWER', 0
	calc_name				db 'CALC', 0
	clock_name				db 'CLOCK', 0
	cmd_name				db 'TERMINAL', 0
	config_name				db 'CONFIG', 0
	ascii_name				db 'ASCIIART', 0
	pixel_name				db 'PIXEL', 0
	player_name				db 'PLAYER', 0
	hwcheck_name			db 'HWCHECK', 0
	about_name				db 'ABOUT', 0

	debug0_name				db 'FONTEDIT', 0
	debug1_name				db 'DISKTEST', 0
	debug2_name				db 'KBDTEST', 0
	debug3_name				db 'SERIAL', 0
	debug4_name				db 'RTCTEST', 0
	debug5_name				db 'SECTOR', 0
	debug6_name				db 'MEMEDIT', 0
	debug7_name				db 'SHAPES', 0
	debug8_name				db 'DOTS', 0
	debug9_name				db 'DEADPIXL', 0
	debug10_name			db 'STARS', 0
	debug11_name			db 'CHECK', 0
	debug12_name			db 'RDTSC', 0
	debug13_name			db 'TEST', 0

	cf_name					db 'CF.BAS', 0
	inkspill_name			db 'INKSPILL.BAS', 0
	spaceinv_name			db 'SPACEINV.APP', 0
	asmtris_name			db 'ASMTRIS.APP', 0
	sudoku_name				db 'SUDOKU.APP', 0
	fisher_name				db 'FISHER.APP', 0
	miketron_name			db 'MIKETRON.BAS', 0
	muncher_name			db 'MUNCHER.BAS', 0
	hangman_name			db 'HANGMAN.APP', 0
	snake_name				db 'SNAKE.APP', 0

	empty_string			db 0
	
	app_prefix				db '.APP', 0

	menuoptions				db 'Programs,Games,Log out,Reboot,Power off', 0
	gameoptions				db 'Cosmic Flight,InkSpill,Space Inventors,aSMtris,Sudoku,Deep Sea Fisher,MikeTron,Muncher,Hangman,Snake', 0
	debugoptions			db 'Font editor,Disk detection test,Keyboard tester,Serial communication tester,RTC clock tester,Disk Sector inspector,Memory editor,Shapes test,Dots,Dead pixel tester,3D Starfield demo,Disk sector checker,TSC register tester,Simple test app', 0
	progoptions				db 'File manager,Text editor,Image viewer,Calculator,Clock,Terminal,Settings,ASCII art editor,Pixel art editor,Music player,Hardware checker,About MichalOS,Other stuff...', 0
	
	prog_msg				db 'This file is not an application!', 0

; ==================================================================
; MichalOS Shutdown routine
; ==================================================================

os_reboot:
	jmp 0FFFFh:0

os_shutdown:
	call os_clear_screen
	call os_show_cursor

	mov ax, 5300h
	xor bx, bx
	int 15h				; check if APM is present
	jc .APM_missing

	mov ax, 5304h
	xor bx, bx
	int 15h				; disconnect any previous APM interface	
	
	mov ax, 530Eh		; Set APM to version 1.2
	xor bx, bx
	mov cx, 0102h
	int 15h

	mov ax, 5301h
	xor bx, bx
	xor cx, cx
	int 15h				; open an interface with APM
	jc .APM_interface

	mov ax, 5307h
	mov bx, 1
	mov cx, 3
	int 15h				; do a power off
	
.APM_error:
	mov ax, .errormsg1
	jmp .display_error
	
.APM_missing:
	mov ax, .errormsg2
	jmp .display_error
	
.APM_interface:
	mov ax, .errormsg3
	jmp .display_error
	
.APM_pwrmgmt:
	mov ax, .errormsg4

.display_error:
	mov bx, .errormsg01
	mov cx, .errormsg02
	clr dx
	call os_dialog_box
	
	jmp os_reboot

	.errormsg1	db 'Error shutting down the computer.', 0
	.errormsg2	db 'This computer does not support APM.', 0
	.errormsg3	db 'Error communicating with APM.', 0
	.errormsg4	db 'Error enabling power management.', 0
	.errormsg01	db 'Please turn off the computer manually,', 0
	.errormsg02	db 'or press OK to reboot.', 0

buffer:
