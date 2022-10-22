; ------------------------------------------------------------------
; MichalOS Dots Test
; ------------------------------------------------------------------

	%INCLUDE "michalos.inc"

start:
	call os_init_graphics_mode
	
.loop:
	clr ax
	mov bx, 255
	call os_get_random
	mov bl, cl
	
	mov cx, [.x_pos]
	mov dx, [.y_pos]
	
	call os_set_pixel
	
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
	
	call os_init_text_mode
	ret
	
	.color	db 0
	.x_pos	dw 0
	.y_pos	dw 0
	
; ------------------------------------------------------------------
