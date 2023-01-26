; ==================================================================
; MichalOS Keyboard input handling functions
; ==================================================================

; ------------------------------------------------------------------
; os_wait_for_key -- Waits for keypress and returns key
; Also handles the screensaver. TODO: move the screensaver code to "int.asm"
; IN: None
; OUT: AX = key pressed, other regs preserved

os_wait_for_key:
	pusha
	
.try_again:
	clr bh
	call .screen_power

	; Reset the screensaver tick
	movzx eax, byte [CONFIG_SCREENSAVER_MINUTES]
	mov ebx, [current_timer_freq]	; Multiply by the number of ticks per minute
	mul ebx
	mov [screensaver_timer], eax	; See "int.asm"
	
	mov byte [.scrn_active], 0	; Reset all the screensaver variables

	mov al, [system_ui_state]				; Save the current screen state, for later
	mov [.gfx_state], al
	mov ah, 03h
	clr bh
	int 10h
	mov [.orig_crsr], cx		; Get the shape of the cursor
	
.loop:
	hlt							; Halt the CPU for 1/18.2 seconds, to save the CPU usage
	call .screensaver
	call os_check_for_key
	
	test ax, ax
	jz .loop

	pusha
	mov ax, 0500h
	int 10h
	
	mov al, [.gfx_state]
	mov [system_ui_state], al
	mov cx, [.orig_crsr]
	mov ah, 01h
	int 10h
	popa
	
	cmp byte [.scrn_active], 1
	je .try_again
	
	mov [.tmp_buf], ax

	popa
	mov ax, [.tmp_buf]
	ret
	
.screensaver:
	cmp dword [screensaver_timer], 0
	jne .good
	
	cmp byte [CONFIG_SCREENSAVER_MINUTES], 0
	je .good
	
	mov ah, 0Fh
	int 10h
	
	cmp al, 3
	jne .good
	
	pusha
	mov byte [system_ui_state], 1
	mov ax, 0501h
	int 10h
	call os_hide_cursor
	mov byte [.scrn_active], 1

	mov bh, 4
	call .screen_power
	popa

.good:
	ret
	
.screen_power:
	cmp bh, [.scrn_power]
	je .good

	pusha
	mov ax, 4F10h
	mov bl, 1
	mov [.scrn_power], bh
	int 10h
	popa
	ret
	
	.tmp_buf		dw 0
	.gfx_state		db 0
	.orig_crsr		dw 0
	.scrn_active	db 0
	.scrn_power		db 0
	
; ------------------------------------------------------------------
; os_check_for_key -- Scans keyboard buffer for input, but doesn't wait
; Also handles special keyboard shortcuts.
; IN: None
; OUT: AX = 0 if no key pressed, otherwise scan code

os_check_for_key:
	pusha

	mov ah, 11h			; BIOS call to check for key
	
	int 16h
		
	jz .nokey			; If no key, skip to end

	mov ah, 10h			; Otherwise get it from buffer
	int 16h

	call int_special_keys

	mov [.tmp_buf], ax		; Store resulting keypress

	popa				; But restore all other regs
	mov ax, [.tmp_buf]
	ret

.nokey:
	popa
	clr ax			; Zero result if no key pressed
	ret


	.tmp_buf	dw 0


; ==================================================================

; ------------------------------------------------------------------
; int_special_keys -- Checks for special keys and performs their action.
; IN: AX = key
; OUT: None, registers preserved

int_special_keys:
	pusha
	cmp ah, 105
	je .disable_sound
	cmp ah, 106
	je .enable_sound
	cmp ah, 107
	je .exit_app
	popa
	ret
	
.exit_app:
	cmp byte [app_running], 0
	je .no_exit
	
	popa
	
	mov sp, [origstack]
	sub sp, 2
	
	ret
	
.no_exit:
	popa
	ret
		
.enable_sound:
	mov byte [0083h], 1

	mov ax, [speaker_period]

	cmp ax, 1
	je .no_play_note
	
	call os_speaker_raw_period

.no_play_note:
	jmp .display_speaker
	
.disable_sound:
	mov byte [0083h], 0
	call os_speaker_off

.display_speaker:
	cmp byte [system_ui_state], 1
	je .no_display_spkr

	call os_get_cursor_pos
	push dx
	mov dx, 79			; Print the little speaker icon
	call os_move_cursor
	
	mov ax, 0E17h
	clr bh
	cmp byte [0083h], 0
	je .no_crossed_spkr
	
	dec al
	
.no_crossed_spkr:
	int 10h
	pop dx
	call os_move_cursor
	
.no_display_spkr:
	popa
	clr ax
	ret
	
; ==================================================================

