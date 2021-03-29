
	%INCLUDE "michalos.inc"

start:
	mov al, [0]
	mov [.drive], al
	
	call .draw_background
	mov dl, 0
	mov dh, 4
	call os_move_cursor
	mov si, .hexchars
	call os_print_string

	mov cx, 512
	mov di, DISK_BUFFER
	mov al, 88
	rep stosb
	
.draw_loop:
	call .bardraw
	
	mov dl, 4
	mov dh, 6
	call os_move_cursor
	mov si, DISK_BUFFER
	cmp byte [.halfnum], 0
	je near .zerohalf
	add si, 256
.zerohalf:
	pusha
	call .datadraw
	popa
	mov dl, 53
	mov dh, 6
	call os_move_cursor
	call .asciidraw
	
	mov dl, 0				; Print the input label
	mov dh, 2
	call os_move_cursor
	mov si, .input_label
	call os_print_string
	
	mov ah, 09h				; Clear the screen for the next input
	mov al, ' '
	mov bh, 0
	mov bl, [57000]
	mov cx, 60
	int 10h
	
	call .sectordraw

	mov dl, 2				; Print the input label
	mov dh, 2
	call os_move_cursor
	call os_show_cursor		; Get a command from the user
	mov ax, .input_buffer
	call os_input_string
	
	mov si, .input_buffer	; Decode the command
	call os_string_uppercase
	lodsb
	cmp al, 'Q'				; 'Q' typed?
	je near .exit
	cmp al, 'S'
	je near .sectorselect
	cmp al, 'H'
	je near .selecthalf
	cmp al, 'D'
	je near .selectdrive
	jmp .draw_loop
	
.selectdrive:
	call os_string_to_int
	mov [.drive], al
	jmp .draw_loop
	
.sectordraw:
	mov dl, 40
	mov dh, 2
	call os_move_cursor
	mov ax, [.sectornum]
	call os_int_to_string
	mov si, ax
	call os_print_string
	ret
	
.asciidraw:
	lodsb
	cmp al, 32
	jge near .asciichar
	mov al, '.'
.asciichar:
	mov ah, 0Eh
	mov bh, 0
	int 10h
	
	call os_get_cursor_pos
	cmp dl, 69
	jl .asciidraw
	
	mov dl, 53
	inc dh	
	call os_move_cursor

	cmp dh, 22
	jl .asciidraw
	ret

.datadraw:
	lodsb
	call os_print_2hex
	
;	cmp si, disk_buffer+512
;	je near .draw_loop
	
	push si
	mov si, .space
	call os_print_string
	pop si
	
	call os_get_cursor_pos
	cmp dl, 52
	jl .datadraw
	
	mov dl, 4
	inc dh	
	call os_move_cursor

	cmp dh, 22
	jl .datadraw
	ret
	
	
	
.selecthalf:
	lodsb
	cmp al, '0'
	je near .selectfirsthalf
	mov byte [.halfnum], 1
	jmp .draw_loop
.selectfirsthalf:
	mov byte [.halfnum], 0
	jmp .draw_loop
	
.sectorselect:
	call os_string_to_int	; Decode the entered number
	mov [.sectornum], ax
	call os_disk_l2hts		; Entered number -> HTS
	mov bx, DISK_BUFFER		; Read the sector
	mov ah, 2
	mov al, 1
	mov dl, [.drive]
	stc
	int 13h
	jc .error
	jmp .draw_loop
	
.error:
	mov ax, .msg1
	mov bx, .msg2
	mov cx, .msg2
	mov dx, 0
	call os_dialog_box
	call .draw_background
	jmp .draw_loop
	
.exit:
	call os_clear_screen
	ret

.draw_background:
	mov ax, .title_msg
	mov bx, .footer_msg
	mov cx, [57000]
	call os_draw_background
	ret

.bardraw:
	mov dl, 0
	mov dh, 6
	call os_move_cursor
	mov al, [.halfnum]
	cmp al, 0
	je near .firsthalf
	mov si, .hexchars1
	call os_print_string
	ret
.firsthalf:
	mov si, .hexchars0
	call os_print_string
	ret
	
	.title_msg			db 'MichalOS Disk Inspector', 0
	.footer_msg			db 'q = Quit, sXYZ = Load sector XYZ, h0/h1 = Display 1st/2nd half', 0

	.input_label		db ' >', 0

	.hexchars			db '    00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F  0123456789ABCDEF', 13, 10, 0
	.hexchars0			db '000', 13, 10, '010', 13, 10, '020', 13, 10, '030', 13, 10, '040', 13, 10, '050', 13, 10, '060', 13, 10, '070', 13, 10, '080', 13, 10, '090', 13, 10, '0A0', 13, 10, '0B0', 13, 10, '0C0', 13, 10, '0D0', 13, 10, '0E0', 13, 10, '0F0', 13, 10, 0
	.hexchars1			db '100', 13, 10, '110', 13, 10, '120', 13, 10, '130', 13, 10, '140', 13, 10, '150', 13, 10, '160', 13, 10, '170', 13, 10, '180', 13, 10, '190', 13, 10, '1A0', 13, 10, '1B0', 13, 10, '1C0', 13, 10, '1D0', 13, 10, '1E0', 13, 10, '1F0', 13, 10, 0
	
	.halfnum			db 0
	.sectornum			dw 0
	
	.drive				db 0
	
	.space				db ' ', 0
	
	.msg1				db 'Disk error!', 0
	.msg2				db 0
	
	.msgfdda			db 'A: (Floppy 1)', 0
	.msgfddb			db 'B: (Floppy 2)', 0
	.msghddc			db 'C: (Hard drive 1)', 0
	.msghddd			db 'D: (Hard drive 2)', 0
	.msgcdrom			db 'E: (CD-ROM)', 0
	
	.msgsector			db ', sector ', 0

	.input_buffer		db 0		; Has to be on the end!
; ------------------------------------------------------------------

