; ==================================================================
; PC SPEAKER/ADLIB SOUND ROUTINES
; ==================================================================

; ------------------------------------------------------------------
; os_speaker_tone -- Generate PC speaker tone (call os_speaker_off to turn off)
; IN: AX = note frequency; OUT: Nothing (registers preserved)

os_speaker_tone:
	pusha
	cmp byte [0083h], 0
	je near .exit
	popa
	
	pusha
	cmp ax, 0
	je near .exit
	
	call os_speaker_off
	mov cx, ax			; Store note value for now

	mov al, 10110110b
	out 43h, al
	mov dx, 12h			; Set up frequency
	mov ax, 34DCh
	div cx
	out 42h, al
	mov al, ah
	out 42h, al

	in al, 61h			; Switch PC speaker on
	or al, 03h
	out 61h, al

.exit:
	popa
	ret

; ------------------------------------------------------------------
; os_speaker_note_length -- Generate PC speaker tone for a set amount of time and then stop
; IN: AX = note frequency, CX = length (in ticks)

os_speaker_note_length:
	pusha
	call os_speaker_tone
	
	mov ax, cx
	call os_pause
	
	call os_speaker_off
	popa
	ret

; ------------------------------------------------------------------
; os_speaker_off -- Turn off PC speaker
; IN/OUT: Nothing (registers preserved)

os_speaker_off:
	pusha

	in al, 61h
	and al, 0FCh
	out 61h, al

	popa
	ret

; ------------------------------------------------------------------
; os_start_adlib -- Starts the selected Adlib driver
; IN: SI = interrupt handler, CX = prescaler, BL = number of channels
; The interrupt will fire at 33144 Hz (the closest possible to 32768 Hz) divided by CX.
; Common prescaler values:
;		33 = ~1 kHz (1004.362 Hz)
;		663 = ~50 Hz (49.991 Hz)
;		1820 = ~18.2 Hz (18.211 Hz)

os_start_adlib:
	pusha
	mov byte [adlib_running], 1

	cmp byte [57070], 1
	jge .pcspk
	
	mov ax, 0
	
.loop:
	call int_adlib_regwrite
	inc ah
	jnz .loop
	
	mov ax, 36
	mul cx
	
	mov cx, ax
	call os_attach_app_timer
	
	popa
	ret
	
.pcspk:
	mov ax, 36
	div bl
	
	mov [pwm_channel_amplitude], al

	mov [pwm_callback], si
	mov [pwm_callback_ctr], cx
	mov [pwm_callback_ctr_def], cx

	; Set up the PC speaker
	in al, 0x61
	or al, 3
	out 0x61, al

	; Enable the callback
	mov si, pwm_handler
	mov di, cs
	mov cl, 01Ch
	call os_modify_int_handler

	mov cx, 36
	call os_set_timer_speed
	
	popa
	ret
	
; ------------------------------------------------------------------
; os_stop_adlib -- Stops the Adlib driver

os_stop_adlib:
	pusha
	cmp byte [57070], 1
	jge .pcspk
	
	call os_return_app_timer

	mov ah, 0
	
.loop:
	movzx bx, ah
	shr bx, 5
	mov al, [adlib_clear_regs + bx]

	call int_adlib_regwrite
	
	inc ah
	jnz .loop
	
	mov byte [adlib_running], 0
	popa
	ret
	
.pcspk:
	; Turn off the PC speaker
	in al, 0x61
	and al, 0xfc
	out 0x61, al

	mov cx, 0
	call os_set_timer_speed
	
	; Reset the RTC handler
	mov cl, 1Ch
	mov si, os_compat_int1C
	mov di, cs
	call os_modify_int_handler
	
	; Turn off all of the channels
	mov cx, 18		; Not only nuke pwm_freq, but also pwm_cntr!
	mov di, pwm_freq
	mov ax, 0
	rep stosw
	
	popa
	ret
	
	; Registers:    	   0x00  0x20  0x40  0x60  0x80  0xA0  0xC0  0xE0
	adlib_clear_regs	db 0x00, 0x00, 0x3F, 0xFF, 0xFF, 0x00, 0x00, 0x00
	
; ------------------------------------------------------------------
; os_check_adlib -- Checks if YM3812 is present in the system
; OUT: CF clear if YM3812 is present

os_check_adlib:
	pusha
	cmp byte [57070], 1
	jge .ok

	mov ax, 0460h
	call int_adlib_regwrite
	
	mov ax, 0480h
	call int_adlib_regwrite
	
	mov dx, 388h
	in al, dx
	cmp al, 0
	jne .error
	
