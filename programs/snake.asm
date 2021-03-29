; snake game
; assembly 8086
; written by Leonardo Ono (ono.leo@gmail.com)
;
; target OS: DOS (.COM file extension)
; use: nasm snake.asm -o snake.com -f bin

	%include "michalos.inc"

section .text
		call hide_cursor
	start:
		call show_title
		call start_playing
		call show_game_over
		jmp start

	; in:
	;	si = number of 55.56 ms to wait
	sleep:
			mov ah, 0
			int 1Ah
			mov bx, dx
		.wait:
			mov ah, 0
			int 1Ah
			sub dx, bx
			cmp dx, si
			jl .wait
			ret

	hide_cursor:
			mov ah, 02h
			mov bh, 0
			mov dh, 25
			mov dl, 0
			int 10h
			ret

	clear_keyboard_buffer:
			mov ah, 1
			int 16h
			jz .end
			mov ah, 0h ; retrieve key from buffer
			int 16h
			jmp clear_keyboard_buffer
		.end:
			ret

	exit_process:
			mov sp, 0FFFEh - 2
			ret

	buffer_clear:
			mov bx, 0
		.next:	
			mov byte [buffer + bx], ' '
			inc bx
			cmp bx, 2000
			jnz .next
			ret
		
	; in:
	;	bl = char
	;	cx = col
	;	dl = row
	buffer_write:
		mov di, buffer
		mov al, 80
		mul dl
		add ax, cx
		add di, ax
		mov byte [di], bl
		ret
	
	; in:
	;	cx = col
	;	dx = row
	; out: 
	;	bl = char
	buffer_read:
		mov di, buffer
		mov al, 80
		mul dl
		add ax, cx
		add di, ax
		mov bl, [di]
		ret
	
	; in:
	;	si = string address
	;	di = buffer destination offset
	buffer_print_string:
		.next:
			mov al, [si]
			cmp al, 0
			jz .end
			mov byte [buffer + di], al
			inc di
			inc si
			jmp .next
		.end:
			ret
		
	;   0 = snake right
	;   2 = snake left
	;   4 = snake down
	;   8 = snake up
	; > 8 = ASCII char
	buffer_render:
			mov ax, 0b800h
			mov es, ax
			mov di, buffer
			mov si, 0
		.next:
			mov bl, [di]
			cmp bl, 8
			jz .is_snake
			cmp bl, 4
			jz .is_snake
			cmp bl, 2
			jz .is_snake
			cmp bl, 1
			jz .is_snake
			jmp .write
		.is_snake:
			mov bl, 219
		.write:
			mov byte [es:si], bl
			inc di
			add si, 2
			cmp si, 4000
			jnz .next
			ret

	show_title:
			call buffer_clear
			call buffer_render
			mov si, 18
			call sleep
			mov si, 0
		.next:
			mov bx, [.title + si]
			mov byte [buffer + bx], 219
			push si
			call buffer_render
			mov si, 1
			call sleep
			pop si
			add si, 2
			cmp si, 274
			jl .next
			mov si, .text_1
			mov di, 1626
			call buffer_print_string
			mov si, .text_2
			mov di, 1781
			call buffer_print_string
			call clear_keyboard_buffer
		.wait_for_key:
			mov si, .text_4
			mov di, 1388
			call buffer_print_string
			call buffer_render
			mov si, 5
			call sleep
			mov ah, 1
			int 16h
			jnz .continue
			mov si, .text_3
			mov di, 1388
			call buffer_print_string
			call buffer_render
			mov si, 10
			call sleep
			mov ah, 1
			int 16h
			jz .wait_for_key
		.continue:
			mov ah, 0
			int 16h
			ret
		.title:
			dw 0342, 0341, 0340, 0339, 0338, 0337, 0336, 0335, 0415, 0495
			dw 0575, 0655, 0656, 0657, 0658, 0659, 0660, 0661, 0662, 0742
			dw 0822, 0902, 0982, 0981, 0980, 0979, 0978, 0977, 0976, 0975
			dw 0985, 0905, 0825, 0745, 0665, 0585, 0505, 0425, 0345, 0426
			dw 0507, 0587, 0668, 0669, 0750, 0830, 0911, 0992, 0912, 0832
			dw 0752, 0672, 0592, 0512, 0432, 0352, 0995, 0915, 0835, 0755
			dw 0675, 0595, 0515, 0435, 0355, 0356, 0357, 0358, 0359, 0360
			dw 0361, 0362, 0442, 0522, 0602, 0682, 0762, 0842, 0922, 1002
			dw 0676, 0677, 0678, 0679, 0680, 0681, 0365, 0445, 0525, 0605
			dw 0685, 0765, 0845, 0925, 1005, 0372, 0451, 0530, 0609, 0608
			dw 0687, 0686, 0768, 0769, 0850, 0931, 1012, 0382, 0381, 0380
			dw 0379, 0378, 0377, 0376, 0375, 0455, 0535, 0615, 0695, 0775
			dw 0855, 0935, 1015, 1016, 1017, 1018, 1019, 1020, 1021, 1022
			dw 0696, 0697, 0698, 0699, 0700, 0701, 0702
		.text_1:
			db "DEVELOPED BY O.L. (C) 2017", 0
		.text_2:
			db "WRITTEN IN ASSEMBLY 8086 LANGUAGE :)", 0
		.text_3:
			db "PRESS ANY KEY TO START", 0
		.text_4:
			db "                      ", 0

	print_score:
			mov si, .text
			mov di, 0
			call buffer_print_string
			mov ax, [score]
			mov di, 13
		.next_digit:
			xor dx, dx
			mov bx, 10
			div bx
			push ax
			mov al, dl
			add al, 48
			mov byte [buffer + di], al
			pop ax
			dec di
			cmp ax, 0
			jnz .next_digit
			ret
		.text:
			db " SCORE: 000000", 0

	update_snake_direction:
			mov ah, 1
			int 16h
			jz .end
			mov ah, 0h ; retrieve key from buffer
			int 16h
			cmp al, 27 ; ESC
			jz exit_process
			cmp ah, 48h ; up
			jz .up
			cmp ah, 50h ; down
			jz .down
			cmp ah, 4bh; left
			jz .left
			cmp ah, 4dh; right
			jz .right
			jmp update_snake_direction
		.up:
			mov byte [snake_direction], 8
			jmp update_snake_direction
		.down:
			mov byte [snake_direction], 4
			jmp update_snake_direction
		.left:
			mov byte [snake_direction], 2
			jmp update_snake_direction
		.right:
			mov byte [snake_direction], 1
			jmp update_snake_direction
		.end:
			ret
		
	update_snake_head:
			mov al, [snake_head_y]
			mov byte [snake_head_previous_y], al
			mov al, [snake_head_x]
			mov byte [snake_head_previous_x], al
			mov ah, [snake_direction]
			cmp ah, 8 ; up
			jz .up
			cmp ah, 4 ; down
			jz .down
			cmp ah, 2; left
			jz .left
			cmp ah, 1; right
			jz .right
		.up:
			dec word [snake_head_y]
			jmp .end
		.down:
			inc word [snake_head_y]
			jmp .end
		.left:
			dec word [snake_head_x]
			jmp .end
		.right:
			inc word [snake_head_x]
		.end:
			; update previous snake body with direction information
			mov bl, [snake_direction]
			mov ch, 0
			mov cl, [snake_head_previous_x]
			mov dl, [snake_head_previous_y]
			call buffer_write
			ret

	check_snake_new_position:
			mov ch, 0
			mov cl, [snake_head_x]
			mov dh, 0
			mov dl, [snake_head_y]
			call buffer_read
			cmp bl, 8
			jle .set_game_over
			cmp bl, '*'
			je .food
			cmp bl, ' '
			je .empty_space
		.set_game_over:
			cmp al, 1
			mov byte [is_game_over], al 
		.write_new_head:
			mov bl, 1
			mov ch, 0
			mov cl, [snake_head_x]
			mov ch, 0
			mov dl, [snake_head_y]
			call buffer_write
			ret
		.food:
			inc dword [score]
			call .write_new_head
			call create_food
			jmp .end
		.empty_space:
			call update_snake_tail
			call .write_new_head
		.end:
			ret

	update_snake_tail:
			mov al, [snake_tail_y]
			mov byte [snake_tail_previous_y], al
			mov al, [snake_tail_x]
			mov byte [snake_tail_previous_x], al
			mov ch, 0
			mov cl, [snake_tail_x]
			mov dh, 0
			mov dl, [snake_tail_y]
			call buffer_read
			cmp bl, 8 ; up
			jz .up
			cmp bl, 4 ; down
			jz .down
			cmp bl, 2; left
			jz .left
			cmp bl, 1; right
			jz .right
			jmp exit_process
		.up:
			dec word [snake_tail_y]
			jmp .end
		.down:
			inc word [snake_tail_y]
			jmp .end
		.left:
			dec word [snake_tail_x]
			jmp .end
		.right:
			inc word [snake_tail_x]
		.end:
			mov bl, ' '
			mov ch, 0
			mov cl, [snake_tail_previous_x]
			mov ch, 0
			mov dl, [snake_tail_previous_y]
			call buffer_write
		ret

	create_initial_foods:
			mov cx, 10
		.again:
			push cx
			call create_food
			pop cx
			loop .again

	; TODO: needs to fix when there isn't more free position available
	create_food:
		.try_again:
			; ref.: http://webpages.charter.net/danrollins/techhelp/0245.HTM
			mov ah, 0
			int 1Ah ; cx = hi dx = low
			mov ax, dx
			and ax, 0fffh
			mul dx
			mov dx, ax
			mov ax, dx
			mov cx, 2000
			xor dx, dx
			div cx ; dx = rest of division
			mov bx, dx
			mov di, buffer
			mov al, [di + bx]
			cmp al, ' ' ; create food just in empty position
			jnz .try_again
			mov byte [di + bx], '*'
			ret

	reset:
			mov ax, 0
			mov word [score], ax
			mov byte [is_game_over], al
			mov al, 8
			mov byte [snake_direction], al
			mov al, 40
			mov byte [snake_head_x], al
			mov byte [snake_head_previous_x], al
			mov byte [snake_tail_previous_x], al
			mov byte [snake_tail_x], al
			mov al, 15
			mov byte [snake_head_y], al
			mov byte [snake_head_previous_y], al
			mov byte [snake_tail_y], al
			mov byte [snake_tail_previous_y], al
			ret

	start_playing:
			call reset		
			call buffer_clear
			call draw_border
			call create_initial_foods
		.main_loop:
			mov si, 2
			call sleep
		
			call update_snake_direction
			call update_snake_head
			call check_snake_new_position
			call print_score
			call buffer_render
		
			mov al, [is_game_over]
			cmp al, 0
			jz .main_loop
			ret

	draw_border:
			mov di, 0
		.next_x:
			mov byte [buffer + di], 255
			mov byte [buffer + 80 + di], 196
			mov byte [buffer + 1920 + di], 196
			inc di
			cmp di, 80
			jnz .next_x
			mov di, 0
		.next_y:
			mov byte [buffer + 80 + di], 179
			mov byte [buffer + 159 + di], 179
			add di,80
			cmp di, 2000
			jnz .next_y
		.corners:
			mov byte [buffer + 80], 218
			mov byte [buffer + 159], 191
			mov byte [buffer + 1920], 192
			mov byte [buffer + 1999], 217
			ret
		
	show_game_over:
			mov si, .text_1
			mov di, 880 + 32
			call buffer_print_string
			mov si, .text_2
			mov di, 960 + 32
			call buffer_print_string
			mov si, .text_1
			mov di, 1040 + 32
			call buffer_print_string
			call buffer_render
			mov si, 48
			call sleep
			call clear_keyboard_buffer
			mov ah, 0
			int 16h
			ret
		.text_1:
			db "               ", 0
		.text_2:
			db "   GAME OVER   ", 0

section .bss
		score resw 1
		is_game_over resb 1

		; 8 = up
		; 4 = down
		; 2 = left
		; 1 = right
		snake_direction resb 1

		snake_head_x resb 1
		snake_head_y resb 1
		snake_head_previous_x resb 1
		snake_head_previous_y resb 1
		snake_tail_x resb 1
		snake_tail_y resb 1
		snake_tail_previous_x resb 1
		snake_tail_previous_y resb 1

		buffer resb 2000
