; ------------------------------------------------------------------
; MichalOS Disk test
; ------------------------------------------------------------------

	%INCLUDE "michalos.inc"

start:
	mov dx, 65535
.loop:
	inc dx
	cmp dx, 256
	je .exit
	mov cx, 1				; Load first disk sector into RAM
	mov dh, 0
	mov bx, disk_buffer
	mov ah, 2
	mov al, 1
	stc
	int 13h					; BIOS load sector call
	jc .loop
	mov al, dl
	call os_print_2hex
	call os_print_newline
	jmp .loop
.exit:
	call os_wait_for_key
	ret
	
disk_buffer:
	
; ------------------------------------------------------------------
