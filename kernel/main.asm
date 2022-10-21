; ------------------------------------------------------------------
; MichalOS Kernel
; ------------------------------------------------------------------

	BITS 16
	
	ORG 32768
	
; ------------------------------------------------------------------
; MACROS
; ------------------------------------------------------------------
	
%macro clr 1
	xor %1, %1
%endmacro

%macro mov16 3
	mov %1, (%2 + %3 * 256)
%endmacro

%define ADLIB_BUFFER 0500h
%define DESKTOP_BACKGROUND 0600h
%define SYSTEM_FONT 1600h
%define FILE_MANAGER 2600h
%define disk_buffer 0E000h

; ------------------------------------------------------------------
; MichalOS memory map:
; Segment 0000h:
;   - 0000h - 03FFh = Interrupt vector table
;   - 0400h - 04FFh = BIOS data area
;   - 0500h - 05FFh = AdLib register buffer
;   - 0600h - 15FFh = Desktop background (BG.ASC)
;   - 1600h - 25FFh = System font (FONT.SYS)
;   - 2600h - 35FFh = File manager (FILEMAN.APP)
; Segment 0360h:
;   - 0000h - 00FFh = System variables
;      - 0000h = RET instruction
;      - 0001h - 0050h = Footer buffer
;      - 0051h - 0081h = File selector filter buffer
;      - 0082h = System state (byte)
;         - 0 if a GUI application is running
;         - 1 if a non-GUI application is running (no header/footer)
;      - 0083h = Sound state (byte)
;         - 0 if sound disabled
;         - 1 if sound enabled
;      - 0084h = Default boot device (byte)
;      - 0085h = Default button for os_dialog_box (0 = OK, 1 = Cancel) (byte)
;      - 0086h = int_filename_convert error status (byte)
;         - 0 if filename too long
;         - 1 if filename empty
;         - 2 if no extension found
;         - 3 if no basename found
;         - 4 if extension too short
;      - 0087h = Flag for os_file_selector input (byte)
;      - 0088h = Maximum number of characters that os_input_string can input (byte)
;      - 0089h = Width of os_list_dialog (word)
;      - 00E0h - 00EFh - parameters for an app (eg. a file to open when an app launches)
;      - 00F0h - 00FFh - temporary buffer for storing apps' filenames
;   - 0100h - 7FFEh = Application
;   - 7FFEh - Application return flag
;      - 0 = return to the desktop after an application quits
;      - 1 = launch another application (00F0h-00FFh) after an application quits
;      (example: when a user opens an app through Terminal, then terminal stores its name to 00F0h-00FFh so it starts after the requested application exits)
;   - 7FFFh - Application launch flag
;      - 0 = return to the desktop after an application quits
;      - 1 = launch another application (filename passed in AX) after an application quits
;         - Note: after launching another application this flag is set to 0
;   - 8000h - DEA7h = MichalOS kernel
;   - DEA8h - DFFFh = Configuration file (SYSTEM.CFG)
;      - described in CONFIG.ASM
;   - E000h - FFFFh = Disk buffer
; End of memory: 2048 bytes stack
; ------------------------------------------------------------------

; ------------------------------------------------------------------
; OS CALL VECTORS

