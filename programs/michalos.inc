; ------------------------------------------------------------------
; Include file for MichalOS program development
; ------------------------------------------------------------------

	BITS 16
	ORG 100h
	
DISK_BUFFER		equ 0E000h
CONFIG_FILE		equ 57000

; ------------------------------------------------------------------
; IMPORTANT LOCATIONS

os_main			equ	8000h	; Where the OS code starts

; ------------------------------------------------------------------
; COLOURS (eg for os_draw_background and os_draw_block)

%DEFINE BLACK_ON_WHITE		11110000b
%DEFINE WHITE_ON_BLACK		00001111b

; ------------------------------------------------------------------
; KEYS

%DEFINE KEY_UP		72
%DEFINE KEY_DOWN	80
%DEFINE KEY_LEFT	75
%DEFINE KEY_RIGHT	77

%DEFINE KEY_ESC		27
%DEFINE KEY_ENTER	13

; ------------------------------------------------------------------
; SYSTEM CALLS

%macro syscall 1
	mov bp, %1
	call os_syscall
%endmacro

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

; Screen control

os_clear_screen			equ	8009h	; (Nothing used)
os_print_string			equ	8003h	; IN: SI = zero-terminated string location
os_move_cursor			equ	8006h	; IN: DH/DL = row/column
os_print_horiz_line		equ	800Ch	; IN: AX = 1 for double line, else single
os_print_newline		equ	800Fh	; (Nothing used)
os_draw_background		equ	802Ah	; IN: AX, BX = strings, CX = colour
os_draw_block			equ	80B4h	; IN: BL = colour, DH/DL/SI/DI = pos
os_input_dialog			equ	80A8h	; IN: AX = location, BX = msg string
os_dialog_box			equ	803Ch	; IN: AX, BX, CX = strings, DX = type	OUT: AX = 0 for OK, 1 for cancel (only multi choice for DX = 1)
os_list_dialog			equ	80ABh	; IN: AX = comma-separated list of		OUT: AX = number (starting from 1), CF set if Esc pressed
									; options, BX, CX = help to display at
									; top of list
os_file_selector		equ	805Ah	;										OUT: Returns filename in AX
os_get_cursor_pos		equ	8069h	;										OUT: DH = row, DL = column
os_print_space			equ	806Ch	; (Nothing used)
os_print_digit			equ	8072h	; IN: AX = digit to print
os_print_1hex			equ	8075h	; IN: Display low nibble of AL in hex
os_print_2hex			equ	8078h	; IN: Display AL in hex
os_print_4hex			equ	807Bh	; IN: Display AX in hex
os_show_cursor			equ	808Ah	; (Nothing used)
os_hide_cursor			equ	808Dh	; (Nothing used)
os_dump_registers		equ	8090h	; IN: EAX, EBX, ECX, EDX, ESI, EDI
os_color_selector		equ 8123h	; 										OUT: AL = color number (0-15)
os_print_footer			equ 812Ch	; IN: SI = string (or 0 to restore the previous footer)
os_print_8hex			equ 812Fh	; IN: Display EAX in hex
os_format_string		equ 80D5h	; IN: SI = string, BL = color
os_input_password		equ 813Bh	; IN: AX = location, BL = color
os_temp_box				equ 8144h	; IN: SI/AX/BX/CX/DX = strings (0 for no display)
os_password_dialog		equ 8117h	; IN: AX = location, BX = help string
os_reset_font			equ 80E1h	; (Nothing used)
os_option_menu			equ 806Fh	; IN: AX = comma-separated list,		OUT: AX = number (starting from 1)
									; BX = width
os_draw_icon			equ 8105h
os_putchar				equ 80D8h
os_list_dialog_tooltip	equ 8093h
os_print_string_box		equ 80E4h
os_put_chars			equ 80E7h

; Keyboard handling

os_wait_for_key			equ	8012h	;										OUT: AL = key pressed
os_check_for_key		equ	8015h	;										OUT: AL = key pressed

; File handling

os_get_file_list		equ	8042h	; IN: AX = string to store filenames
os_load_file			equ	8021h	; IN: AX = filename, CX = location		OUT: BX = file size in bytes, CF clear if OK, set if error
os_write_file			equ	8096h	; IN: AX = filename, BX = location, CX = number of bytes to save
os_file_exists			equ	8099h	; IN: AX = filename						OUT: CF clear if exists
os_create_file			equ	809Ch	; IN: AX = filename
os_remove_file			equ	809Fh	; IN: AX = filename
os_rename_file			equ	80A2h	; IN: AX = filename, BX = new filename
os_get_file_size		equ	80A5h	; IN: AX = filename						OUT: EBX = bytes (4G max)
os_read_root			equ 814Ah	; IN: SI = where to put the directory	OUT: CF set if error
os_disk_l2hts			equ 8156h	; IN: AX = logical sector				OUT: correct registers for int 13h
os_report_free_space	equ 8081h	;										OUT: AX = number of free sectors
os_get_file_datetime	equ 80F9h

; Sound

os_speaker_tone			equ	801Bh	; IN: AX = note frequency
os_speaker_off			equ	801Eh	; (Nothing used)
os_speaker_note_length	equ 8087h
os_start_adlib			equ 80DBh
os_stop_adlib			equ 8108h
os_adlib_regwrite		equ 804Eh
os_adlib_calcfreq		equ 80C9h
os_adlib_mute			equ 811Ah
os_adlib_unmute			equ 8147h
os_check_adlib			equ 80EAh
os_adlib_noteoff		equ 810Bh

