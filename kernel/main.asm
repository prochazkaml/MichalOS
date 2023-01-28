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
;      - 0083h = Sound state (byte)
;         - 0 if sound disabled
;         - 1 if sound enabled
;      - 0088h = Maximum number of characters that os_input_string can input (byte)
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
	jmp os_main					; 8000h -- Called from bootloader
	jmp os_print_string			; 8003h
	jmp os_move_cursor			; 8006h
	jmp os_clear_screen			; 8009h
	jmp os_exit					; 800Ch
	jmp os_print_newline		; 800Fh
	jmp os_wait_for_key			; 8012h
	jmp os_check_for_key		; 8015h
	jmp os_int_to_string		; 8018h
	jmp os_speaker_tone			; 801Bh
	jmp os_speaker_off			; 801Eh
	jmp os_load_file			; 8021h
	jmp os_pause				; 8024h
	jmp os_illegal_call			; 8027h ; FREE!!!!!!!!!!!!
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
	jmp os_illegal_call			; 80EAh ; FREE!!!!!!!!!!!
	jmp os_draw_line			; 80EDh
	jmp os_draw_polygon			; 80F0h
	jmp os_draw_circle			; 80F3h
	jmp os_clear_graphics		; 80F6h
	jmp os_get_file_datetime	; 80F9h
	jmp os_string_encrypt		; 80FCh
	jmp os_set_pixel			; 80FFh
	jmp os_init_graphics_mode	; 8102h
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
	jmp os_get_boot_disk		; 812Ch
	jmp os_print_8hex			; 812Fh
	jmp os_string_to_32int		; 8132h
	jmp os_math_power			; 8135h
	jmp os_math_root			; 8138h
	jmp os_input_password		; 813Bh
	jmp os_get_int_handler		; 813Eh
	jmp os_get_os_name			; 8141h
	jmp os_temp_box				; 8144h
	jmp os_adlib_unmute			; 8147h
	jmp os_disk_read_sector		; 814Ah
	jmp os_init_text_mode		; 814Dh
	jmp os_disk_write_sector	; 8150h
	jmp os_print_int			; 8153h
	jmp os_disk_read_multiple_sectors	; 8156h
	jmp os_speaker_raw_period	; 8159h
	jmp os_select_list			; 815Ch
	jmp os_list_dialog_ex		; 815Fh
	jmp os_disk_write_multiple_sectors	; 8162h
	jmp os_input_string_ex		; 8165h
	jmp os_file_selector_filtered	; 8168h

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
	mov fs, [driversgmt]
	add ax, 1000h
	mov gs, ax
	
	mov [bootdev], dl			; Save boot device number

	mov cx, 0x8000
	clr di
	clr al
	rep stosb

	mov byte [0000h], 0xC3
	mov byte [0088h], 255
;	mov byte [00E0h], 0

	; Clear the disk params table

	push es
	mov es, [driversgmt]
	mov di, DISK_PARAMS
	mov al, 0FFh
	mov cx, 8 * 256
	rep stosb
	pop es

	; Load the files
	
	mov byte [CONFIG_FONT], CFG_FONT_BIOS		; If a fatal error occurs, use the default BIOS font

	push es
	mov es, [driversgmt]
	
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
	
	mov byte [CONFIG_FONT], CFG_FONT_MICHALOS	; Our custom font has loaded, so use it

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
	
	call os_init_text_mode
	call os_return_app_timer	; Also sets up RTC handler
	clr cx
	call os_set_timer_speed
	
	mov ax, 0305h
	mov bx, 0104h
	int 16h
	
	mov ax, system_cfg			; Try to load SYSTEM.CFG
	mov cx, CONFIG_FILE
	call os_load_file

	mov al, [CONFIG_SOUND_ENABLED]				; Copy the default sound volume (on/off)
	mov [0083h], al
	
	jnc no_load_demotour		; If failed, it doesn't exist, so the system is run for the first time
	
	mov byte [0083h], 1
	mov ax, demotour_name
	call load_program_file
	call run_binary_program

no_load_demotour:
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
	mov ds, [driversgmt]
	mov si, FILE_MANAGER
	mov di, 0100h
	mov cx, 1000h
	rep movsb
	pop ds
	call run_binary_program
	jmp checkformenu

systemfilemissing:
	push cs
	pop es

	mov bx, noprogerror
	mov cx, 4000h
	call os_string_join

	mov ax, cx
	call os_fatal_error
	
	; And now data for the above code...

	driversgmt				dw 0000h
	
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