; ------------------------------------------------------------------
; MichalOS Music Player - duo MMF decoder
; ------------------------------------------------------------------

start_poly_mmf:
	mov [.filesize], bx

	call start.draw_player_background

	call os_check_adlib
	jc .adliberror
	
.error_bypass:
	clr dx
	mov ax, [buffer]
	cmp ax, 0
	jne .no_18_2
	
	inc dx
	
.no_18_2:
	mov bx, 36
	div bx
	
	mov si, .int_handler
	mov cx, ax
	mov bl, 2
	call os_start_adlib
	
	mov cx, 7					; We will only read 7 registers here
	mov si, polypiano.adlibsquare
	
.preparechannels:
	lodsw
	
	push cx
	clr bx
	mov cx, 9
	
.channelloop:
	push ax
	add ah, [polypiano.adliboffsets + bx]
	inc bx
	
	call os_adlib_regwrite
	pop ax
	
	loop .channelloop
	
	pop cx
	loop .preparechannels
	
	lodsw
	
.feedbackloop:					; Write the 8th register
	call os_adlib_regwrite
	inc ah
	cmp ah, 0C9h
	jne .feedbackloop
	
	mov si, .playmsg1
	mov bx, start_dro.playmsg2
	call create_player_box

.play_loop:
	mov dx, 0C26h
	call os_move_cursor
	
	mov ax, [.counter]
	call os_int_to_string
	mov si, ax
	call os_print_string

	movzx eax, word [.pointer_2]
	sub eax, buffer2 + 3
	movzx ebx, word [.filesize]
	call draw_progress_bar

	call os_check_for_key
	cmp al, 27
	je .exit
	cmp al, 32
	je .pause
	
	hlt

	cmp byte [.song_end], 1
	jne .play_loop

.exit:
	call os_stop_adlib

	mov word [.pointer], .track0	; Reset the values when we press Esc
	mov byte [.delay], 1
	
	mov word [.pointer_2], .track0_2
	mov byte [.delay_2], 1

	mov word [.counter], 0
	mov byte [.paused], 0
	mov byte [.song_end], 0
	ret
	
.pause:
	xor byte [.paused], 1
	jmp .play_loop
	
.int_handler:
	mov cl, 0			; Channel

	cmp byte [.paused], 0
	jne .skip_play
	
	dec byte [.delay]
	jnz .int_handler_2
	
	mov al, [.song_delay]
	mov [.delay], al
	
	inc word [.counter]

	mov si, [.pointer]
	lodsw
	mov [.pointer], si
	
	cmp ax, 0
	je near .notone
	
	cmp ax, 1
	je near .end
	
	call os_adlib_calcfreq

.int_handler_2:
	mov cl, 1			; Channel

	dec byte [.delay_2]
	jnz .skip_play
	
	mov al, [.song_delay_2]
	mov [.delay_2], al
	
	mov si, [.pointer_2]
	lodsw
	mov [.pointer_2], si
	
	cmp ax, 0
	je near .notone_2
	
	cmp ax, 1
	je near .end
	
	call os_adlib_calcfreq
	
.skip_play:
	ret
	
.notone:
	call os_adlib_noteoff
	jmp .int_handler_2
	
.notone_2:
	call os_adlib_noteoff
	ret
	
.end:
	mov byte [.song_end], 1
	ret
	
.adliberror:
	mov byte [0085h], 1
	
	mov ax, start.adlib_msg1
	mov bx, start.adlib_msg2
	clr cx
	mov dx, 1
	call os_dialog_box
	mov byte [0085h], 0
	
	cmp ax, 0
	je .error_bypass
	
	ret
	
	.playmsg1	db 'Now playing: <duo>', 0
	
	.pointer	dw .track0
	.delay		db 1

	.pointer_2	dw .track0_2
	.delay_2	db 1

	.counter	dw 0
	.paused		db 0
	.song_end	db 0

	.filesize	dw 0
	
	.song_delay		equ buffer + 2
	.song_delay_2	equ buffer2 + 2
	.track0			equ buffer + 3
	.track0_2		equ buffer2 + 3
