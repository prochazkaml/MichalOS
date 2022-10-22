; ------------------------------------------------------------------
; MichalOS Dots Test
; ------------------------------------------------------------------

	%INCLUDE "michalos.inc"

start:
	call os_init_graphics_mode
	
	mov ax, 0A000h
	mov es, ax

	clr si
	clr di

.loop:
	clr ax
	mov bx, 255
	call os_get_random
	mov bl, cl
	
	mov cx, si
	mov ax, di
	
	call os_fast_set_pixel
	
	inc si
	cmp si, 320
	jne .no_inc_y
	
	clr si
	inc di
	
	cmp di, 200
	jne .no_inc_y

	clr di
	
.no_inc_y:
	call os_check_for_key
	cmp al, 27
	jne .loop
	ret
	
	.color	db 0
	.x_pos	dw 0
	.y_pos	dw 0
	
; ------------------------------------------------------------------
