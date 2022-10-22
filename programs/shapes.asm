; ------------------------------------------------------------------
; MichalOS Shapes Test
; ------------------------------------------------------------------

	%INCLUDE "michalos.inc"

start:
	mov ax, .msg1
	mov bx, .msg2
	mov cx, .msg3
	mov dx, 0
	call os_dialog_box

	call os_init_graphics_mode
	
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
	je .line
	cmp byte [.shape], 1
	je .cf_rect
	cmp byte [.shape], 2
	je .circles
	cmp byte [.shape], 3
	je .no_cf_rect
	
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
	jmp .get_key

.circles:
	mov al, bl
	mov bx, si
	shr bx, 1
	call os_draw_circle

.get_key:
	call os_check_for_key
	cmp al, 32
	jne .no_switch
	
	inc byte [.shape]
	cmp byte [.shape], 5
	jne .no_switch

	mov byte [.shape], 0
	
.no_switch:
	cmp al, 27
	jne .loop
	ret
	
	.color	db 0
	.shape	db 0
	
	.msg1	db "Press Space to cycle lines, fill rects,", 0
	.msg2	db "circles, rects & full screen refresh", 0
	.msg3	db "Press Esc to exit.", 0

; ------------------------------------------------------------------