; String handling

os_int_to_string		equ	8018h	; IN: AX = unsigned integer				OUT: AX = string
os_sint_to_string		equ	80C0h	; IN: AX = signed integer				OUT: AX = string
os_string_reverse		equ	80AEh	; IN: SI = string location
os_string_length		equ	802Dh	; IN: AX = string loc					OUT: AX = length
os_string_uppercase		equ	8030h	; IN: AX = zero-terminated string
os_string_lowercase		equ	8033h	; IN: AX = zero-terminated string
os_input_string			equ	8036h	; IN: AX = string location
os_string_copy			equ	8039h	; IN: SI = source, DI = dest strings
os_string_join			equ	803Fh	; IN: AX, BX = source strings, CX = dest
os_string_compare		equ	8045h	; IN: SI, DI = strings, carry set if same
os_string_chomp			equ	8048h	; IN: AX = string location
os_get_time_string		equ	8054h	; IN: BX = string location for eg '20:41'
os_get_date_string		equ	805Dh	; IN: BX = string location for eg '12/31/2007'
os_find_char_in_string	equ	8066h	; IN: SI = string, AL = char to find
os_string_to_int		equ	80B1h	; IN: SI = string (up to 65535)			OUT: AX = int
os_string_parse			equ	80C3h	; IN: SI = string						OUT: AX/BX/CX/DX = substrings (or 0 if not present)
os_string_tokenize		equ	80CFh	; IN: SI = string, AL = sep char		OUT: DI = next token
os_32int_to_string		equ 8129h	; IN: EAX = unsigned integer			OUT: AX = string
os_string_to_32int		equ 8132h	; IN: SI = string						OUT: EAX = integer
os_string_to_hex		equ 804Bh	; IN: SI = string (hex formatted)		OUT: EAX = integer
os_string_add			equ 8084h	; IN: AX/BX = Main string/Added string
os_print_32int			equ 80BAh	; IN: EAX = unsigned integer
os_string_encrypt		equ 80FCh

; Math routines

os_get_random			equ	80B7h	; IN: AX, BX = low, high				OUT: CX = num
os_bcd_to_int			equ	8051h	; IN: AL = BCD number					OUT: AX = integer
os_math_power			equ 8135h	; IN: EAX, EBX = numbers				OUT: EAX = EAX ^ EBX
os_math_root			equ 8138h	; IN: EAX = number, EBX = root			OUT: EAX (EDX = 0) = result, EAX-EDX = range
os_int_to_bcd			equ 8111h

; Ports

os_serial_port_enable	equ	80BDh	; IN: AX = 0 for 9600 baud, 1 for 1200
os_send_via_serial		equ	8060h	; IN: AL = byte to send
os_get_via_serial		equ	8063h	;										OUT: AL = byte received

; Misc OS functions

os_run_basic			equ	80C6h	; IN: AX = code location in RAM, BX = size, SI = parameter string (or 0 if none)
os_pause				equ	8024h	; IN: AX = 1/18.2 of second to wait
os_clear_registers		equ 80E2h	;										OUT: all registers clear
os_fatal_error			equ	8027h	; IN: AX = error string location
os_get_memory			equ 8120h	;										OUT: AX = conventional memory (kB), BX = extended memory (kB)
os_get_int_handler		equ 813Eh	; IN: CL = int number					OUT: DI:SI = code location
os_draw_logo			equ 8057h	;										OUT: A very beautiful logo
os_modify_int_handler	equ 8126h	; IN: CL = int number, DI:SI = code location
os_update_clock			equ 80E4h	; (Nothing used)
os_crash_application	equ 80E7h	; (Nothing used)
os_attach_app_timer		equ 80CCh
os_return_app_timer		equ 80DEh
os_int_1Ah				equ 810Eh
os_set_timer_speed		equ 807Eh

; Graphics functions

os_put_pixel			equ 80FFh	; IN: AL = color, BH = page, CX = X res, DX = Y res
os_get_pixel			equ 8102h	; IN: BH = page, CX = X res, DX = Y res	OUT: AL = color
os_draw_rectangle		equ 811Dh	; IN: CX/DX/SI/DI = X1/Y1/X2/Y2, BL = color, CF = set if filled
os_draw_line			equ 80EDh
os_draw_polygon			equ 80F0h
os_draw_circle			equ 80F3h
os_clear_graphics		equ 80F6h

; Mouse functions

os_mouse_locate			equ 8159h	;										OUT: CX = Mouse X, DX = Mouse Y
os_mouse_move			equ 815Ch	; IN: CX = Mouse X, DX = Mouse Y
os_mouse_range			equ 8165h	; IN: AX/BX/CX/DX = X1/Y1/X2/Y2
os_mouse_wait			equ 8168h	; (Nothing used)
os_mouse_anyclick		equ 816Bh	;										OUT: CF set if any button is pressed, AL = button data - bitfield
os_mouse_scale			equ 8177h	; IN: DL/DH = mouse X/Y scale
os_mouse_reset_scroll	equ 815Fh
os_mouse_read_scroll	equ 8162h
os_mouse_reset			equ 816Eh
os_mouse_read_int		equ 8171h

; -----------------------------------------------------------------
