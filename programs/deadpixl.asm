; ------------------------------------------------------------------
; MichalOS Dead Pixel Test
; ------------------------------------------------------------------

	%INCLUDE "include/program.inc"

start:
	mov ax, .msg1
	mov bx, .msg2
	clr cx
	clr dx
	call os_dialog_box

	call os_init_graphics_mode
	
	clr bx
	movs es, 0A000h

.loop:
	call os_clear_graphics

	inc bl
	and bl, 7

	call os_wait_for_key
	cmp al, 27
	jne .loop
	ret
	
	.msg1	db "Press any key to change the color.", 0
	.msg2	db "Press Escape to quit.", 0

; ------------------------------------------------------------------
