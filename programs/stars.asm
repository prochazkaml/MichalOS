; ------------------------------------------------------------------
; MichalOS Starfield demo
; Backported from MichalOS 2.2 to work on standard VGA
; ------------------------------------------------------------------

	%INCLUDE "include/program.inc"
	%DEFINE STARCOUNT 512
	%DEFINE MAX_DEPTH 360

start:
	; Set up speed limiting interrupt

	mov si, .int_handler
	mov cx, 19886
	call os_attach_app_timer

	; Generate the stars

	mov cx, STARCOUNT
	mov di, starlist

.gen_loop:
	call .generate_new_star
	add di, 4
	loop .gen_loop

	; Initialize graphics mode

	call os_init_graphics_mode

.loop:
	cmp byte [.drawframe], 1
	je .draw
	
	hlt
	jmp .loop

.draw:
	mov byte [.drawframe], 0

	push gs
	pop es

	clr di
	clr eax
	mov cx, 64000 / 4
	rep stosd

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
	
	movsx ebx, word [.xoffset]
	sal ebx, 8
	sub eax, ebx
	
	movzx ebx, word [si + 2]
	clr edx
	bt eax, 31
	jnc .no_negative_x

	dec edx

.no_negative_x:
	idiv ebx
	
	; Is the star out of range?
	
	add ax, 160
	js .no_render
	mov cx, ax

	cmp cx, 320
	jge .no_render
	
	; Calculate Y postition
	
	movsx eax, byte [si + 1]
	mov ebx, 1280
	imul ebx

	movsx ebx, word [.yoffset]
	sal ebx, 8
	sub eax, ebx
	
	movzx ebx, word [si + 2]
	clr edx
	bt eax, 31
	jnc .no_negative_y

	dec edx

.no_negative_y:
	movzx ebx, word [si + 2]
	idiv ebx

	; Is the star out of range?
	
	add ax, 100
	js .no_render
	mov dx, ax
	
	cmp dx, 200
	jge .no_render

	; Calculate the pointer

	mov ax, dx
	mov bx, 320
	mul bx
	add ax, cx
	mov di, ax

	; Calculate the color
	
	clr dx
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
	jnz .no_reset
	
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
	mov cx, 64000 / 4
	rep movsd

	pop ds

	; Check for user input

	call os_check_for_key

	cmp ah, 72
	je .move_up
	
	cmp ah, 75
	je .move_left
	
	cmp ah, 77
	je .move_right
	
	cmp ah, 80
	je .move_down

	cmp al, 27
	jne .loop
	ret

.move_up:
	dec word [.yoffset]
	jmp .loop

.move_down:
	inc word [.yoffset]
	jmp .loop

.move_left:
	dec word [.xoffset]
	jmp .loop

.move_right:
	inc word [.xoffset]
	jmp .loop

	.xoffset	dw 0
	.yoffset	dw 0

; DI = address of star entry (4 bytes)
.generate_new_star:
	pusha

	; Generate new X/Y coordinates
	clr ax
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

.int_handler:
	mov byte [.drawframe], 1
	ret

	.drawframe	db 1

starlist:

; ------------------------------------------------------------------
