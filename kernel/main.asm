; ------------------------------------------------------------------
; MichalOS Kernel
; ------------------------------------------------------------------

	BITS 16
	ORG 32768
	%include "include/kernel.inc"

; ------------------------------------------------------------------
; MichalOS memory map:
; Segment 0000h:
;   - 0000h - 03FFh = Interrupt vector table
;   - 0400h - 04FFh = BIOS data area
;   - 0500h - 05FFh = AdLib register buffer
;   - 0600h - 15FFh = Desktop background (BG.ASC)
;   - 1600h - 25FFh = System font (FONT.SYS)
;   - 2600h - 2DFFh = File manager (FILEMAN.APP)
;   - 2E00h - 35FFh = Disk parameter table
; Segment 0360h:
;   - 0000h - 00FFh = System variables
;      - 0000h = RET instruction
;      - 00E0h - 00EFh - parameters for an app (eg. a file to open when an app launches)
;      - 00F0h - 00FFh - temporary buffer for storing apps' filenames
;   - 0100h - 7FFFh = Application
;   - 8000h - DEA7h = MichalOS kernel
;   - DEA8h - DFFFh = Configuration file (SYSTEM.CFG)
;      - config file map described in include/constants.asm
;   - E000h - FFFFh = Disk buffer
; End of memory: 4k-64k bytes stack
; ------------------------------------------------------------------

; ------------------------------------------------------------------
; OS CALL VECTORS

os_call_vectors:
	jmp os_main
	jmp os_print_string
	jmp os_move_cursor
	jmp os_clear_screen
	jmp os_exit
	jmp os_print_newline
	jmp os_wait_for_key
	jmp os_check_for_key
	jmp os_int_to_string
	jmp os_speaker_tone
	jmp os_speaker_off
	jmp os_load_file
	jmp os_pause
	jmp os_draw_background
	jmp os_string_length
	jmp os_string_uppercase
	jmp os_string_lowercase
	jmp os_input_string
	jmp os_string_copy
	jmp os_dialog_box
	jmp os_string_join
	jmp os_get_file_list
	jmp os_string_compare
	jmp os_string_chomp
	jmp os_string_to_hex
	jmp os_adlib_regwrite
	jmp os_bcd_to_int
	jmp os_get_time_string
	jmp os_draw_logo
	jmp os_file_selector
	jmp os_get_date_string
	jmp os_send_via_serial
	jmp os_get_via_serial
	jmp os_find_char_in_string
	jmp os_get_cursor_pos
	jmp os_print_space
	jmp os_option_menu
	jmp os_print_digit
	jmp os_print_1hex
	jmp os_print_2hex
	jmp os_print_4hex
	jmp os_set_timer_speed
	jmp os_report_free_space
	jmp os_string_add
	jmp os_speaker_note_length
	jmp os_show_cursor
	jmp os_hide_cursor
	jmp os_dump_registers
	jmp os_list_dialog_tooltip
	jmp os_write_file
	jmp os_file_exists
	jmp os_create_file
	jmp os_remove_file
	jmp os_rename_file
	jmp os_get_file_size
	jmp os_input_dialog
	jmp os_list_dialog
	jmp os_string_reverse
	jmp os_string_to_int
	jmp os_draw_block
	jmp os_get_random
	jmp os_print_32int
	jmp os_serial_port_enable
	jmp os_sint_to_string
	jmp os_string_parse
	jmp os_run_basic
	jmp os_adlib_calcfreq
	jmp os_attach_app_timer
	jmp os_string_tokenize
	jmp os_clear_registers
	jmp os_format_string
	jmp os_putchar
	jmp os_start_adlib
	jmp os_return_app_timer
	jmp os_reset_font
	jmp os_print_string_box
	jmp os_put_chars
	jmp os_draw_line
	jmp os_draw_polygon
	jmp os_draw_circle
	jmp os_clear_graphics
	jmp os_get_file_datetime
	jmp os_string_encrypt
	jmp os_set_pixel
	jmp os_init_graphics_mode
	jmp os_draw_icon
	jmp os_stop_adlib
	jmp os_adlib_noteoff
	jmp os_int_1Ah
	jmp os_int_to_bcd
	jmp os_decompress_zx7
	jmp os_password_dialog
	jmp os_adlib_mute
	jmp os_draw_rectangle
	jmp os_get_memory
	jmp os_color_selector
	jmp os_modify_int_handler
	jmp os_32int_to_string
	jmp os_get_boot_disk
	jmp os_print_8hex
	jmp os_string_to_32int
	jmp os_math_power
	jmp os_math_root
	jmp os_input_password
	jmp os_get_int_handler
	jmp os_get_os_name
	jmp os_temp_box
	jmp os_adlib_unmute
	jmp os_disk_read_sector
	jmp os_init_text_mode
	jmp os_disk_write_sector
	jmp os_print_int
	jmp os_disk_read_multiple_sectors
	jmp os_speaker_raw_period
	jmp os_select_list
	jmp os_list_dialog_ex
	jmp os_disk_write_multiple_sectors
	jmp os_input_string_ex
	jmp os_file_selector_filtered
	jmp os_speaker_muted
	jmp os_string_callback_tokenizer
	jmp os_set_max_input_length

