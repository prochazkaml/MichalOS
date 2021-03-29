; ==================================================================
; KEYBOARD HANDLING ROUTINES
; ==================================================================

; ------------------------------------------------------------------
; os_wait_for_key -- Waits for keypress and returns key
; Also handles the screensaver. TODO: move the screensaver code to "int.asm"
; IN: Nothing; OUT: AX = key pressed, other regs preserved

os_wait_for_key:
	pusha
	
.try_again:
	mov bh, 0
	call .screen_power

	; Reset the screensaver tick
	movzx ax, byte [57074]
	mov bx, 1092		; 18.2 Hz * 60 seconds
	mul bx
	mov [screensaver_timer], ax		; See "int.asm"
	
	mov byte [.scrn_active], 0	; Reset all the screensaver variables

	mov al, [0082h]				; Save the current screen state, for later
	mov [.gfx_state], al
	mov ah, 03h
	mov bh, 0
	int 10h
	mov [.orig_crsr], cx		; Get the shape of the cursor
	
.loop:
	hlt							; Halt the CPU for 1/18.2 seconds, to save the CPU usage
	call .screensaver
	call os_check_for_key
	
	cmp ax, 0
	je .loop

	pusha
	mov ax, 0500h
	int 10h
	
	mov al, [.gfx_state]
	mov [0082h], al
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
	cmp word [screensaver_timer], 0
	jne .good
	
	cmp byte [57074], 0
	je .good
	
	mov ah, 0Fh
	int 10h
	
	cmp al, 3
	jne .good
	
	pusha
	mov byte [0082h], 1
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
; IN: Nothing; OUT: AX = 0 if no key pressed, otherwise scan code

os_check_for_key:
	pusha

	mov ah, 11h			; BIOS call to check for key
	
	int 16h
		
	jz .nokey			; If no key, skip to end

	mov ah, 10h			; Otherwise get it from buffer
	int 16h

	call special_keys

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

; Checks for special keys and performs their action.
; IN: AX = key
; OUT: nothing
special_keys:
	pusha
	cmp ah, 105
	je near .disable_sound
	cmp ah, 106
	je near .enable_sound
	cmp ah, 107
	je near .exit_app
	cmp ah, 139
	je near .intended_system_crash
	popa
	ret
	
.intended_system_crash:
	mov ax, .crash_msg
	call os_fatal_error
	
	.crash_msg		db 'Intended system crash', 0
	
.exit_app:
	cmp byte [app_running], 0
	je near .no_exit
	
	popa
	
	mov sp, [origstack]
	sub sp, 2
	
	ret
	
.no_exit:
	popa
	ret
		
.enable_sound:
	mov byte [0083h], 1
	jmp .display_speaker
	
.disable_sound:
	mov byte [0083h], 0
	call os_speaker_off

.display_speaker:
	cmp byte [0082h], 1
	je .no_display_spkr

	call os_get_cursor_pos
	push dx
	mov dx, 79			; Print the little speaker icon
	call os_move_cursor
	
	mov ax, 0E17h
	mov bh, 0
	cmp byte [0083h], 0
	je .no_crossed_spkr
	
	dec al
	
.no_crossed_spkr:
	int 10h
	pop dx
	call os_move_cursor
	
.no_display_spkr:
	popa
	ret
	
; ==================================================================

