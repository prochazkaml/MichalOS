; ------------------------------------------------------------------
; MichalOS Dead Pixel Test
; ------------------------------------------------------------------

	%INCLUDE "michalos.inc"

start:
	mov ax, .msg1
	mov bx, .msg2
	clr cx
	clr dx
	call os_dialog_box

	mov byte [0082h], 1

	mov ax, 13h
	int 10h
	
	clr bx

.loop:
	call os_clear_graphics

	inc bl
	and bl, 7

	call os_wait_for_key
	cmp al, 27
	jne .loop
		
	mov ax, 3
	int 10h
	ret
	
	.msg1	db "Press any key to change the color.", 0
	.msg2	db "Press Escape to quit.", 0

; ------------------------------------------------------------------
