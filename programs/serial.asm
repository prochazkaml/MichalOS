; ------------------------------------------------------------------
; MichalOS Serial Tester
; ------------------------------------------------------------------

	%INCLUDE "include/program.inc"

start:
	call .draw_background
	clr ax				; Set up the serial port
	call os_serial_port_enable
	
	call os_get_via_serial		; Is the other computer waiting for connection?
	cmp al, 123
	je .connection_request
	
	mov si, .wait_msg1
	mov ax, .wait_msg2
	mov bx, .blank
	mov cx, .blank
	mov dx, .blank
	call os_temp_box

.loop:
	mov al, 123
	call os_send_via_serial
	
	call os_get_via_serial
	cmp al, 125
	je .request_confirm
	
	call os_check_for_key
	cmp al, 27
	je .exit
	
	jmp .loop
	
.connection_request:
	mov al, 125
	call os_send_via_serial
	
.request_confirm:
	mov ax, .connection_msg
	clr bx
	clr cx
	clr dx
	call os_dialog_box
	
	jmp .exit
	
	
.draw_background:
	mov ax, .title_msg
	mov bx, .blank
	mov cx, 256
	call os_draw_background
	ret
	
.exit:
	clr al
	call os_send_via_serial
	ret
	
	.title_msg			db 'MichalOS Serial Tester', 0
	.blank				db 0
	.wait_msg1			db 'Waiting for a response...', 0
	.wait_msg2			db 'Press Esc to quit.', 0
	.connection_msg		db 'Successfully connected.', 0
	
; ------------------------------------------------------------------
