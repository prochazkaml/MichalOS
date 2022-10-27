; ------------------------------------------------------------------
; MichalOS Configuration
; ------------------------------------------------------------------

; SYSTEM.CFG map:
; 0 = Desktop background color (BYTE)
; 1 = Window background color (BYTE)
; 2 = Password enabled (BYTE)
; 3 - 35 = Password data (STRING, 32 chars + '\0')
; 36 - 68 = Username (STRING, 32 chars + '\0')
; 69 - Sound enabled on startup (BYTE)
; 70 - Adlib driver number
;		- 0: Standard Adlib (ports 0x388-0x389)
;		- 1: PC speaker PWM
; 71 - Menu screen dimming enabled (BYTE)
; 72 - Menu color (BYTE)
; 73 - "DOS" font enabled (BYTE)
; 74 - Minutes to wait for screensaver (BYTE)
; 75 - System stack size in 16-byte blocks (WORD)
; 77 - 80 - Unused *******************************
; 81 - Minute time offset (WORD)

	%INCLUDE "michalos.inc"

start:
	call .draw_background

	mov ax, .command_list			; Draw list of settings
	mov bx, .help_msg1
	mov cx, .help_msg2
	mov si, startlist
	call .list_dialog

	jc .exit					; User pressed Esc?

	cmp ax, 1
	je .look

	cmp ax, 2
	je .sound
	
	cmp ax, 3
	je .password
		
	cmp ax, 4
	je .timezone
	
	cmp ax, 5
	je .advanced

.look:
	call .draw_background

	mov ax, .look_list			; Draw list of settings
	mov bx, .help_msg1
	mov cx, .help_msg2

	call os_list_dialog

	jc start					; User pressed Esc?

	cmp ax, 1
	je .bg_change
	
	cmp ax, 2
	je .bg_img_change
	
	cmp ax, 3
	je .bg_img_reset
		
	cmp ax, 4
	je .window_change
	
	cmp ax, 5
	je .menu_change
	
	cmp ax, 6
	je .screensaver_settings
	
	cmp ax, 7
	je .font_change

	cmp ax, 8
	je .enable_dimming
	
	cmp ax, 9
	je .disable_dimming
	
	cmp ax, 10
	je .img_help

.bg_img_reset:
	mov ax, .bg_name
	call os_remove_file
	
	mov byte [fs:DESKTOP_BACKGROUND], 0
	
	mov ax, .changedone
	clr bx
	clr cx
	clr dx
	call os_dialog_box
	jmp .look

.bg_img_change:
	call .draw_background

	mov byte [0087h], 1
	mov bx, .extension_number
	call os_file_selector		; Get filename
	mov byte [0087h], 0
	jc .look

	mov cx, buffer
	call os_load_file
	
	pusha
	push es
	mov ax, fs
	mov es, ax
	mov di, DESKTOP_BACKGROUND
	mov si, buffer
	mov cx, 1840
	rep movsw
	pop es
	popa
	
	xchg cx, bx
	
	mov ax, .bg_name
	call os_remove_file
	call os_write_file
	jc .write_error2
	
	mov ax, .changedone
	clr bx
	clr cx
	clr dx
	call os_dialog_box
	jmp .look

.write_error2:
	mov ax, .errmsg1
	mov bx, .errmsg2
	clr cx
	clr dx
	call os_dialog_box
	jmp .look
	
.img_help:
	mov ax, .imghelp1
	mov bx, .imghelp2
	mov cx, .imghelp3
	clr dx
	call os_dialog_box
	jmp .look
	
.enable_dimming:
	mov byte [57071], 1
	call .update_config
	jmp .look
	
.disable_dimming:
	mov byte [57071], 0
	call .update_config
	jmp .look

.enable_graphics:
	mov byte [57076], 1
	call .update_config
	jmp .look
	
.enable_text_mode:
	mov byte [57076], 0
	call .update_config
	jmp .look
	
.screensaver_settings:
	call .draw_background
	
	mov ax, .screensaver_list
	mov bx, .help_msg1
	mov cx, .help_msg2
	
	call os_list_dialog
	
	jc .look
	
	cmp ax, 1
	je .disable_screensaver
	
	cmp ax, 2
	je .screensaver_change_time
	
.disable_screensaver:
	mov byte [57074], 0
	call .update_config
	jmp .screensaver_settings

.screensaver_change_time:
	call .draw_background
	
	mov ax, buffer
	mov bx, .screensaver_msg
	call os_input_dialog
	
	mov si, buffer
	call os_string_to_int
	
	cmp ax, 60
	jg .screensaver_error
	
	mov [57074], al
	
	call .update_config
	jmp .screensaver_settings
	
.screensaver_error:
	mov ax, .scrnsaveerr
	clr bx
	clr cx
	clr dx
	call os_dialog_box

	jmp .screensaver_settings
	
