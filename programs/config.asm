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
; 75 - 80 - Unused *******************************
; 81 - Minute time offset (WORD)

	%INCLUDE "michalos.inc"

start:
	call .draw_background

.start:
	mov ax, .command_list			; Draw list of settings
	mov bx, .help_msg1
	mov cx, .help_msg2

	call os_list_dialog

	jc near .exit					; User pressed Esc?

	cmp ax, 1
	je near .look

	cmp ax, 2
	je near .sound
	
	cmp ax, 3
	je near .password
		
	cmp ax, 4
	je near .timezone
		
.look:
	mov ax, .look_list			; Draw list of settings
	mov bx, .help_msg1
	mov cx, .help_msg2

	call os_list_dialog

	jc near .start					; User pressed Esc?

	cmp ax, 1
	je near .bg_change
	
	cmp ax, 2
	je near .bg_img_change
	
	cmp ax, 3
	je near .bg_img_reset
		
	cmp ax, 4
	je near .window_change
	
	cmp ax, 5
	je near .menu_change
	
	cmp ax, 6
	je near .screensaver_settings
	
	cmp ax, 7
	je near .font_change

	cmp ax, 8
	je near .enable_dimming
	
	cmp ax, 9
	je near .disable_dimming
	
	cmp ax, 10
	je near .img_help

.bg_img_reset:
	mov ax, .bg_name
	call os_remove_file
	
	mov byte [fs:DESKTOP_BACKGROUND], 0
	
	mov ax, .changedone
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	jmp .look

.bg_img_change:
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
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	jmp .look

.write_error2:
	mov ax, .errmsg1
	mov bx, .errmsg2
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	jmp .look
	
.img_help:
	mov ax, .imghelp1
	mov bx, .imghelp2
	mov cx, .imghelp3
	mov dx, 0
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
	je near .disable_screensaver
	
	cmp ax, 2
	je near .screensaver_change_time
	
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
	
	cmp ax, 30
	jg .screensaver_error
	
	mov [57074], al
	
	call .update_config
	jmp .screensaver_settings
	
.screensaver_error:
	mov ax, .scrnsaveerr
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	jmp .screensaver_settings
	
.font_change:
	call .draw_background

	mov ax, .font_list			; Draw list of settings
	mov bx, .help_msg1
	mov cx, .help_msg2

	call os_list_dialog

	jc near .look					; User pressed Esc?
	
	cmp ax, 1
	je near .michalos_font
	
	cmp ax, 2
	je near .bios_font
	
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
	mov bx, 0				; to be bright, and not blinking
	int 10h
	jmp .look
	
.menu_change:
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
	

.sound:
	mov ax, .sound_list			; Draw list of settings
	mov bx, .help_msg1
	mov cx, .help_msg2

	call os_list_dialog

	jc near .start					; User pressed Esc?

	cmp ax, 1
	je near .enable_sound
	
	cmp ax, 2
	je near .disable_sound

	cmp ax, 3
	je near .adlib_drv
	
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
	
	jc near .sound
	
	dec al
	mov [57070], al
	
	call .update_config
	jmp .sound
	
.password:
	mov ax, .password_list
	mov bx, .help_msg1
	mov cx, .help_msg2
	call os_list_dialog
	
	jc .start
	
	cmp ax, 1
	je near .change_name
	
	cmp ax, 2
	je near .disable_password
	
	cmp ax, 3
	je near .set_password
	
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
	
.fail:
	call .draw_background

	mov ax, .permerrmsg1
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	jmp .password
	
.exit:
	call os_clear_screen
	ret

;------------------------------------------

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
	mov bx, 0
	mov cx, 0
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

	.command_list		db 'Look and feel,Sound,User information,Set timezone', 0
	.password_list		db 'Change the name,Disable the password,Set the password', 0
	.look_list			db 'Set the background color,Set an image as a background,Remove the image background,Set the window color,Set the main menu color,Screensaver settings,Select the default font,Enable background dimming when in menu,Disable background dimming when in menu,(INFO) Why should I set the background color when I use an image?', 0
	.font_list			db 'MichalOS System Font,BIOS Default Font', 0
	.screensaver_list	db 'Disable the screensaver,Set the screensaver', 0
	.sound_list			db 'Enable sound at startup,Disable sound at startup,Set Adlib device driver', 0
	.adlib_list			db 'Standard Adlib card (ports 0x388-0x389),9-voice PC speaker square wave generator (PWM),9-voice PC speaker square wave generator (PWM - max volume)', 0

	.imghelp1			db 'Some applications do not support drawing', 0
	.imghelp2			db 'the image to the BG, so the background', 0
	.imghelp3			db 'color is used as a fallback.', 0
	
	.time_msg			db 'Enter a time offset (in minutes):', 0
	
	.password_msg		db 'Enter a new password:', 0
	.name_msg			db 'Enter a new name (32 chars max.):', 0
	
	.screensaver_msg	db 'Enter the amount of minutes (max. 30):', 0
	
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

	.permerrmsg1		db 'Authentication failed!', 0

	.scrnsaveerr		db 'Max. 30 minutes!', 0
	
	driversgmt	dw 0
	
buffer:
	
; ------------------------------------------------------------------

