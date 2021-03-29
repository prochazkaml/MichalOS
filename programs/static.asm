; ------------------------------------------------------------------
; MichalOS TV Static Test
; ------------------------------------------------------------------

	%INCLUDE "michalos.inc"

start:
	mov byte [0082h], 1

	mov ax, 06h
	int 10h

	push es
	mov ax, 0B800h
	mov es, ax
	mov di, 0
	
.loop:
	mov ax, 0
	mov bx, 255
	call os_get_random
	
	mov al, cl
	stosb
	
	cmp di, 16000
	jne .no_reset

	mov di, 0
	
.no_reset:
	call os_check_for_key
	cmp al, 27
	jne .loop
	
	mov ax, 3
	int 10h
	pop es
	ret
	
	.color	db 0
	.x_pos	dw 0
	.y_pos	dw 0
	
; ------------------------------------------------------------------
