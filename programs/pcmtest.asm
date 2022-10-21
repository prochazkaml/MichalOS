; ------------------------------------------------------------------
; MichalOS PC Speaker PCM Demo
;
; WARNING: This demo uses the top 1.44 MB of a 2.88 MB disk.
; To generate a compatible image, run your favorite song through
; FFmpeg to convert it to a 11025 Hz 8-bit PCM file:
; 
; ffmpeg -i <inputfile> -f u8 -acodec pcm_u8 -ac 1 -ar 11025 <outputfile>
; 
; Then, move the output file to files/gitignore/288data. After that,
; you can generate the 2.88 MB image by running:
; 
; make big
; ------------------------------------------------------------------

	%include "michalos.inc"
	bits    16
	org     100h

	counter			equ	0x1234DC / 11025

start:
	call os_hide_cursor
	
	mov ax, .titlemsg
	mov bx, .footermsg
	mov cx, 256
 	call os_draw_background
	
	;; Load data sector
	mov bx, 8192
	mov ax, 2880
	call os_convert_l2hts
	mov ah, 2
	mov al, 8
	int 13h
	jnc .no_error

	mov ax, .error_msg1
	mov bx, .error_msg2
	mov cx, .error_msg3
	mov dx, 1
	call os_dialog_box

	test ax, ax
	jnz .appexit

.no_error:
	clr si
	clr ax
	clr bx
	clr cx
	clr dx
	call os_temp_box

	;; Replace IRQ0 with our sound code
	mov     si, tick
	call os_attach_app_timer

	;; Attach the PC Speaker to PIT Channel 2
	in      al, 0x61
	or      al, 3
	out     0x61, al

	;; Reprogram PIT Channel 0 to fire IRQ0 at 16kHz
	cli
	mov     al, 0x36
	out     0x43, al
	mov     ax, counter
	out     0x40, al
	mov     al, ah
	out     0x40, al
	sti

	;; Keep processing interrupts until it says we're done

.mainlp:
	hlt
	call os_check_for_key
	cmp al, "1"
	je .dec_volume
	cmp al, "2"
	je .inc_volume
	cmp al, 32
	je .playpause
	cmp al, 27
	je .exit
	
	; Load new sectors if necessary

	mov ax, [offset]
	and ax, 0x1000
	cmp ax, [.previous_block]
	je .no_load

	mov [.previous_block], ax
	xor ax, 0x1000
	mov bx, 8192
	add bx, ax
	
	mov ax, [.current_position]
	cmp ax, 2880 * 2
	jne .no_reset

	mov ax, 2880
	mov [.current_position], ax
	mov word [.loadedbuffers], 0

.no_reset:
	call os_convert_l2hts
	mov ah, 2
	mov al, 8
	int 13h

	add word [.current_position], 8
	inc word [.loadedbuffers]

.no_load:
	; Draw the VU meter
	
	mov dl, 24
	mov dh, 14
	call os_move_cursor

	mov cx, 32
	mov bx, 7
	mov ax, 0920h
	int 10h

	mov si, [offset]
	movzx cx, byte [si]
	cmp cx, 80h
	jge .subtract
	
	mov al, 80h
	sub al, cl
	mov cl, al
	jmp .done
	
.subtract:
	sub cl, 80h

.done:
	shr cx, 2
	
	mov ax, 09DBh
	int 10h
	
.no_display:
	; Show how many samples have been read
	
	mov dl, 20
	mov dh, 10
	call os_move_cursor
	
	mov ax, [.loadedbuffers]
	call os_int_to_string
	mov si, ax
	call os_print_string

	mov si, .buffmsg
	call os_print_string

	mov ax, [.loadedbuffers]
	shl ax, 2
	call os_int_to_string
	mov si, ax
	call os_print_string

	mov si, .buffmsg2
	call os_print_string

	; Show how long has the song been playing
	
	mov dl, 20
	mov dh, 12
	call os_move_cursor
	
	clr edx
	movzx eax, word [.loadedbuffers]
	shl eax, 12
	mov ebx, 11025
	div ebx
	
	call os_int_to_string
	mov si, ax
	call os_print_string
	
	mov si, .secondmsg
	call os_print_string
	
	cmp word [done], 0
	je .mainlp
	
.exit:
	;; Restore original IRQ0
	
	call os_return_app_timer

	mov     al, 0x36        ; ... and slow the timer back down
	out     0x43, al        ; to 18.2 Hz
	xor     al, al
	out     0x40, al
	out     0x40, al
	
	;; Turn off the PC speaker
	in      al, 0x61
	and     al, 0xfc
	out     0x61, al

.appexit:
	;; And quit with success
	ret
	
.playpause:
	xor byte [pausestate], 1
	jmp .mainlp
	
.inc_volume:
	cmp byte [shr_value], 00h
	je .mainlp
	
	dec byte [shr_value]
	jmp .mainlp
	
.dec_volume:
	cmp byte [shr_value], 07h
	je .mainlp
	
	inc byte [shr_value]
	jmp .mainlp
	
	.current_position	dw 2880 + 8
	.titlemsg			db "MichalOS PCM Test", 0
	.footermsg			db "[Space] Play/Pause [Esc] Exit", 0
	.secondmsg			db " seconds played  ", 0
	.buffmsg			db " buffers read (", 0
	.buffmsg2			db " kB)     ", 0
	.previous_block		dw 1
	.loadedbuffers		dw 1

	.error_msg1			db "Error reading high disk sectors.", 0
	.error_msg2			db "On some systems, this may be a false", 0
	.error_msg3			db "positive. Do you still want to continue?", 0

	;; *** IRQ0 TICK ROUTINE ***
tick:   
	cmp byte [pausestate], 1
	je .no_update_timer

	mov     si, [offset]

	mov     ah, [si]  ; If not, load up the value
	mov cl, [shr_value]
	shr     ax, cl           ; Make it a 7-bit value
	test ah, ah
	jz .no_play				; If the value is 0, the PIT thinks it's actually 0x100, so it'll clip

	mov     al, 0xb0        ; And program PIT Channel 2 to
	out     0x43, al        ; deliver a pulse that many
	mov     al, ah          ; microseconds long
	out     0x42, al
	clr al
	out     0x42, al

.no_play:
	inc     si              ; Update pointer
	and si, 0x1FFF			; Ensure the pointer is 4096-8191
	or si, 0x2000
	mov     [offset], si

.no_update_timer:
	jmp     .intend         ; ... and jump to end of interrupt
	
	;; If we get here, we're past the end of the sound.
.nosnd:
	mov     ax, [done]      ; Have we already marked it done?
	jnz     .intend         ; If so, nothing left to do
	mov     ax, 1           ; Otherwise, mark it done...
	mov     [done], ax

.intend:

	ret

	done   dw      0
	offset dw      8192
	shr_value	db 2
	pausestate	db 0
