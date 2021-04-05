; ------------------------------------------------------------------
; MichalOS Starfield demo
; Backported from MichalOS 2.2 to work on standard VGA
; ------------------------------------------------------------------

	%INCLUDE "michalos.inc"
	%DEFINE STARCOUNT 512
	%DEFINE MAX_DEPTH 360

start:
	; Generate the stars

	mov cx, STARCOUNT
	mov di, starlist

.gen_loop:
	call .generate_new_star
	add di, 4
	loop .gen_loop

	; Initialize graphics mode

	mov byte [0082h], 1

	mov ax, 13h
	int 10h

.loop:
	push gs
	pop es

	mov di, 0
	mov al, 0
	mov cx, 64000
	rep stosb

	; Process the stars!

	mov cx, STARCOUNT
	mov si, starlist

.drawloop:
	; Draw the star

	push cx

	; Calculate X postition
	
	movsx eax, byte [si + 0]
	mov ebx, 1280
	imul ebx
	
	movzx ebx, word [si + 2]
	idiv ebx
	
	add ax, 160
	mov cx, ax

	; Is the star out of range?
	
	cmp cx, 0
	jl .no_render
	
	cmp cx, 320
	jge .no_render
	
	; Calculate Y postition
	
	movsx eax, byte [si + 1]
	mov ebx, 1280
	imul ebx
	
	movzx ebx, word [si + 2]
	idiv ebx

	add ax, 100
	mov dx, ax

	; Is the star out of range?
	
	cmp dx, 0
	jl .no_render
	
	cmp dx, 200
	jge .no_render

	; Calculate the pointer

	mov ax, dx
	mov bx, 320
	mul bx
	add ax, cx
	mov di, ax

	; Calculate the color
	
	mov dx, 0
	mov ax, [si + 2]
	mov bx, MAX_DEPTH / 15

	div bx
	
	mov bl, 15
	sub bl, al
	
	add bl, 16
	mov [gs:di], bl
	
.no_render:
	pop cx

	; Move the star closer to the camera

	dec word [si + 2]
	
	cmp word [si + 2], 0
	jg .no_reset
	
	mov word [si + 2], MAX_DEPTH

.no_reset:
	add si, 4
	dec cx
	jnz .drawloop

	; Copy the framebuffer

	push ds
	
	push gs
	pop ds
	
	push 0xA000
	pop es

	clr si
	clr di
	mov cx, 64000
	rep movsb

	pop ds

	; Check for user input

	call os_check_for_key

	cmp al, 27
	jne .loop
	
	mov ax, 3
	int 10h
	ret

; DI = address of star entry (4 bytes)
.generate_new_star:
	pusha

	; Generate new X/Y coordinates
	mov ax, 0
	mov bx, 99
	call os_get_random
	
	mov dx, cx
	call os_get_random
	
	mov al, cl
	sub al, 50
	stosb
	
	mov al, dl
	sub al, 50
	stosb
	
	mov ax, 1
	mov bx, MAX_DEPTH
	
	call os_get_random

	mov [di], cx

	popa
	ret

starlist:

; ------------------------------------------------------------------
