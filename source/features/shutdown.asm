; ------------------------------------------------------------------
; MichalOS Shutdown handler
; ------------------------------------------------------------------

os_shutdown:
	mov byte [0082h], 1
	call os_hide_cursor
	call .drawbackground
	call .drawwindow
	call .selector
	
	cmp al, 1
	je near .shutdown
	
	cmp al, 2
	je near .reset
	
	cmp al, 3
	je near checkformenu
	
.selector:
	mov dx, 11 * 256 + 28
	call os_move_cursor

.selectorloop:
	call .drawcontents
	call .invert
	
	call os_wait_for_key
	
	cmp ah, 80
	je .selectdown
	
	cmp ah, 72
	je .selectup
	
	cmp al, 13
	je .select
	
	cmp al, 27
	je .return
	
	jmp .selectorloop

.return:
	mov al, 3
	mov byte [0082h], 1
	ret

.selectdown:
	cmp dh, 13
	je near .selectorloop
	inc dh
	jmp .selectorloop

.selectup:
	cmp dh, 11
	je near .selectorloop
	dec dh
	jmp .selectorloop

.select:
	mov al, dh
	sub al, 10
	ret
	
.invert:
	mov dl, 28

.invertloop:
	call os_move_cursor
	mov ah, 08h
	mov bh, 0
	int 10h

	mov bx, 240			; Black on white
	mov ah, 09h
	mov cx, 1
	int 10h

	inc dl
	cmp dl, 60
	je near .invertend
	jmp .invertloop
	
.invertend:
	mov dl, 28
	ret
	
.drawwindow:
	mov dx, 9 * 256 + 19			; First, draw white background box
	mov bl, [57001]
	mov si, 42
	mov di, 15
	call os_draw_block

.drawcontents:
	pusha
	mov bl, [57001]
	mov dx, 10 * 256 + 20
	call os_move_cursor

	mov si, .dialogmsg1
	call os_format_string
	mov si, 57036
	call os_format_string
	mov si, .dialogmsg2
	call os_format_string

	mov dx, 11 * 256 + 20
	call os_move_cursor
	mov si, .logo0
	call os_format_string

	mov dx, 12 * 256 + 20
	call os_move_cursor
	mov si, .logo1
	call os_format_string

	mov dx, 13 * 256 + 20
	call os_move_cursor
	mov si, .logo2
	call os_format_string

	mov dx, 14 * 256 + 20
	call os_move_cursor
	mov si, .logo3
	call os_format_string
	popa
	ret

.drawbackground:
	call os_clear_screen
	mov dx, 0
	call os_move_cursor
	
	mov ax, 0920h
	mov bx, 112			; Black on gray
	mov cx, 80
	int 10h
	
	mov dx, 1 * 256
	call os_move_cursor
	
	mov bl, [57000]		; Color from RAM
	and bl, 11110000b
	mov cx, 1840
	mov al, 177
	int 10h
	
	mov dx, 24 * 256
	call os_move_cursor
	mov bl, 112			; Black on gray
	mov cx, 80
	mov al, 32
	int 10h
	ret
	
.reset:
	jmp 0FFFFh:0

.shutdown:
	call os_clear_screen
	call os_show_cursor

	mov si, .apmmsg
	call os_print_string
	
	mov si, .dbgmsg1
	call os_print_string
	
	mov ax, 5300h
	xor bx, bx
	int 15h				; check if APM is present
	jc .APM_missing

	mov si, .dbgmsg2
	call os_print_string

	mov ax, 5304h
	xor bx, bx
	int 15h				; disconnect any previous APM interface	
	
	mov si, .dbgmsg2_1
	call os_print_string
	
	mov ax, 530Eh		; Set APM to version 1.2
	xor bx, bx
	mov cx, 0102h
	int 15h

	mov si, .dbgmsg3
	call os_print_string

	mov ax, 5301h
	xor bx, bx
	xor cx, cx
	int 15h				; open an interface with APM
	jc .APM_interface

	mov si, .dbgmsg4
	call os_print_string

	mov ax, 5307h
	mov bx, 1
	mov cx, 3
	int 15h				; do a power off
	
.APM_error:
	mov ax, .errormsg1
	mov bx, .errormsg4
	mov cx, .errormsg45
	xor dx, dx
	call os_dialog_box
	
	jmp .reset
	
.APM_missing:
	mov ax, .errormsg2
	mov bx, .errormsg4
	mov cx, .errormsg45
	xor dx, dx
	call os_dialog_box
	
	jmp .reset
	
.APM_interface:
	mov ax, .errormsg3
	mov bx, .errormsg4
	mov cx, .errormsg45
	xor dx, dx
	call os_dialog_box
	
	jmp .reset
	
.APM_pwrmgmt:
	mov ax, .errormsg5
	mov bx, .errormsg4
	mov cx, .errormsg45
	xor dx, dx
	call os_dialog_box
	
	jmp .reset

	
	.dialogmsg1	db 'Goodbye, ', 0
	.dialogmsg2	db '.', 0
	.errormsg1	db 'Error shutting down the computer.', 0
	.errormsg2	db 'This computer does not support APM.', 0
	.errormsg3	db 'Error communicating with APM.', 0
	.errormsg4	db 'Please turn off the computer manually,', 0
	.errormsg45	db 'or press OK to reboot.', 0
	.errormsg5	db 'Error enabling power management.', 0
	
	.apmmsg		db 'Attempting shutdown through APM...', 13, 10, 0
	
	
	.dbgmsg1	db 'Checking APM...', 13, 10, 0
	.dbgmsg2	db 'Disconnecting any previous APM interface...', 13, 10, 0
	.dbgmsg2_1	db 'Setting APM version to 1.2...', 13, 10, 0
	.dbgmsg3	db 'Connecting to APM...', 13, 10, 0
	.dbgmsg4	db 'Enabling power management...', 13, 10, 0
	.dbgmsg5	db 'Shutting down...', 13, 10, 0
	
	.logo0		db 218, 196, 196, 179, 196, 196, 191, '  Shut down the computer         ', 0
	.logo1		db 179, 32, 32, 179, 32, 32, 179,     '  Soft reboot the computer       ', 0
	.logo2		db 179, 32, 32, 32, 32, 32, 179,      '  Go back                        ', 0
	.logo3		db 192, 196, 196, 196, 196, 196, 217, 0
