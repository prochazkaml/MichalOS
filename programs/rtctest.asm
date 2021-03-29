	BITS 16
	ORG 100h
	%INCLUDE "michalos.inc"

start:
	call .draw_background

	mov ax, .exit_msg
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	call os_clear_screen	
.test:
	call os_check_for_key
	cmp al, "Q"
	je near .exit

	mov cl, 0
	
.loop:
	mov al, cl
	out 70h, al
		
	in al, 71h

	add al, 13h
	daa
	
	call os_print_2hex
	call os_print_space
	inc cl
	cmp cl, 10
	jne .loop
	
	call os_print_newline
	jmp .test
	
.draw_background:	
	mov ax, .title
	mov bx, .blank
	mov cx, 256
	call os_draw_background
	ret

.exit:
	ret
	
	.title			db 'MichalOS RTC Diagnostic Tool', 0
	.blank			db 0
	
	.space			db ' ', 0
	.exit_msg		db 'Press Shift+Q to quit.', 0