.font_change:
	call .draw_background

	mov ax, .font_list			; Draw list of settings
	mov bx, .help_msg1
	mov cx, .help_msg2

	call os_list_dialog

	jc .look					; User pressed Esc?
	
	cmp ax, 1
	je .michalos_font
	
	cmp ax, 2
	je .bios_font
	
.michalos_font:
	mov byte [57073], 0
	call .update_config
	call os_reset_font
	jmp .look
	
.bios_font:
	mov byte [57073], 1
	call .update_config
	mov ax, 3
	int 10h
	mov ax, 1003h			; Set text output with certain attributes
	clr bx			; to be bright, and not blinking
	int 10h
	jmp .look
	
.menu_change:
	call .draw_background
	call os_color_selector
	jc .look
	cmp al, 14
	jg .menu_confirm
	add al, 0F0h
.menu_confirm:
	rol al, 4
	mov [57072], al
	call .update_config
	jmp .look
	
.bg_change:
	call .draw_background
	call os_color_selector
	jc .look
	cmp al, 9
	jge .bg_confirm
	add al, 0F0h
.bg_confirm:
	rol al, 4
	mov [57000], al
	call .update_config
	jmp .look

.window_change:
	call .draw_background
	call os_color_selector
	jc .look
	cmp al, 9
	jge .window_confirm
	add al, 240
.window_confirm:
	rol al, 4
	mov [57001], al
	call .update_config
	jmp .look

.timezone:
	call .draw_background

	mov ax, buffer
	mov bx, .time_msg
	call os_input_dialog

	mov si, buffer
	
	cmp byte [si], '-'
	je .negative_timezone
	
	call os_string_to_int
	mov [57081], ax
	
	call .update_config
	jmp start	
	
.negative_timezone:
	inc si
	
	call os_string_to_int
	neg ax
	mov [57081], ax
	
	call .update_config
	jmp start
	
.advanced:
	call .draw_background
	
	mov ax, .advanced_list		; Draw list of settings
	mov bx, .help_msg1
	mov cx, .help_msg2

	call os_list_dialog

	jc start					; User pressed Esc?

	cmp ax, 1
	je .stack_size
	
.stack_size:
	call .draw_background
	
	mov ax, buffer
	mov bx, .stack_msg
	call os_input_dialog
	
	mov si, buffer
	call os_string_to_int

	shl ax, 6					; kB -> segments

	cmp ax, 256
	jb .stack_size_error

	cmp ax, 4096
	ja .stack_size_error

	mov [57075], ax

	call .update_config
	jmp .advanced

.stack_size_error:
	mov ax, .stack_err_msg
	clr bx
	clr cx
	clr dx
	call os_dialog_box
	jmp .advanced

.sound:
	mov ax, .sound_list			; Draw list of settings
	mov bx, .help_msg1
	mov cx, .help_msg2

	call os_list_dialog

	jc start					; User pressed Esc?

	cmp ax, 1
	je .enable_sound
	
	cmp ax, 2
	je .disable_sound

	cmp ax, 3
	je .adlib_drv
	
.enable_sound:
	mov byte [57069], 1
	call .update_config
	jmp .sound
	
.disable_sound:
	mov byte [57069], 0
	call .update_config
	jmp .sound
	
.adlib_drv:
	mov ax, .adlib_list
	mov bx, .help_msg1
	mov cx, .help_msg2
	call os_list_dialog
	
	jc .sound
	
	dec al
	mov [57070], al
	
	call .update_config
	jmp .sound
	
.password:
	mov ax, .password_list
	mov bx, .help_msg1
	mov cx, .help_msg2
	call os_list_dialog
	
	jc start
	
	cmp ax, 1
	je .change_name
	
	cmp ax, 2
	je .disable_password
	
	cmp ax, 3
	je .set_password
	
.change_name:
	call .draw_background
	
	call .reset_name
	mov ax, 57036
	mov bx, .name_msg
	mov byte [0088h], 32
	call os_input_dialog
	mov byte [0088h], 255

	call .update_config
	jmp .password
	
.disable_password:
	call .draw_background

	mov byte [57002], 0
	call .update_config
	jmp .password
	
.set_password:
	call .draw_background

	mov byte [57002], 1
	call .reset_password

	mov ax, 57003
	mov bx, .password_msg
	mov byte [0088h], 32
	call os_password_dialog
	mov byte [0088h], 255
	
	mov si, 57003
	call os_string_encrypt
	
	call .update_config
	jmp .password
	
.exit:
	call os_clear_screen
	ret

;------------------------------------------

.list_dialog:
	mov [.selectedlist], si

	mov si, .callback
	jmp os_list_dialog_tooltip

.callback:
	dec ax
	shl ax, 1
	mov bx, ax
	
	mov si, [.selectedlist]

	mov si, [si + bx]
	mov dl, 42
	call os_print_string_box
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
	mov cx, 256
	call os_draw_background
	popa
	ret

