polypiano:
	call start.draw_background
	
	call os_check_adlib
	jc .adliberror
	
.error_bypass:
	mov ax, buffer
	mov bx, .channelmsg
	call os_input_dialog
	
	mov si, buffer
	call os_string_to_int
	
	cmp al, 9
	jg .error

	cmp al, 1
	jl .error
	
.init_adlib:
	mov byte [.currentchannel], 0
	mov [.numofchannels], al

	mov si, .dummyinterrupt
	mov cx, 1820
	mov bl, al
	call os_start_adlib
	
	mov cx, 7					; We will only read 7 registers here
	mov si, .adlibsquare
	
.preparechannels:
	lodsw
	
	push cx
	clr bx
	mov cx, 9
	
.channelloop:
	push ax
	add ah, [.adliboffsets + bx]
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
	je .end
	
	mov si, start.keydata1
	mov di, start.notedata1
	
.decodeloop:
	mov bh, [si]
	inc si
	add di, 2
	
	test bh, bh
	jz .pianoloop
	
	cmp ah, bh
	jne .decodeloop
	
	sub di, 2				; We've overflowed a bit
	mov ax, [di]
	
	mov bl, [start.octave]
	mov cl, 6
	sub cl, bl
	shr ax, cl
	
	mov cl, [.currentchannel]	
	call os_adlib_calcfreq
	
	inc cl
	cmp cl, [.numofchannels]
	jne .no_reset_counter

	clr cl
	
.no_reset_counter:
	mov [.currentchannel], cl
	
	jmp .pianoloop
	
.octave_down:
	cmp byte [start.octave], 1
	jle .pianoloop
	dec byte [start.octave]
	jmp .pianoloop
	
.octave_up:
	cmp byte [start.octave], 6
	jge .pianoloop
	inc byte [start.octave]
	jmp .pianoloop
	
.execstop:
	clr cl
	
.stoploop:
	call os_adlib_noteoff

	inc cl
	cmp cl, 9
	jne .stoploop
	
	jmp .pianoloop
	
.end:
	call os_stop_adlib
	jmp start

.dummyinterrupt:
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
	jmp start
	
.error:
	mov ax, .channelerr
	mov bx, .channelerr2
	clr cx
	clr dx
	call os_dialog_box
	
	mov al, 9
	jmp .init_adlib
	
	.currentchannel		db 0
	.numofchannels		db 0
	
	.adlibsquare		db 02h, 20h
						db 01h, 23h
						db 19h, 40h
						db 0F0h,60h
						db 0F0h,63h
						db 0F0h,80h
						db 0FFh,83h
						db 0Eh, 0C0h
						
	.adliboffsets		db 0, 1, 2, 8, 9, 10, 16, 17, 18

	.channelmsg			db 'How many notes at once? (1-9)', 0
	.channelerr			db 'Number not in range.', 0
	.channelerr2		db 'Defaulted to 9 notes.', 0
