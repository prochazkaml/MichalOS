piano:
	call start.draw_clear_background
	
	mov16 dx, 1, 9
	call os_move_cursor
	mov si, start.piano0
	call os_print_string
	call os_hide_cursor
	
.pianoloop:
	mov16 dx, 1, 17
	call os_move_cursor

	mov si, start.octavemsg
	call os_print_string
	
	mov al, [start.octave]
	call os_print_1hex
	
	call os_wait_for_key

	cmp ah, 72
	je .octave_up
	
	cmp ah, 80
	je .octave_down
	
	cmp al, ' '
	je .execstop
	
	cmp al, 27
	je start
	
	mov si, start.keydata1
	mov di, start.notedata1
	
.decodeloop:
	mov bh, [si]
	inc si
	add di, 2
	
	cmp bh, 0
	je .pianoloop
	
	cmp ah, bh
	jne .decodeloop
	
	sub di, 2				; We've overflowed a bit
	mov ax, [di]
	
	mov bl, [start.octave]
	mov cl, 6
	sub cl, bl
	shr ax, cl
	
	call os_speaker_tone
	
	jmp .pianoloop
	
.octave_down:
	cmp byte [start.octave], 1
	je .pianoloop
	dec byte [start.octave]
	jmp .pianoloop
	
.octave_up:
	cmp byte [start.octave], 6
	je .pianoloop
	inc byte [start.octave]
	jmp .pianoloop
	
.execstop:
	call os_speaker_off
	jmp .pianoloop
	