; ------------------------------------------------------------------
; START OF MAIN KERNEL CODE

os_main:
	int 12h						; Get RAM size
	dec ax						; Some BIOSes round up, so we have to sacrifice 1 kB :(
	shl ax, 6					; Convert kB to segments

	mov bx, 256					; Set up a 4 kB stack - good enough for now

	mov si, first_init_stack_done
	jmp int_set_stack

first_init_stack_done:
	mov ax, cs					; Set all segments to match where kernel is loaded
	mov ds, ax
	mov es, ax
	push word 0
	pop fs
	add ax, 1000h
	mov gs, ax
	
	mov [bootdev], dl			; Save boot device number

	mov cx, 0x8000
	clr di
	clr al
	rep stosb

	mov byte [0000h], 0xC3
;	mov byte [00E0h], 0

	; Clear the disk params table

	push es
	movs es, fs
	mov di, DISK_PARAMS
	mov al, 0FFh
	mov cx, 8 * 256
	rep stosb
	pop es

	; Load the files
	
	mov byte [CONFIG_FONT], CFG_FONT_BIOS		; If a fatal error occurs, use the default BIOS font

	push es
	movs es, fs
	
	mov ax, fileman_name
	mov cx, FILE_MANAGER
	call os_load_file
	
	jc systemfilemissing

	mov ax, bg_name
	mov cx, DESKTOP_BACKGROUND
	call os_load_file
	jnc .background_ok
	
	mov byte [DESKTOP_BACKGROUND], 0
	
.background_ok:	
	mov ax, font_name
	mov cx, SYSTEM_FONT
	call os_load_file

	jc systemfilemissing
	pop es
	
	mov ax, system_cfg			; Try to load SYSTEM.CFG
	mov cx, CONFIG_FILE
	call os_load_file

	pushf

	cli

	mov di, cs

	clr cl						; Divide by 0 error handler
	mov si, os_compat_int00
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

	sti
	
	call os_return_app_timer	; Also sets up RTC handler
	clr cx
	call os_set_timer_speed
	
	mov ax, 0305h
	mov bx, 0104h
	int 16h
	
	mov al, [CONFIG_SOUND_ENABLED]				; Copy the default sound volume (on/off)
	mov [speaker_unmuted], al
	
	popf
	jnc no_load_demotour		; If loading SYSTEM.CFG failed, it doesn't exist, so the system was started for the first time
	
	mov byte [speaker_unmuted], 1
	mov ax, demotour_name
	call load_program_file
	call run_binary_program

no_load_demotour:
	call os_init_text_mode

	int 12h						; Get RAM size
	dec ax						; Some BIOSes round up, so we have to sacrifice 1 kB :(
	shl ax, 6					; Convert kB to segments

	mov bx, [CONFIG_STACKSGMT_SIZE]				; Set up the proper stack according to the config file

	cmp bx, 256
	jb second_init_stack_done

	cmp bx, 4096
	ja second_init_stack_done

	mov si, second_init_stack_done
	jmp int_set_stack

second_init_stack_done:
	clr ax

start_desktop:
	mov si, desktop_data		; Start the desktop!
	call os_run_zx7_module

	; Possible return values: AX = 0 for starting the file manager, AX = (valid ptr) for starting an application

	test ax, ax
	jz load_fileman

launch_program:
	test ax, ax				; If an application returns a non-valid ptr, ignore it
	jz checkformenu

	pusha
	mov si, ax
	call os_string_length
	add si, ax				; SI now points to end of filename
	mov cx, 3
	sub si, cx
	mov di, app_ext
	rep cmpsb				; Are final 3 chars 'APP'?
	jne launch_basic		; If not, try 'BAS'
	popa
	
	call load_program_file
	call run_binary_program

	jmp checkformenu

launch_basic:
	popa
	pusha
	mov si, ax
	call os_string_length
	add si, ax				; SI now points to end of filename
	mov cx, 3
	sub si, cx
	mov di, bas_ext
	rep cmpsb				; Are final 3 chars 'BAS'?
	jne program_error		; If not, error out
	popa

	call load_program_file
	call os_show_cursor

	mov ax, 100h
	clr si
	call os_run_basic

	mov si, basic_finished_msg
	call os_print_string
	call os_wait_for_key

	jmp checkformenu

load_program_file:
	mov cx, 100h			; Where to load the program file
	call os_load_file		; Load filename pointed to by AX

	jc systemfilemissing

	pusha
	mov cx, 7EFDh
	sub cx, bx
	mov di, 100h
	add di, bx
	clr al
	rep stosb
	popa
	ret

return_to_app:
	mov ax, 00F0h
	mov cx, 100h			; Where to load the program file
	call os_load_file		; Load filename pointed to by AX

	jc systemfilemissing	

run_binary_program:
	; Detect binary header version
	
	cmp byte [100h], 0xC3	; Old headerless binaries
	jne start_binary

	cmp dword [101h], 'MiOS'; File magic
	jne start_binary

	; MichalOS version 1 executable was loaded

	mov cx, [106h]			; File size
	mov si, 108h

	bt word [105h], 0		; Was it compressed?
	jnc load_binary_no_compression
	jc load_binary_decompress

start_binary:
	call os_clear_screen	; Clear the screen before running
	
	mov byte [app_running], 1
	mov byte [app_exit_special], 0

	mov [origstack], sp
	
	call os_clear_registers
	
	call 100h	
	
finish:
	mov byte [app_running], 0
	
	call os_stop_adlib		; Reset everything (in case the app crashed or something)
	call os_return_app_timer
	call os_speaker_off

	sti

	pusha
	mov ax, cs
	mov ds, ax
	mov es, ax

	mov ah, 0Fh				; Get the current video mode
	int 10h
	
	cmp al, 3
	je .skip_gfx
	
	call os_init_text_mode

.skip_gfx:
	popa
	
	cmp byte [app_exit_special], 1
	je launch_program
	ret

load_binary_no_compression:
	mov di, 100h
	rep movsb
	jmp start_binary

load_binary_decompress:
	mov di, 8000h
	sub di, cx

	push di
	rep movsb
	pop si

	mov di, 100h
	call os_decompress_zx7

	jmp start_binary

program_error:
	popa
	mov ax, 2
	jmp start_desktop
	
checkformenu:
	mov ax, 1
	jmp start_desktop

load_fileman:
	push ds
	movs ds, fs
	mov si, FILE_MANAGER
	mov di, 0100h
	mov cx, 1000h
	rep movsb
	pop ds
	call run_binary_program
	jmp checkformenu

systemfilemissing:
	movs es, cs
	mov bx, noprogerror
	mov cx, 4000h
	call os_string_join

	mov ax, cx
	call os_fatal_error
	
	; And now data for the above code...

	noprogerror				db ' - System file not found', 0
	
	app_ext					db 'APP', 0
	bas_ext					db 'BAS', 0

	fileman_name			db 'FILEMAN.APP', 0
	demotour_name			db 'DEMOTOUR.APP', 0
	system_cfg				db 'SYSTEM.CFG', 0
	font_name				db 'FONT.SYS', 0
	bg_name					db 'BG.SYS', 0
	
	basic_finished_msg		db 'BASIC program ended', 0

	desktop_data incbin "sub_desktop.zx7"

; ------------------------------------------------------------------
; SYSTEM VARIABLES -- Settings for programs and system calls

	; System runtime variables
								
	origstack		dw 0		; SP before launching a program

	app_running		db 0		; Is a program running?
	
	system_ui_state	db 0		; 0 if a GUI application is running
								; 1 if a non-GUI application is running (no header/footer)

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
	%INCLUDE "features/zx7.asm"
	%INCLUDE "features/disk/lowlevel.asm"
	%INCLUDE "features/disk/cache.asm"

; ==================================================================
; END OF KERNEL
; ==================================================================

os_kernel_end:
	db 0 ; for kerneltree.py