.update_config:
	mov ax, .config_name	; Replace the SYSTEM.CFG file with the new configuration...
	call os_remove_file
	mov ax, .config_name
	mov bx, 57000
	mov cx, 83				; SYSTEM.CFG file size
	call os_write_file
	jc .write_error
	mov ax, .changedone
	clr bx
	clr cx
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

	.command_list		db 'Look and feel,Sound,User information,Set timezone,Advanced system settings', 0
	.password_list		db 'Change the name,Disable the password,Set the password', 0
	.look_list			db 'Set the background color,Set an image as a background,Remove the image background,Set the window color,Set the main menu color,Screensaver settings,Select the default font,Enable background dimming when in menu,Disable background dimming when in menu,(INFO) Why should I set the background color when I use an image?', 0
	.font_list			db 'MichalOS System Font,BIOS Default Font', 0
	.screensaver_list	db 'Disable the screensaver,Set the screensaver', 0
	.sound_list			db 'Enable sound at startup,Disable sound at startup,Set Adlib device driver', 0
	.adlib_list			db 'Standard Adlib card (ports 0x388-0x389),9-voice PC speaker square wave generator (PWM),9-voice PC speaker square wave generator (PWM - max volume)', 0
	.advanced_list		db 'System stack size', 0

	.imghelp1			db 'Some applications do not support drawing', 0
	.imghelp2			db 'the image to the BG, so the background', 0
	.imghelp3			db 'color is used as a fallback.', 0
	
	.time_msg			db 'Enter a time offset (in minutes):', 0
	
	.password_msg		db 'Enter a new password:', 0
	.name_msg			db 'Enter a new name (32 chars max.):', 0
	
	.screensaver_msg	db 'Enter the amount of minutes (max. 60):', 0
	
	.stack_msg			db 'Enter stack size (4-64 kB, default = 8):', 0
	.stack_err_msg		db 'Stack size not in range (4-64 kB)!', 0

	.changedone			db 'Changes have been saved.', 0
	
	.help_msg1			db 'Choose an option...', 0
	.help_msg2			db '', 0
	
	.title_msg			db 'MichalOS Settings', 0
	.footer_msg			db '', 0

	.config_name		db 'SYSTEM.CFG', 0
	.bg_name			db 'BG.SYS', 0
	
	.extension_number	db 1
	.asc_extension		db 'ASC', 0
	
	.errmsg1			db 'Error writing to the disk!', 0
	.errmsg2			db 'Make sure it is not read only!', 0

	.scrnsaveerr		db 'Max. 60 minutes!', 0
	
	.selectedlist		dw 0

startlist:
	dw .listitem0, .listitem1, .listitem2, .listitem3, .listitem4

	.listitem0	db 'Options for changing the visual', 13, 10
				db 'appearance of the system.', 13, 10
				db 10
				db 'These may include:', 13, 10
				db '- Setting the background', 13, 10
				db '- Changing system colors', 13, 10
				db '- Selecting the system font', 13, 10
				db '- Screensaver settings', 13, 10
				db '- etc.', 0

	.listitem1	db 'Options for controlling audio.', 13, 10
				db 10
				db 'Currently, the only supported', 13, 10
				db 'audio devices are your computer', 27h, 's', 13, 10
				db 'PC speaker and a YM3812-equipped', 13, 10
				db 'synthesizer device (such as', 13, 10
				db 'the AdLib sound card).', 0

	.listitem2	db 'Options for changing personal', 13, 10
				db 'information:', 13, 10
				db '- Changing the user name displayed', 13, 10
				db '  on the welcome screen', 13, 10
				db '- Changing or resetting the user', 13, 10
				db '  password', 0

	.listitem3	db 'If the displayed time in the top', 13, 10
				db 'right-hand corner does not match', 13, 10
				db 'reality, it may be possible that', 13, 10
				db 'your BIOS time is not set according', 13, 10
				db 'to your actual timezone.', 13, 10
				db 10
				db 'To mitigate this, you can set a', 13, 10
				db 'time offset (negative or positive),', 13, 10
				db 'which the system will add to the', 13, 10
				db 'current time reported by the BIOS.', 13, 10
				db 10
				db 'This way, you may keep the current', 13, 10
				db 'BIOS time intact (some OSes need', 13, 10
				db 'this) as well as have the correct', 13, 10
				db 'time displayed in MichalOS.', 0

	.listitem4	db 'Options only for advanced users.', 13, 10
				db 10
				db 'If these are set incorrectly, they', 13, 10
				db 'might cause system instability or', 13, 10
				db 'frequent crashes.', 13, 10
				db 10
				db 'However, if used correctly, they', 13, 10
				db 'may in certain instances help in', 13, 10
				db 'fixing some system issues.', 0
	
buffer:
	
; ------------------------------------------------------------------

