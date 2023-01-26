; ------------------------------------------------------------------
; Include file for MichalOS kernel/program development - constants & macros
; ------------------------------------------------------------------

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
; MACROS

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

; ------------------------------------------------------------------
; MEMORY LOCATIONS

%define ADLIB_BUFFER 0500h
%define DESKTOP_BACKGROUND 0600h
%define SYSTEM_FONT 1600h
%define FILE_MANAGER 2600h
%define DISK_PARAMS 2E00h

%define DISK_BUFFER 0E000h
%define CONFIG_FILE 57000
