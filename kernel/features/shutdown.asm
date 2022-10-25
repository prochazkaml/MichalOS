; ==================================================================
; MichalOS Shutdown handler
; ==================================================================

os_reboot:
	jmp 0FFFFh:0

os_shutdown:
	call os_clear_screen
	call os_show_cursor

	mov ax, 5300h
	xor bx, bx
	int 15h				; check if APM is present
	jc .APM_missing

	mov ax, 5304h
	xor bx, bx
	int 15h				; disconnect any previous APM interface	
	
	mov ax, 530Eh		; Set APM to version 1.2
	xor bx, bx
	mov cx, 0102h
	int 15h

	mov ax, 5301h
	xor bx, bx
	xor cx, cx
	int 15h				; open an interface with APM
	jc .APM_interface

	mov ax, 5307h
	mov bx, 1
	mov cx, 3
	int 15h				; do a power off
	
.APM_error:
	mov ax, .errormsg1
	jmp .display_error
	
.APM_missing:
	mov ax, .errormsg2
	jmp .display_error
	
.APM_interface:
	mov ax, .errormsg3
	jmp .display_error
	
.APM_pwrmgmt:
	mov ax, .errormsg4

.display_error:
	mov bx, .errormsg01
	mov cx, .errormsg02
	clr dx
	call os_dialog_box
	
	jmp os_reboot

	.errormsg1	db 'Error shutting down the computer.', 0
	.errormsg2	db 'This computer does not support APM.', 0
	.errormsg3	db 'Error communicating with APM.', 0
	.errormsg4	db 'Error enabling power management.', 0
	.errormsg01	db 'Please turn off the computer manually,', 0
	.errormsg02	db 'or press OK to reboot.', 0
	
; ==================================================================
