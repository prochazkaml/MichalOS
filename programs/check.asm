
	%INCLUDE "include/program.inc"

start:
	mov ax, .title
	mov bx, .null
	mov cx, 256
	call os_draw_background

	mov ax, .msg1
	mov bx, .msg2
	mov cx, .msg3
	mov dx, 1
	call os_dialog_box
	
	cmp ax, 1
	je .exit

	call os_clear_screen
	call os_get_boot_disk

	clr eax
	
.loop:
	call .sectorselect
	inc ax
	cmp ax, 2880
	jl .loop
	
	mov ax, [.bad_sectors]
	call os_print_int
	
	mov si, .badmsg0
	call os_print_string
	
	call os_wait_for_key
	
.exit:
	ret
	
.sectorselect:
	pusha
	mov si, .sectormsg
	call os_print_string
	
	call os_print_int
	popa
	
	pusha
	mov si, 4000h
	call os_get_boot_disk
	call os_disk_read_sector
	jc .error
	
	mov si, .pass_msg
	call os_print_string
	popa
	ret
	
.error:
	mov si, .err_msg
	call os_print_string
	inc word [.bad_sectors]
	popa
	ret

	.drive				db 0
	.bad_sectors		dw 0
	
	.title				db 'MichalOS Disk Checker', 0
	.null				db 0
	.msg1				db 'This utility will scan the current drive', 0
	.msg2				db 'for bad sectors. On a real floppy, this', 0
	.msg3				db 'test takes ~2 min. Are you sure?', 0

	.sectormsg			db 'Sector ', 0
	.pass_msg			db ' - Passed', 13, 10, 0
	.err_msg			db ' - Failed', 13, 10, 0
	.badmsg0			db ' bad sectors found.', 0
	
; ------------------------------------------------------------------