.ok:
	popa
	clc
	ret
	
.error:
	popa
	stc
	ret
	
; ------------------------------------------------------------------
; os_adlib_regwrite -- Write to a YM3812 register
; IN: AH/AL - register address/value to write

os_adlib_regwrite:
	pusha
	
	movzx bx, ah		; Store the value in the buffer first
	mov [fs:ADLIB_BUFFER + bx], al
	
	call int_adlib_regwrite
	
	popa
	ret
	
; ------------------------------------------------------------------
; os_adlib_regread -- Read from a YM3812 register
; IN: AH - register address; OUT: AL - value

os_adlib_regread:
	push bx
	
	movzx bx, ah		; Store the value in the buffer first
	mov al, [fs:ADLIB_BUFFER + bx]
	
	pop bx
	ret
	
; ------------------------------------------------------------------
; int_adlib_regwrite -- Internal kernel function - not available to user programs
; IN: AH/AL - register address/value to write
	
int_adlib_regwrite:
	pusha

	cmp byte [57070], 1
	jge .pcspk

	cmp byte [adlib_running], 0
	je .no_write

	mov dx, 388h
	push ax
	mov al, ah
	out dx, al

	in al, dx
	in al, dx
	in al, dx
	in al, dx
	in al, dx
	in al, dx
	
	pop ax
	inc dx
	out dx, al

	dec	dx
	mov	ah, 22h

.wait:
	in al,dx
	dec ah
	jnz .wait
	
.no_write:
	popa
	ret

.pcspk:
	cmp ah, 0A0h
	jl .no_write

	cmp ah, 0B8h
	jg .no_write

	and ah, 0Fh
	movzx bx, ah
	
	mov al, [fs:ADLIB_BUFFER + 0A0h + bx]
	mov ah, [fs:ADLIB_BUFFER + 0B0h + bx]
	
	test ah, 20h
	jz .pcspk_clear
	
	mov dl, ah		; Get the block number
	shr dl, 2
	and dl, 7
	
	and ax, 3FFh	; Get the FNum
	
	; WARNING! Due to the 16-bit integer limit (for speed), the maximum is block = 7, FNum = 511.
	; Quick and dirty formula: freq = (fnum << block) / 21

	mov [.shift + 2], dl
	
	.shift: db 0C1h, 0E0h, 0	; Shift AX left by the block number

	push bx
	
	xor dx, dx
	mov bx, 21
	div bx						; Calculate the frequency

	pop bx

	push bx						; Apply the frequency multiplier
	mov bh, 0
	mov bl, [adlib_fmul_registers + bx]
	mov bl, [fs:ADLIB_BUFFER + bx]
	and bl, 0Fh
	mov bl, [adlib_fmul_values + bx]
	
	mul bx
	pop bx
	
	shl bx, 1		; Words
	mov word [pwm_freq + bx], ax

	popa
	ret
	
.pcspk_clear:
	shl bx, 1		; Words
	mov word [pwm_freq + bx], 0
	
	popa
	ret
	
	adlib_fmul_values		db 1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 20, 24, 24, 30, 30
	adlib_fmul_registers	db 23h, 24h, 25h, 2Bh, 2Ch, 2Dh, 33h, 34h, 35h
	
; ------------------------------------------------------------------
; os_adlib_mute -- Mute the YM3812's current state
; IN: nothing

os_adlib_mute:
	pusha
	
	cmp byte [57070], 1
	jge .pcspk
	
	mov si, adlib_volume_registers
	mov cx, 18
	
.loop:
	lodsb
	mov ah, al
	
	call os_adlib_regread
	or al, 3Fh
	call int_adlib_regwrite
	
	loop .loop
	popa
	ret

.pcspk:
	mov byte [pwm_muted], 1
	popa
	ret
	
; ------------------------------------------------------------------
; os_adlib_unmute -- Unmute the YM3812's current state
; IN: nothing

os_adlib_unmute:
	pusha

	cmp byte [57070], 1
	jge .pcspk
	
	mov si, adlib_volume_registers
	mov cx, 18
	
.loop:
	lodsb
	mov ah, al
	
	call os_adlib_regread
	call int_adlib_regwrite
	
	loop .loop
	popa
	ret
	
.pcspk:
	mov byte [pwm_muted], 0
	popa
	ret

	adlib_volume_registers	db 40h, 41h, 42h, 43h, 44h, 45h, 48h, 49h, 4Ah, 4Bh, 4Ch, 4Dh, 50h, 51h, 52h, 53h, 54h, 55h
	adlib_running			db 0

