; ==================================================================
; MichalOS Shutdown handler
; ==================================================================

os_reboot:
	jmp 0FFFFh:0

os_shutdown:
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
	
	jmp os_reboot
	
.APM_missing:
	mov ax, .errormsg2
	mov bx, .errormsg4
	mov cx, .errormsg45
	xor dx, dx
	call os_dialog_box
	
	jmp os_reboot
	
.APM_interface:
	mov ax, .errormsg3
	mov bx, .errormsg4
	mov cx, .errormsg45
	xor dx, dx
	call os_dialog_box
	
	jmp os_reboot
	
.APM_pwrmgmt:
	mov ax, .errormsg5
	mov bx, .errormsg4
	mov cx, .errormsg45
	xor dx, dx
	call os_dialog_box
	
	jmp os_reboot

	
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

; ==================================================================
