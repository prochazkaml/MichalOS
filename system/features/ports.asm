; ==================================================================
; PORT INPUT AND OUTPUT ROUTINES
; ==================================================================

; ------------------------------------------------------------------
; os_serial_port_enable -- Set up the serial port for transmitting data
; IN: AX = 0 for normal mode (9600 baud), or 1 for slow mode (1200 baud)

os_serial_port_enable:
	pusha

	clr dx			; Configure serial port 1
	cmp ax, 1
	je .slow_mode

	mov ax, 11100011b		; 9600 baud, no parity, 8 data bits, 1 stop bit
	jmp .finish

.slow_mode:
	mov ax, 10000011b		; 1200 baud, no parity, 8 data bits, 1 stop bit	

.finish:
	int 14h

	popa
	ret


; ------------------------------------------------------------------
; os_send_via_serial -- Send a byte via the serial port
; IN: AL = byte to send via serial; OUT: AH = Bit 7 clear on success

os_send_via_serial:
	pusha

	mov ah, 01h
	clr dx			; COM1

	int 14h

	mov [.tmp], ah

	popa

	mov ah, [.tmp]

	ret

	.tmp db 0


; ------------------------------------------------------------------
; os_get_via_serial -- Get a byte from the serial port
; IN: nothing; OUT: AL = byte that was received, AH = Bit 7 clear on success

os_get_via_serial:
	pusha

	mov ah, 02h
	clr dx			; COM1

	int 14h

	mov [.tmp], ax

	popa

	mov ax, [.tmp]

	ret


	.tmp dw 0

; ==================================================================

