; ==================================================================
; MichalOS ZX7 decompression routine
; ==================================================================

; Decompresses Einar Saukas' ZX7 compressed stream data in 16-bit real mode.
; ZX7 format and original Z80 decompressor by Einar Saukas.
; Original Z80 to 8086 conversion, and size-optimized version, by Peter Ferrie.
; Speed-optimized code by Peter Ferrie and Jim Leonard.
; 20160308
;
; The source for the conversion was the original "default" Z80 decompression
; code provided by Einar.  Further size optimization and unrolling were
; independently performed specifically for the 8086.
; Source is formatted for Borland Turbo Assembler IDEAL mode and NEAR calls,
; however it should be very easy to port to other assemblers if necessary.

; ------------------------------------------------------------------
; os_decompress_zx7 -- Decompresses ZX7-packed data.
; IN: DS:SI = source, ES:DI = destination
; OUT: None, registers preserved

os_decompress_zx7:
	pusha
	call int_decompress_zx7
	popa
	ret

; ==================================================================

; ------------------------------------------------------------------
; int_decompress_zx7 -- Decompresses ZX7-packed data.
; IN: DS:SI = source, ES:DI = destination
; OUT: None, destroys every imaginable register under the sun

int_decompress_zx7:
	mov al, 80h
	xor cx, cx
	mov bp, .next_bit
	
.copy_byte_loop:
	movsb					; copy literal byte

.main_loop:
	call bp
	jnc .copy_byte_loop		; next bit indicates either
							; literal or sequence

	; determine number of bits used for length (Elias gamma coding)

	xor bx, bx

.len_size_loop:
	inc bx
	call bp
	jnc .len_size_loop
	db 80h ; mask call

	; determine length

.len_value_loop:
	call bp

.len_value_skip:
	adc cx, cx
	jb .next_bit_ret 		; check end marker
	dec bx
	jnz .len_value_loop
	inc cx					; adjust length

	; determine offset

	mov bl, [si]			; load offset flag (1 bit) +
							; offset value (7 bits)
	inc si
	stc
	adc bl, bl
	jnc .offset_end 		; if offset flag is set, load
							; 4 extra bits
	mov bh, 10h				; bit marker to load 4 bits
.rld_next_bit:
	call bp
	adc bh, bh				; insert next bit into D
	jnc .rld_next_bit		; repeat 4 times, until bit
							; marker is out
	inc bh					; add 128 to DE

.offset_end:
	shr bx, 1				; insert fourth bit into E

	; copy previous sequence

	push si
	mov si, di
	sbb si, bx				; destination = destination - offset - 1

	es rep movsb

	pop si					; restore source address
							; (compressed data)
	jmp .main_loop

.next_bit:
	add al, al				; check next bit
	jnz .next_bit_ret		; no more bits left?
	lodsb					; load another group of 8 bits
	adc al, al

.next_bit_ret:
	ret

; ==================================================================