os_call_vectors:
	jmp os_main					; 8000h -- Called from bootloader
	jmp os_print_string			; 8003h
	jmp os_move_cursor			; 8006h
	jmp os_clear_screen			; 8009h
	jmp os_illegal_call			; 800Ch
	jmp os_print_newline		; 800Fh
	jmp os_wait_for_key			; 8012h
	jmp os_check_for_key		; 8015h
	jmp os_int_to_string		; 8018h
	jmp os_speaker_tone			; 801Bh
	jmp os_speaker_off			; 801Eh
	jmp os_load_file			; 8021h
	jmp os_pause				; 8024h
	jmp os_fatal_error			; 8027h
	jmp os_draw_background		; 802Ah
	jmp os_string_length		; 802Dh
	jmp os_string_uppercase		; 8030h
	jmp os_string_lowercase		; 8033h
	jmp os_input_string			; 8036h
	jmp os_string_copy			; 8039h
	jmp os_dialog_box			; 803Ch
	jmp os_string_join			; 803Fh
	jmp os_get_file_list		; 8042h
	jmp os_string_compare		; 8045h
	jmp os_string_chomp			; 8048h
	jmp os_string_to_hex		; 804Bh
	jmp os_adlib_regwrite		; 804Eh
	jmp os_bcd_to_int			; 8051h
	jmp os_get_time_string		; 8054h
	jmp os_draw_logo			; 8057h
	jmp os_file_selector		; 805Ah
	jmp os_get_date_string		; 805Dh
	jmp os_send_via_serial		; 8060h
	jmp os_get_via_serial		; 8063h
	jmp os_find_char_in_string	; 8066h
	jmp os_get_cursor_pos		; 8069h
	jmp os_print_space			; 806Ch
	jmp os_option_menu			; 806Fh
	jmp os_print_digit			; 8072h
	jmp os_print_1hex			; 8075h
	jmp os_print_2hex			; 8078h
	jmp os_print_4hex			; 807Bh
	jmp os_set_timer_speed		; 807Eh
	jmp os_report_free_space	; 8081h
	jmp os_string_add			; 8084h
	jmp os_speaker_note_length	; 8087h
	jmp os_show_cursor			; 808Ah
	jmp os_hide_cursor			; 808Dh
	jmp os_dump_registers		; 8090h
	jmp os_list_dialog_tooltip	; 8093h
	jmp os_write_file			; 8096h
	jmp os_file_exists			; 8099h
	jmp os_create_file			; 809Ch
	jmp os_remove_file			; 809Fh
	jmp os_rename_file			; 80A2h
	jmp os_get_file_size		; 80A5h
	jmp os_input_dialog			; 80A8h
	jmp os_list_dialog			; 80ABh
	jmp os_string_reverse		; 80AEh
	jmp os_string_to_int		; 80B1h
	jmp os_draw_block			; 80B4h
	jmp os_get_random			; 80B7h
	jmp os_print_32int			; 80BAh
	jmp os_serial_port_enable	; 80BDh
	jmp os_sint_to_string		; 80C0h
	jmp os_string_parse			; 80C3h
	jmp os_run_basic			; 80C6h
	jmp os_adlib_calcfreq		; 80C9h
	jmp os_attach_app_timer		; 80CCh
	jmp os_string_tokenize		; 80CFh
	jmp os_clear_registers		; 80D2h
	jmp os_format_string		; 80D5h
	jmp os_putchar				; 80D8h
	jmp os_start_adlib			; 80DBh
	jmp os_return_app_timer		; 80DEh
	jmp os_reset_font			; 80E1h
	jmp os_print_string_box		; 80E4h
	jmp os_put_chars			; 80E7h
	jmp os_check_adlib			; 80EAh
	jmp os_draw_line			; 80EDh
	jmp os_draw_polygon			; 80F0h
	jmp os_draw_circle			; 80F3h
	jmp os_clear_graphics		; 80F6h
	jmp os_get_file_datetime	; 80F9h
	jmp os_string_encrypt		; 80FCh
	jmp os_put_pixel			; 80FFh
	jmp os_get_pixel			; 8102h
	jmp os_draw_icon			; 8105h
	jmp os_stop_adlib			; 8108h
	jmp os_adlib_noteoff		; 810Bh
	jmp os_int_1Ah				; 810Eh
	jmp os_int_to_bcd			; 8111h
	jmp os_decompress_zx7		; 8114h
	jmp os_password_dialog		; 8117h
	jmp os_adlib_mute			; 811Ah
	jmp os_draw_rectangle		; 811Dh
	jmp os_get_memory			; 8120h
	jmp os_color_selector		; 8123h
	jmp os_modify_int_handler	; 8126h
	jmp os_32int_to_string		; 8129h
	jmp os_print_footer			; 812Ch
	jmp os_print_8hex			; 812Fh
	jmp os_string_to_32int		; 8132h
	jmp os_math_power			; 8135h
	jmp os_math_root			; 8138h
	jmp os_input_password		; 813Bh
	jmp os_get_int_handler		; 813Eh
	jmp os_get_os_name			; 8141h ; FREE!!!!!!!!!!!!!!!!!!!
	jmp os_temp_box				; 8144h
	jmp os_adlib_unmute			; 8147h
	jmp os_read_root			; 814Ah
	jmp os_illegal_call			; 814Dh ; FREE!!!!!!!!!!!!!!!!!!!
	jmp os_illegal_call			; 8150h ; FREE!!!!!!!!!!!!!!!!!!!
	jmp os_illegal_call			; 8153h ; FREE!!!!!!!!!!!!!!!!!!!
	jmp os_convert_l2hts		; 8156h
	
