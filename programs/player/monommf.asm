; ------------------------------------------------------------------
; MichalOS Music Player - mono MMF decoder
; ------------------------------------------------------------------

start_mono_mmf:
	push bx

	mov ax, bx
	mov cx, buffer
	call os_load_file

	sub bx, 3
	mov [.filesize], bx
	
	mov cx, [buffer]
	call os_set_timer_speed
	
	call start.draw_player_background
	mov ax, .msgstart
	clr bx
	clr cx
	clr dx
	call os_dialog_box
	
	mov si, start_dro.playmsg1
	mov bx, start_dro.playmsg2
	call create_player_box
	
	mov dx, 0A21h
	call os_move_cursor
	pop si
	call os_print_string

.play_loop:
	call .int_handler
	call os_check_for_key
	
	cmp al, 27
	je .exit
	cmp al, 32
	je .pause
	
	mov ax, 1
	call os_pause
	
	cmp word [.pointer], .track0
	jne .play_loop
	cmp byte [.delay], 0
	jne .play_loop

.exit:
	mov word [.pointer], .track0	; Reset the values when we press Esc
	mov word [.previous], 0
	mov word [.counter], 0
	mov byte [.paused], 0
	
	clr cx					; 18.2 Hz
	call os_set_timer_speed
	ret
	
.pause:
	xor byte [.paused], 1
	jmp .play_loop
	
.int_handler:
	pusha
	cmp byte [.paused], 0
	jne .skip_play
	
	inc byte [.delay]
	mov al, [.song_delay]
	cmp byte [.delay], al
	jl .skip_play
	
	inc word [.counter]
	pusha
	mov dx, 0C26h
	call os_move_cursor
	mov ax, [.counter]
	call os_print_int
	popa
	
	movzx eax, word [.pointer]
	sub eax, buffer + 3
	movzx ebx, word [.filesize]
	call draw_progress_bar

	mov byte [.delay], 0
	
	mov si, [.pointer]
	lodsw
	mov [.pointer], si
	
	cmp ax, [.previous]
	je .skip_play
	
	mov [.previous], ax
	
	test ax, ax
	jz .notone
	
	cmp ax, 1
	je .end
	
	call os_speaker_tone
	
.skip_play:
	popa
	ret
	
.notone:
	call os_speaker_off
	popa
	ret
	
.end:
	call os_speaker_off
	mov word [.pointer], .track0
	popa
	ret

	.previous	dw 0
	.pointer	dw .track0
	.filesize	dw 0
	.counter	dw 0
	.delay		db 0
	.paused		db 0
	.song_delay	equ buffer + 2
	.track0		equ buffer + 3
 	.msgstart	db 'Press OK to start...', 0
