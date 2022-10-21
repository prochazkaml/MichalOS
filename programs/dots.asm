; ------------------------------------------------------------------
; MichalOS Dots Test
; ------------------------------------------------------------------

	%INCLUDE "michalos.inc"

start:
	mov byte [0082h], 1

	mov ax, 13h
	int 10h
	
.loop:
	clr ax
	mov bx, 255
	call os_get_random
	mov al, cl
	
	mov cx, [.x_pos]
	mov dx, [.y_pos]
	
	clr bh
	call os_put_pixel
	
	inc word [.x_pos]
	cmp word [.x_pos], 320
	jne .no_inc_y
	
	mov word [.x_pos], 0
	inc word [.y_pos]
	
	cmp word [.y_pos], 200
	jne .no_inc_y
	
	mov word [.y_pos], 0
	
.no_inc_y:
	call os_check_for_key
	cmp al, 27
	jne .loop
	
	mov ax, 3
	int 10h
	ret
	
	.color	db 0
	.x_pos	dw 0
	.y_pos	dw 0
	
; ------------------------------------------------------------------
