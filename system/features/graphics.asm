; ==================================================================
; MichalOS Graphics functions
; ==================================================================

; Puts a pixel on the screen.
; IN: AL = Color; BH = Page; CX = X position; DX = Y position
; OUT: nothing
os_put_pixel:
	pusha
	mov ah, 0Ch
	int 10h
	popa
	ret
	
; Gets a pixel from the screen.
; IN: BH = Page; CX = X position; DX = Y position
; OUT: AL = Color
os_get_pixel:
	pusha
	mov ah, 0Dh
	int 10h
	mov [.tmp_byte], al
	popa
	mov al, [.tmp_byte]
	ret
	
	.tmp_byte	db 0
	
; ==================================================================
; TachyonOS -- The TachyonOS Operating System kernel
; Copyright (C) 2013 TachyonOS Developers -- see doc/LICENCE.TXT
;
; GRAPHICS ROUTINES
; ==================================================================
	
os_set_pixel:
	pusha
	mov dx, cx
	mov cx, ax
	mov al, bl
	mov bh, 0
	call os_put_pixel
	popa
	ret
	
; Implementation of Bresenham's line algorithm. Translated from an implementation in C (http://www.edepot.com/linebresenham.html)
; IN: CX=X1, DX=Y1, SI=X2, DI=Y2, BL=colour
; OUT: None, registers preserved
os_draw_line:
	pusha				; Save parameters
	
	xor ax, ax			; Clear variables
	mov di, .x1
	mov cx, 11
	rep stosw
	
	popa				; Restore and save parameters
	pusha
	
	mov [.x1], cx			; Save points
	mov [.x], cx
	mov [.y1], dx
	mov [.y], dx
	mov [.x2], si
	mov [.y2], di
	
	mov [.colour], bl		; Save the colour
	
	mov bx, [.x2]
	mov ax, [.x1]
	cmp bx, ax
	jl .x1gtx2
	
	sub bx, ax
	mov [.dx], bx
	mov ax, 1
	mov [.incx], ax
	jmp .test2
	
.x1gtx2:
	sub ax, bx
	mov [.dx], ax
	mov ax, -1
	mov [.incx], ax
	
.test2:
	mov bx, [.y2]
	mov ax, [.y1]
	cmp bx, ax
	jl .y1gty2
	
	sub bx, ax
	mov [.dy], bx
	mov ax, 1
	mov [.incy], ax
	jmp .test3
	
.y1gty2:
	sub ax, bx
	mov [.dy], ax
	mov ax, -1
	mov [.incy], ax
	
.test3:
	mov bx, [.dx]
	mov ax, [.dy]
	cmp bx, ax
	jl .dygtdx
	
	mov ax, [.dy]
	shl ax, 1
	mov [.dy], ax
	
	mov bx, [.dx]
	sub ax, bx
	mov [.balance], ax
	
	shl bx, 1
	mov [.dx], bx
	
.xloop:
	mov ax, [.x]
	mov bx, [.x2]
	cmp ax, bx
	je .done
	
	mov ax, [.x]
	mov cx, [.y]
	mov bl, [.colour]
	call os_set_pixel
	
	xor si, si
	mov di, [.balance]
	cmp di, si
	jl .xloop1
	
	mov ax, [.y]
	mov bx, [.incy]
	add ax, bx
	mov [.y], ax
	
	mov ax, [.balance]
	mov bx, [.dx]
	sub ax, bx
	mov [.balance], ax
	
.xloop1:
	mov ax, [.balance]
	mov bx, [.dy]
	add ax, bx
	mov [.balance], ax
	
	mov ax, [.x]
	mov bx, [.incx]
	add ax, bx
	mov [.x], ax
	
	jmp .xloop
	
.dygtdx:
	mov ax, [.dx]
	shl ax, 1
	mov [.dx], ax
	
	mov bx, [.dy]
	sub ax, bx
	mov [.balance], ax
	
	shl bx, 1
	mov [.dy], bx
	
.yloop:
	mov ax, [.y]
	mov bx, [.y2]
	cmp ax, bx
	je .done
	
	mov ax, [.x]
	mov cx, [.y]
	mov bl, [.colour]
	call os_set_pixel
	
	xor si, si
	mov di, [.balance]
	cmp di, si
	jl .yloop1
	
	mov ax, [.x]
	mov bx, [.incx]
	add ax, bx
	mov [.x], ax
	
	mov ax, [.balance]
	mov bx, [.dy]
	sub ax, bx
	mov [.balance], ax
	
.yloop1:
	mov ax, [.balance]
	mov bx, [.dx]
	add ax, bx
	mov [.balance], ax
	
	mov ax, [.y]
	mov bx, [.incy]
	add ax, bx
	mov [.y], ax
	
	jmp .yloop
	
.done:
	mov ax, [.x]
	mov cx, [.y]
	mov bl, [.colour]
	call os_set_pixel
	
	popa
	ret
	
	
	.x1 dw 0
	.y1 dw 0
	.x2 dw 0
	.y2 dw 0
	
	.x dw 0
	.y dw 0
	.dx dw 0
	.dy dw 0
	.incx dw 0
	.incy dw 0
	.balance dw 0
	.colour db 0
	.pad db 0
	
; Draw (straight) rectangle
; IN: CX=X1, DX=Y1, SI=X2, DI=Y2, BL=colour, CF = set if filled or clear if not
; OUT: None, registers preserved
os_draw_rectangle:
	pusha
	pushf
	
	mov word [.x1], cx
	mov word [.y1], dx
	mov word [.x2], si
	mov word [.y2], di
	
	popf
	jnc .draw_line

	jmp .fill_shape
	
