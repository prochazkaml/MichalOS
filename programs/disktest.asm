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

	mov si, disk_buffer
	mov eax, 0				; Load first disk sector into RAM
	call os_disk_read_sector
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
