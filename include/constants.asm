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

%macro movs 2
	push %2
	pop %1
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
%define CONFIG_FILE_SIZE 83

; ------------------------------------------------------------------
; CONFIG FILE LOCATIONS

%define CONFIG(x) (CONFIG_FILE + x)

; 0 = Desktop background color (BYTE)
%define CONFIG_DESKTOP_BG_COLOR CONFIG(0)

; 1 = Window background color (BYTE)
%define CONFIG_WINDOW_BG_COLOR CONFIG(1)

; 2 = Password enabled (BYTE)
%define CONFIG_PASSWORD_ENABLED CONFIG(2)

; 3 - 35 = Password data (STRING, 32 chars + '\0')
%define CONFIG_PASSWORD CONFIG(3)
%define CFG_PASSWORD_MAX_INPUT_LENGTH 32
%define CFG_PASSWORD_MAX_LENGTH 33

; 36 - 68 = Username (STRING, 32 chars + '\0')
%define CONFIG_USERNAME CONFIG(36)
%define CFG_USERNAME_MAX_INPUT_LENGTH 32
%define CFG_USERNAME_MAX_LENGTH 33

; 69 - Sound enabled on startup (BYTE)
%define CONFIG_SOUND_ENABLED CONFIG(69)

; 70 - Adlib driver number
%define CONFIG_ADLIB_DRIVER CONFIG(70)
%define CFG_ADLIB_STD_DRIVER 0
%define CFG_ADLIB_PWM_DRIVER 1
%define CFG_ADLIB_PWM_LOUD_DRIVER 2

; 71 - Menu screen dimming enabled (BYTE)
%define CONFIG_MENU_DIMMING CONFIG(71)

; 72 - Menu color (BYTE)
%define CONFIG_MENU_BG_COLOR CONFIG(72)

; 73 - "DOS" font enabled (BYTE)
%define CONFIG_FONT CONFIG(73)
%define CFG_FONT_MICHALOS 0
%define CFG_FONT_BIOS 1

; 74 - Minutes to wait for screensaver (BYTE)
%define CONFIG_SCREENSAVER_MINUTES CONFIG(74)

; 75 - System stack size in 16-byte blocks (WORD)
%define CONFIG_STACKSGMT_SIZE CONFIG(75)

; 77 - 80 - Unused *******************************

; 81 - Minute time offset (WORD)
%define CONFIG_TIMEZONE_OFFSET CONFIG(81)

; ------------------------------------------------------------------
; MUSICAL NOTE FREQUENCY LIST

A2		equ 110
AS2		equ 117
B2		equ 124
C3		equ 131
CS3		equ 139
D3		equ 147
DS3		equ 156
E3		equ 165
F3		equ 175
FS3		equ 185
G3		equ 196
GS3		equ 208
A3		equ 220
AS3		equ 233
B3		equ 247
C4		equ 262
CS4		equ 277
D4		equ 294
DS4		equ 311
E4		equ 330
F4		equ 349
FS4		equ 370
G4		equ 392
GS4		equ 415
A4		equ 440
AS4		equ 466
B4		equ 494
C5		equ 523
CS5		equ 554
D5		equ 587
DS5		equ 622
E5		equ 659
F5		equ 698
FS5		equ 740
G5		equ 784
GS5		equ 831
A5		equ 880
AS5		equ 932
B5		equ 988
C6		equ 1046
CS6		equ 1109
D6		equ 1175
DS6		equ 1245
E6		equ 1319
F6		equ 1397
FS6		equ 1480
G6		equ 1568
GS6		equ 1661
A6		equ 1760
AS6		equ 1865
B6		equ 1976
C7		equ 2093
CS7		equ 2217
D7		equ 2349
DS7		equ 2489
E7		equ 2637
F7		equ 2794
FS7		equ 2960
G7		equ 3136
GS7		equ 3322
A7		equ 3520
AS7		equ 3729
B7		equ 3951
C8		equ 4186
CS8		equ 4435
D8		equ 4699
DS8		equ 4978
E8		equ 5274
F8		equ 5588
FS8		equ 5920
G8		equ 6272
GS8		equ 6645
A8		equ 7040
AS8		equ 7459
B8		equ 7902