.draw_line:
	; top line
	mov cx, [.x1]
	mov dx, [.y1]
	mov si, [.x2]
	mov di, [.y1]
	call os_draw_line
	
	; left line
	mov cx, [.x1]
	mov dx, [.y1]
	mov si, [.x1]
	mov di, [.y2]
	call os_draw_line
	
	; right line
	mov cx, [.x2]
	mov dx, [.y1]
	mov si, [.x2]
	mov di, [.y2]
	call os_draw_line

	; bottom line
	mov cx, [.x1]
	mov dx, [.y2]
	mov si, [.x2]
	mov di, [.y2]
	call os_draw_line
		
	jmp .finished_fill
		
.fill_shape:
	mov al, bl

	cmp cx, si		; Is X1 smaller than X2?
	jl .x_good
	xchg cx, si		; If not, exchange them
.x_good:
	cmp dx, di		; Is Y1 smaller than Y2?
	jl .y_good
	xchg dx, di		; If not, exchange them
.y_good:
	mov [.x1], cx
	mov bh, 0
.x_loop:
	call os_put_pixel
	inc cx
	
	cmp cx, si
	jl .x_loop
	
	inc dx
	mov cx, [.x1]
	
	cmp dx, di
	jl .x_loop
		
.finished_fill:
	popa
	ret
	
	.x1				dw 0
	.x2				dw 0
	.y1				dw 0
	.y2				dw 0

; Draw freeform shape
; IN: BH = number of points, BL = colour, SI = location of shape points data
; OUT: None, registers preserved
; DATA FORMAT: x1, y1, x2, y2, x3, y3, etc
os_draw_polygon:
	pusha
	
	dec bh
	mov byte [.points], bh
	
	mov word ax, [fs:si]
	add si, 2
	mov word [.xi], ax
	mov word [.xl], ax
	
	mov word ax, [fs:si]
	add si, 2
	mov word [.yi], ax
	mov word [.yl], ax
	
	.draw_points:
		mov cx, [.xl]
		mov dx, [.yl]
		
		mov word ax, [fs:si]
		add si, 2
		mov word [.xl], ax
		
		mov word ax, [fs:si]
		add si, 2
		mov word [.yl], ax
		
		push si
		
		mov si, [.xl]
		mov di, [.yl]
		
		call os_draw_line
		
		pop si
		
		dec byte [.points]
		cmp byte [.points], 0
		jne .draw_points
		
	mov cx, [.xl]
	mov dx, [.yl]
	mov si, [.xi]
	mov di, [.yi]
	call os_draw_line
	
	popa
	ret
	
	.xi				dw 0
	.yi				dw 0
	.xl				dw 0
	.yl				dw 0
	.points				db 0
	

; Clear the screen by setting all pixels to a single colour
; BL = colour to set
os_clear_graphics:
	pusha
	push es
	
	mov ax, 0xA000
	mov es, ax

	mov al, bl
	mov di, 0
	mov cx, 64000
	rep stosb

	pop es
	popa
	ret
	
	
; ----------------------------------------
; os_draw_circle -- draw a circular shape
; IN: AL = colour, BX = radius, CX = middle X, DX = middle y

os_draw_circle:
	pusha
	mov [.colour], al
	mov [.radius], bx
	mov [.x0], cx
	mov [.y0], dx

	mov [.x], bx
	mov word [.y], 0
	mov ax, 1
	shl bx, 1
	sub ax, bx
	mov [.xChange], ax
	mov word [.yChange], 0
	mov word [.radiusError], 0

.next_point:
	mov cx, [.x]
	mov dx, [.y]
	cmp cx, dx
	jl .finish

	;ax bx - function points
	;cx = x 
	;dx = y
	;si = -x
	;di = -y

	mov si, cx
	xor si, 0xFFFF
	inc si
	mov di, dx
	xor di, 0xFFFF
	inc di

	; (x + x0, y + y0)
	mov ax, cx
	mov bx, dx
	call .draw_point

	; (y + x0, x + y0)
	xchg ax, bx
	call .draw_point

	; (-x + x0, y + y0)
	mov ax, si
	mov bx, dx
	call .draw_point

	; (-y + x0, x + y0)
	mov ax, di
	mov bx, cx
	call .draw_point

	; (-x + x0, -y + y0)
	mov ax, si
	mov bx, di
	call .draw_point

	; (-y + x0, -x + y0)
	xchg ax, bx
	call .draw_point

	; (x + x0, -y + y0)
	mov ax, cx
	mov bx, di
	call .draw_point

	; (y + x0, -x + y0)
	mov ax, dx
	mov bx, si
	call .draw_point
	
	inc word [.y]
	mov ax, [.yChange]
	add [.radiusError], ax
	add word [.yChange], 2
	
	mov ax, [.radiusError]
	shl ax, 1
	add ax, [.xChange]
	
	cmp ax, 0
	jle .next_point
	
	dec word [.x]
	mov ax, [.xChange]
	add [.radiusError], ax
	add word [.xChange], 2

	jmp .next_point

.draw_point:
	; AX = X, BX = Y
	pusha
	add ax, [.x0]
	add bx, [.y0]
	mov cx, bx
	mov bl, [.colour]
	call os_set_pixel
	popa
	ret
	
.finish:
	popa
	ret
	


.colour				db 0
.x0					dw 0
.y0					dw 0
.radius				dw 0
.x					dw 0
.y					dw 0
.xChange			dw 0
.yChange			dw 0
.radiusError		dw 0
