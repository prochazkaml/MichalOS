create_player_box:		; SI = top line, BX = center line
	clr ax
	clr cx
	clr dx
	call os_temp_box

	mov ax, 0920h
	mov bx, 87h
	mov cx, 40
	int 10h	
	ret
	
draw_progress_bar:		; EAX = current position, EBX = total
	pushad
	mov16 dx, 20, 14
	call os_move_cursor
	
	clr edx
	mov ecx, 80
	mul ecx
	div ebx

	cmp ax, [.lastval]
	jge .no_redraw
	
	pusha
	mov ax, 0920h
	mov bx, 87h
	mov cx, 40
	int 10h
	popa
	
.no_redraw:
	mov [.lastval], ax
	push ax
	
	shr ax, 1
	
	test ax, ax
	jz .nodraw
	
	mov cx, ax
	
.loop:
	mov ax, 0EDBh
	clr bx
	int 10h
	
	loop .loop
	
.nodraw:
	pop ax
	test ax, 1
	jz .exit
	
	mov ax, 0EDDh
	clr bx
	int 10h
	
.exit:
	popad
	ret
	
	.lastval	dw 0
