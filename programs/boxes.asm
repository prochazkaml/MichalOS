; ------------------------------------------------------------------
; MichalOS Box Test
; ------------------------------------------------------------------

	%INCLUDE "michalos.inc"

start:
	mov byte [0082h], 1

	mov ax, 13h
	int 10h
	
.loop:
	clr ax
	
	mov bx, 15
	call os_get_random
	mov [.color], cl
	
	mov bx, 199
	call os_get_random
	mov di, cx
	call os_get_random
	mov dx, cx
	
	mov bx, 319
	call os_get_random
	mov si, cx
	call os_get_random
	
	mov bl, [.color]
	cmp byte [.shape], 0
	je .no_cf_rect
	cmp byte [.shape], 1
	je .cf_rect
	cmp byte [.shape], 2
	je .line
	
	call os_clear_graphics

	jmp .get_key
	
.no_cf_rect:
	clc
	call os_draw_rectangle
	jmp .get_key
	
.line:
	call os_draw_line
	jmp .get_key
	
.cf_rect:
	stc
	call os_draw_rectangle
	
.get_key:
	call os_check_for_key
	cmp al, 32
	jne .no_switch
	
	inc byte [.shape]
	and byte [.shape], 3
	
.no_switch:
	cmp al, 27
	jne .loop
	
	mov ax, 3
	int 10h
	ret
	
	.color	db 0
	.shape	db 0
	
; ------------------------------------------------------------------
