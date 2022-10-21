; ------------------------------------------------------------------
; MichalOS Music Player - DRO decoder
; ------------------------------------------------------------------

start_drz:
	call os_check_adlib
	jc start_dro.adliberror

.error_bypass:
	popa

	push bx
	
	push es
	mov ax, gs
	add ax, 2000h		; Scratch segment
	mov es, ax
	mov ax, bx
	clr cx
	call os_load_file
	pop es
	
	jc start_dro.stop

	push ds
	push es
	
	mov ax, gs
	mov es, ax
	add ax, 2000h
	mov ds, ax
	clr si
	clr di

	; The file contains several compressed 64 kB chunks, so decompress each one

	lodsb				; Load the number of chunks
	movzx cx, al

.loadsegloop:
	lodsw				; Load the compressed chunk pointer

	push si
	mov si, ax

	push cx
	call os_decompress_zx7	; Decompress the chunk
	pop cx
	pop si

	mov ax, es
	add ax, 1000h		; Point to the next segment
	mov es, ax
	clr di

	loop .loadsegloop

	pop es
	pop ds

	jmp start_dro.dro_post_load

start_dro:
	call os_check_adlib
	jc .adliberror

.error_bypass:
	popa

	push bx
	
	push es
	mov ax, gs
	mov es, ax
	mov ax, bx
	clr cx
	call os_load_file
	pop es
	
	jc .stop

.dro_post_load:	
	call start.draw_player_background
	
	mov si, .playmsg1
	mov bx, .playmsg2
	call create_player_box
	
	mov dx, 0A21h
	call os_move_cursor
	
	pop si
	call os_print_string
	
.dro_decode:
	mov byte [.play], 0
	mov dword [.current_pos], 0
	mov word [.timer], 0
	
	call .clear_adlib

	mov eax, [gs:10h]	; Song length in miliseconds
	shr eax, 10			; Waaay faster than dividing by 1000
	mov [.song_length], ax
	
	mov al, [gs:17h]
	mov [cs:.short_delay], al
	mov al, [gs:18h]
	mov [cs:.long_delay], al
	mov al, [gs:19h]	; Codemap length

	movzx bx, al
	mov [.codemap], bx
	
	and eax, 000000FFh
	add eax, 1Ah	; Get the data start

	mov [.position_offset], ax
	mov word [.position_segment], 0
	
	add eax, [gs:0Ch]	; Add the song length
	
	shl eax, 1			; Register pairs -> offset
	mov [.length_offset], ax
	
	shr eax, 4			; Get the segment
	and ax, 0F000h
	mov [.length_segment], ax
	
	call os_stop_adlib

	mov si, .int_handler
	mov cx, 33
	mov bl, 9
	call os_start_adlib

	jmp .noplaypause
	
.loop:
	; Check the keys
	
	call os_check_for_key
	cmp al, 27
	je .stop
	cmp al, 32
	jne .noplaypause

	xor byte [.play], 1
	
	cmp byte [.play], 0
	je .unmute
	jne .mute
	
.noplaypause:
	; Display the info
	
	pushad

	mov eax, [.current_pos]
	mov ebx, [gs:10h]
	call draw_progress_bar

	test ax, 1111111111b
	jnz .no_update_timer

	shr eax, 10			; Waaay faster than dividing by 1000
	
	mov dx, 0C26h
	call os_move_cursor

	call os_int_to_string
	mov si, ax
	call os_print_string
		
	mov al, 73h			; Print an "s"
	call os_putchar
	
	mov al, 2Fh			; "/"
	call os_putchar
	
	mov ax, [.song_length]
	call os_int_to_string
	mov si, ax
	call os_print_string
	
	mov si, .end_time_msg
	call os_print_string
	
.no_update_timer:
	popad
	
	; DRO parsing
	cmp word [.timer], 0
	jne .loop

	mov ax, [.position_segment]
	cmp ax, [.length_segment]
	jne .no_reset

	mov ax, [.position_offset]
	cmp ax, [.length_offset]
	je .dro_decode
	
.no_reset:
	push es
	mov ax, [.position_segment]
	mov bx, gs
	add ax, bx
	mov es, ax
	
	mov si, [.position_offset]
	mov ax, [es:si]
	pop es
	
	add word [.position_offset], 2
	jnc .no_segment_inc
	
	add word [.position_segment], 1000h
	
.no_segment_inc:
	xchg ah, al
	
	cmp ah, [.short_delay]
	je .do_short
	
	cmp ah, [.long_delay]
	je .do_long
	
	movzx bx, ah			; Decode the command
	cmp bx, [.codemap]
	jg .loop
	
	mov ah, [gs:1Ah + bx]
	call os_adlib_regwrite
	
	jmp .loop

.unmute:
	call os_adlib_unmute
	jmp .noplaypause
	
.mute:
	call os_adlib_mute
	jmp .noplaypause

.do_short:
	pusha
	inc al
	mov [.timer], al
	popa
	jmp .loop
	
.do_long:
	pusha
	mov ah, al
	inc ah
	clr al
	mov [.timer], ax
	popa
	jmp .loop
	
.wait_stop:
	popa
	
.stop:
	call os_stop_adlib
	
	jmp start
	
.clear_adlib:
	clr ax
	
.exit_loop:
	call os_adlib_regwrite
	inc ah
	jnz .exit_loop
	
	ret

.not_enough_ram:
	popa
	mov ax, .no_ram
	clr bx
	clr cx
	clr dx
	call os_dialog_box
	
	jmp start

.int_handler:
	cmp byte [.play], 1
	je .no_dec_timer
	
	cmp word [.timer], 0
	je .no_dec_timer
	
	inc dword [.current_pos]

	dec word [.timer]

.no_dec_timer:
	ret
	
.adliberror:
	mov byte [0085h], 1
	
	mov ax, start.adlib_msg1
	mov bx, start.adlib_msg2
	clr cx
	mov dx, 1
	call os_dialog_box
	mov byte [0085h], 0
	
	test ax, ax
	jz .error_bypass
	
	popa
	jmp start.play_file

	.short_delay		db 0
	.long_delay			db 0
	.position_offset	dw 0
	.position_segment	dw 0
	.length_offset		dw 0
	.length_segment		dw 0
	
	.current_pos		dd 0
	.song_length		dw 0
	
	.codemap			dw 0
	.timer				dw 0
	.play				db 0
	
	.no_ram				db 'Not enough memory!', 0
	.millilength_msg	db 'Song length (in milliseconds): ', 0
	.position_msg		db 'Current position (milliseconds): ', 0
	.playmsg1			db 'Now playing:', 0
	.playmsg2			db 'Current position:', 0
	.end_time_msg		db 's    ', 0
