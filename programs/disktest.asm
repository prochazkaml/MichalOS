; ------------------------------------------------------------------
; MichalOS Disk test
; ------------------------------------------------------------------

	%INCLUDE "include/program.inc"

start:
	mov dx, 65535
.loop:
	inc dx
	cmp dx, 256
	je .exit
	mov cx, 1				; Load first disk sector into RAM
	clr dh
	mov bx, disk_buffer
	mov16 ax, 1, 2
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