; ------------------------------------------------------------------
; PWM DRIVER
; What is emulated: FNum, block number, carrier frequency multiplier
; What is NOT emulated: literally everything else - amplitude, ADSR, waveforms, modulator

pwm_handler:
	cli
	pusha
	push ds
	
	mov ax, cs
	mov ds, ax
	
	cmp byte [pwm_muted], 1
	je .no_spk

	; Send the PWM value to the PC speaker
	mov al, 10110000b
	out 0x43, al
	mov al, [pwm_val]
	out 0x42, al
	mov al, 0
	out 0x42, al

	; Calculate the next value
	mov cx, 9
	mov si, pwm_freq
	mov di, pwm_cntr - 2
	mov bl, 0
	
	mov dl, [pwm_channel_amplitude]
	
	cmp byte [57070], 2
	jne .handler_loop
	
	; Max volume mode, count the number of active channels
	push si
	push cx
	
	clr bx
	
.channel_count_loop:
	lodsw
	
	cmp ax, 0
	je .channel_count_loop_no_inc
	
	inc bx
	
.channel_count_loop_no_inc:
	loop .channel_count_loop
	
	pop cx
	pop si
	
	mov dl, [pwm_fixed_amplitudes + bx]

	; Add all of the channels together
.handler_loop:
	lodsw
	
	cmp ax, 0
	je .handler_loop_no_inc
	
	add di, 2
	add [di], ax
	
	jns .handler_loop_no_inc
	
	add	bl, dl

.handler_loop_no_inc:
	loop .handler_loop
	
	inc bl
	mov [pwm_val], bl
	
.no_spk:
	; Have we reached the callback value?	
	dec word [pwm_callback_ctr]
	jnz .exit

	; Yes, reset it
	mov ax, [pwm_callback_ctr_def]
	mov [pwm_callback_ctr], ax
	
	; Call the callback
	call [pwm_callback]
	
.exit:
	pop ds
	popa
	iret

	pwm_freq				times 9 dw 0
	pwm_cntr				times 9 dw 0
	pwm_muted				db 0
	pwm_callback			dw 0
	pwm_callback_ctr		dw 0
	pwm_callback_ctr_def	dw 0
	pwm_val					db 0
	pwm_channel_amplitude	db 0
	pwm_fixed_amplitudes	db 0, 36, 18, 12, 9, 7, 6, 5, 4, 4
	
; ------------------------------------------------------------------
; os_adlib_calcfreq -- Play a frequency
; IN: AX - frequency, CL = channel; OUT: nothing

os_adlib_calcfreq:
	pushad

	cmp byte [57070], 1
	jge .pcspk

	mov [.channel], cl
	
	movzx eax, ax
	mov cl, 0		; Block number
	
	push eax

.block_loop:		; f-num = freq * 2^(20 - block) / 49716
	pop eax
	push eax
	
	mov bl, 20
	sub bl, cl
	
	mov [.shift + 3], bl
.shift: db 0x66, 0xc1, 0xe0, 0		; shl eax, XX

	clr edx
	mov ebx, 49716	; Divide by the sample rate
	div ebx

	inc cl
	
	cmp ax, 1024	; Is the result too large?
	jge .block_loop
	
	dec cl
	
	shl cl, 2		; Write the block number
	add ah, cl

	or ah, 20h		; Note on
	
	push ax
	mov ah, 0A0h
	add ah, [.channel]
	call os_adlib_regwrite
	pop ax
	
	mov al, ah
	mov ah, 0B0h
	add ah, [.channel]
	call os_adlib_regwrite
	
	pop eax
	popad
	ret
	
.pcspk:
	movzx bx, cl
	shl bx, 1
	shl ax, 1
	mov [pwm_freq + bx], ax
	popad
	ret
	
	.channel	db 0
	
; ------------------------------------------------------------------
; os_adlib_noteoff -- Turns off a note
; IN: CL = channel; OUT: nothing

os_adlib_noteoff:
	cmp byte [57070], 1
	jge .pcspk
	
	pusha

	mov ah, 0B0h
	add ah, cl
	call os_adlib_regread
	
	and al, 11011111b
	call os_adlib_regwrite
	
	popa
	ret
	
.pcspk:
	pusha
	movzx bx, cl
	shl bx, 1
	mov word [pwm_freq + bx], 0
	popa
	ret	
	
; ==================================================================

