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
	test ax, ax
	jnz .no_18_2
	
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

	mov si, .playmsg
	mov bx, start_dro.playmsg2
	call create_player_box

	mov al, [.song_delay]
	mov [.sdelay], al

	mov al, [.song_delay_2]
	mov [.sdelay_2], al

	mov word [.pointer], .track0	; Reset the values when we press Esc
	mov byte [.delay], 1
	
	mov word [.pointer_2], .track0_2
	mov byte [.delay_2], 1

	mov word [.counter], 0
	mov byte [.paused], 0
	mov byte [.song_end], 0

	mov byte [.playreq], 0

.play_loop:
	cmp byte [.playreq], 1
	jne .no_play

	mov byte [.playreq], 0

	cmp byte [.paused], 0
	jne .no_play

	clr cl		; Channel
	mov di, .pointer
	call .parse_channel

	inc cl
	mov di, .pointer_2
	call .parse_channel
	
.no_play:
	mov dx, 0C26h
	call os_move_cursor
	
	mov ax, [.counter]
	call os_print_int

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

.parse_channel:
	dec byte [di + 3]	; Delay value
	jnz .no_parse_channel
	
	mov al, [di + 2] 	; Global song delay value
	mov [di + 3], al
	
	test cl, cl
	jnz .no_inc_ctr

	inc word [.counter]

.no_inc_ctr:
	mov si, [di]		; Current pointer
	lodsw
	mov [di], si
	
	test ax, ax
	jz .notone
	
	cmp ax, 1
	je .mark_end
	
	call os_adlib_calcfreq

.no_parse_channel:
	ret

.notone:
	call os_adlib_noteoff
	ret

.mark_end:
	mov byte [.song_end], 1
	ret

.exit:
	call os_stop_adlib
	ret
	
.pause:
	xor byte [.paused], 1

	call os_adlib_mute

	cmp byte [.paused], 1
	je .play_loop

	call os_adlib_unmute

	jmp .play_loop
	
.int_handler:
	mov byte [.playreq], 1
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
	
	ret
	
	.pointer	dw .track0
	.sdelay		db 0
	.delay		db 1

	.pointer_2	dw .track0_2
	.sdelay_2	db 0
	.delay_2	db 1

	.counter	dw 0
	.paused		db 0
	.song_end	db 0

	.playreq	db 0
	.filesize	dw 0
	
	.playmsg	db 'Now playing: '
	.playmsg2	times 32 db 0 

	.playmsgcct	db '/', 0

	.song_delay		equ buffer + 2
	.song_delay_2	equ buffer2 + 2
	.track0			equ buffer + 3
	.track0_2		equ buffer2 + 3