; ------------------------------------------------------------------
; START OF MAIN KERNEL CODE

os_main:
	int 12h						; Get RAM size
	dec ax						; Some BIOSes round up, so we have to sacrifice 1 kB :(
	shl ax, 6					; Convert kB to segments

	cli

	sub ax, 65536 / 16			; Set the stack to the top of the memory
	mov ss, ax
	mov sp, 0FFFEh

;	xor ax, ax
;	mov ss, ax					; Set stack segment and pointer
;	mov sp, 0FFFEh

	sti

	cld							; The default direction for string operations
								; will be 'up' - incrementing address in RAM

	mov ax, cs					; Set all segments to match where kernel is loaded
	mov ds, ax			
	mov es, ax
	mov fs, [driversgmt]
	add ax, 1000h
	mov gs, ax
	
	mov byte [0000h], 0xC3
	mov [0084h], dl
	mov [bootdev], dl			; Save boot device number
	mov byte [0088h], 255
	mov word [0089h], 76
	mov byte [00E0h], 0

	mov [Sides], bx
	mov [SecsPerTrack], cx

	clr ax
	call os_serial_port_enable

	; Load the files
	
	push es
	mov es, [driversgmt]
	
	mov ax, fileman_name
	mov cx, FILE_MANAGER
	call os_load_file
	
	mov ax, bg_name
	mov cx, DESKTOP_BACKGROUND
	call os_load_file
	jnc .background_ok
	
	mov byte [DESKTOP_BACKGROUND], 0
	
.background_ok:	
	mov ax, font_name
	mov cx, SYSTEM_FONT
	call os_load_file
	
	pop es
	
	cli

	mov di, cs

	clr cl						; Divide by 0 error handler
	mov si, os_compat_int00
	call os_modify_int_handler

	mov cl, 0Ch					; Stack overflow
	mov si, os_compat_int0C
	call os_modify_int_handler

	mov cl, 05h					; Debugger
	mov si, os_compat_int05
	call os_modify_int_handler
	
	mov cl, 06h					; Bad instruction error handler
	mov si, os_compat_int06
	call os_modify_int_handler

	mov cl, 07h					; Processor extension error handler
	mov si, os_compat_int07
	call os_modify_int_handler

	mov cl, 1Ch					; RTC handler
	mov si, os_compat_int1C
	call os_modify_int_handler
	
	sti

;	int 5
	
	call os_seed_random

	mov di, 100h
	clr al
	mov cx, 7EFFh
	rep stosb

	call os_reset_font

	mov ax, 1003h				; Set text output with certain attributes
	clr bl						; to be bright, and not blinking
	int 10h
	
	mov ax, 0305h
	mov bx, 0104h
	int 16h
	
	mov byte [0082h], 0
	
	mov ax, system_cfg			; Try to load SYSTEM.CFG
	mov cx, 57000
	call os_load_file

	mov al, [57069]				; Copy the default sound volume (on/off)
	mov [0083h], al
	
	jc load_demotour			; If failed, it doesn't exist, so the system is run for the first time
	
logoinput:
	mov ax, osname				; Set up the welcome screen
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
	
	mov ax, 100h
	mov bl, 7
	mov byte [0088h], 32
	call os_input_password
	mov byte [0088h], 255

	mov si, 100h
	call os_string_encrypt

	mov di, 57003
	call os_string_compare
	jnc .try
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;end LOGO!
	
checkformenu:
	call os_hide_cursor
	call background

checkformenuloop:	
	call os_wait_for_key
	cmp al, 32					; Space pressed?
	je option_screen		; Open the menu
	cmp al, 'a'					; a pressed?
	je load_fileman		; Open the file manager
	jmp checkformenuloop
	
	greetingmsg			db 'Greetings, ', 0
	passwordmsg			db 'Press any key to log in...', 0
	passentermsg		db 'Enter your password: ', 0

	os_init_msg			db 'MichalOS Desktop', 0
	os_version_msg		db '[Space] Open the main menu [A] Open the file manager', 0

; TODO: THE FOLLOWING CODE NEEDS TO BE REWRITTEN
	
option_screen:
	call menu_background

	mov ax, menuoptions
	mov bx, 13
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
	mov bx, 20
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
	mov di, 0100h
	call os_string_copy
	
	mov ax, 0100h
	mov bx, app_prefix
	mov cx, 00F0h
	call os_string_join
	
	mov bx, cx
	jmp start_program
	
debug_stuff:
	call menu_background

	mov ax, debugoptions
	mov bx, 31
	call os_option_menu
	
	jc app_selector
	
	mov si, ax
	dec si
	shl si, 1
	add si, debugindex1
	lodsw
	mov si, ax
	mov di, 0100h
	call os_string_copy
	
	mov ax, 0100h
	mov bx, app_prefix
	mov cx, 00F0h
	call os_string_join
	
	mov bx, cx
	jmp start_program
	
	
game_selector:
	call menu_background

	mov ax, gameoptions
	mov bx, 19
	call os_option_menu

	jc option_screen

	mov si, ax
	dec si
	shl si, 1
	add si, gameindex1
	lodsw
	
launch_program:
	mov byte [32767], 0

	pusha
	mov si, ax
	mov bx, si
	mov ax, si
	call os_string_length
	mov si, bx
	add si, ax				; SI now points to end of filename...
	dec si
	dec si
	dec si					; ...and now to start of extension!
	mov di, app_ext
	mov cx, 3
	rep cmpsb				; Are final 3 chars 'APP'?
	jne launch_basic		; If not, try 'BAS'
	popa
	
	mov cx, 100h			; Where to load the program file
	call os_load_file		; Load filename pointed to by AX

	jc checkformenu
	
	pusha
	mov cx, 7EFDh
	sub cx, bx
	mov di, 100h
	add di, bx
	clr al
	rep stosb
	popa
	
	call os_show_cursor
	
	jmp execute_bin_program

launch_basic:
	popa
	
	pusha
	mov si, ax
	mov bx, si
	mov ax, si
	call os_string_length
	mov si, bx
	add si, ax				; SI now points to end of filename...
	dec si
	dec si
	dec si					; ...and now to start of extension!
	mov di, bas_ext
	mov cx, 3
	rep cmpsb				; Are final 3 chars 'BAS'?
	jne program_error		; If not, error out
	popa

	mov cx, 100h			; Where to load the program file
	call os_load_file		; Load filename pointed to by AX

	jc checkformenu
	
	pusha
	mov cx, 7EFDh
	sub cx, bx
	mov di, 100h
	add di, bx
	clr al
	rep stosb
	popa

	call os_show_cursor
	
	mov ax, 100h
	clr si
	call os_run_basic

	mov si, basic_finished_msg
	call os_print_string
	call os_wait_for_key

	call os_clear_screen
	
	mov byte [0082h], 0
	
	jmp checkformenu
	
program_error:
	popa
	call background
	mov ax, prog_msg
	clr bx
	clr cx
	clr dx
	call os_dialog_box
	jmp checkformenu
	
load_fileman:
	push ds
	mov ds, [driversgmt]
	mov si, FILE_MANAGER
	mov di, 0100h
	mov cx, 1000h
	rep movsb
	pop ds
	jmp execute_bin_program
	
load_demotour:
	mov byte [0083h], 1
	mov ax, demotour_name
	mov cx, 100h
	call os_load_file
	call os_clear_registers
	call 100h
	jmp logoinput
	
load_command:
	mov ax, cmd_name
	mov bx, app_prefix
	mov cx, 00F0h
	call os_string_join
	mov bx, cx
	jmp start_program
	
start_program:				; BX = program name
	pusha
	mov cx, 7EFDh
	mov di, 100h
	clr al
	rep stosb
	popa
	
	mov ax, bx
	mov cx, 100h			; Where to load the program file
	call os_load_file		; Load filename pointed to by AX

	jc systemfilemissing
	
	call os_show_cursor

	jmp execute_bin_program
	
return_to_app:
	mov ax, 00F0h
	mov cx, 100h			; Where to load the program file
	call os_load_file		; Load filename pointed to by AX

	jc systemfilemissing	

execute_bin_program:
	call os_clear_screen	; Clear the screen before running

	mov byte [0082h], 0
	
	mov byte [app_running], 1

	mov [origstack], sp
	
	call os_clear_registers
	
	call 100h	
	
finish:
	mov byte [app_running], 0
	
	call os_stop_adlib		; Reset everything (in case the app crashed or something)
	call os_speaker_off

	push ax
	mov ax, cs
	mov ds, ax
	mov es, ax
	pop ax
	
	pusha
	mov ah, 0Fh				; Get the current video mode
	int 10h
	
	cmp al, 3
	je .skip_gfx
	
	mov ax, 3
	int 10h

.skip_gfx:
	mov ax, 1003h			; Set text output with certain attributes
	clr bx					; to be bright, and not blinking
	int 10h

	mov byte [0082h], 0
	mov byte [0085h], 0
	
	call os_reset_font
	popa
	
	cmp byte [7FFFh], 1
	je launch_program
	
	cmp byte [7FFEh], 1
	je return_to_app
	
	jmp checkformenu		; When finished, go back to the program list

	
; TODO: THE CODE ABOVE NEEDS TO BE REWRITTEN
	
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
	
systemfilemissing:
	mov ax, noprogerror
	call os_fatal_error
	
	; And now data for the above code...

	driversgmt				dw 0000h
	
	prog_msg				db 'This file is not an application!', 0

	noprogerror				db 'System file not found', 0

	appindex1				dw edit_name, viewer_name, calc_name, clock_name, cmd_name, config_name, ascii_name, pixel_name, player_name, hwcheck_name, about_name
	debugindex1				dw debug0_name, debug1_name, debug2_name, debug3_name, debug4_name, debug5_name, debug6_name, debug7_name, debug8_name, debug9_name, debug11_name, debug12_name, debug13_name
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
	debug7_name				db 'BOXES', 0
	debug8_name				db 'DOTS', 0
	debug9_name				db 'DEADPIXL', 0
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
	
	app_prefix				db '.'
	app_ext					db 'APP', 0
	bas_ext					db 'BAS', 0

	fileman_name			db 'FILEMAN.APP', 0
	demotour_name			db 'DEMOTOUR.APP', 0
	system_cfg				db 'SYSTEM.CFG', 0
	font_name				db 'FONT.SYS', 0
	bg_name					db 'BG.SYS', 0
	
	basic_finished_msg		db 'BASIC program ended', 0

	empty_string			db 0
	
	menuoptions				db 'Programs,Games,Log out,Reboot,Power off', 0
	gameoptions				db 'Cosmic Flight,InkSpill,Space Inventors,aSMtris,Sudoku,Deep Sea Fisher,MikeTron,Muncher,Hangman,Snake', 0
	debugoptions			db 'Font editor,Disk detection test,Keyboard tester,Serial communication tester,RTC clock tester,Disk Sector inspector,Memory editor,Boxes,Dots,Dead pixel tester,Disk sector checker,TSC register tester,Simple test app', 0
	progoptions				db 'File manager,Text editor,Image viewer,Calculator,Clock,Terminal,Settings,ASCII art editor,Pixel art editor,Music player,Hardware checker,About MichalOS,Other stuff...', 0
	
; ------------------------------------------------------------------
; SYSTEM VARIABLES -- Settings for programs and system calls

	; System runtime variables
								
	origstack		dw 0		; SP before launching a program

	app_running		db 0		; Is a program running?
	
;	program_drawn	db 0		; Is the program already drawn by os_draw_background?
	
; ------------------------------------------------------------------
; FEATURES -- Code to pull into the kernel

	%INCLUDE "features/icons.asm"
 	%INCLUDE "features/disk.asm"
	%INCLUDE "features/keyboard.asm"
	%INCLUDE "features/math.asm"
	%INCLUDE "features/misc.asm"
	%INCLUDE "features/ports.asm"
	%INCLUDE "features/screen.asm"
	%INCLUDE "features/sound.asm"
	%INCLUDE "features/string.asm"
	%INCLUDE "features/basic.asm"
	%INCLUDE "features/int.asm"
	%INCLUDE "features/graphics.asm"
	%INCLUDE "features/shutdown.asm"
	%INCLUDE "features/zx7.asm"

; ==================================================================
; END OF KERNEL
; ==================================================================

os_kernel_end:
	db 0 ; for kerneltree.py