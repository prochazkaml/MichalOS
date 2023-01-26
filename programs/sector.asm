
	%INCLUDE "include/program.inc"

start:
	call .draw_background
	mov16 dx, 5, 4
	call os_move_cursor

	clr al

.hex2_title_loop:
	call os_print_2hex
	call os_print_space

	inc al
	cmp al, 10h
	jne .hex2_title_loop

	clr al
	call os_print_space

.hex_title_loop:
	call os_print_1hex

	inc al
	cmp al, 10h
	jne .hex_title_loop

	mov cx, 512
	mov di, DISK_BUFFER
	mov al, 88
	rep stosb
	
.draw_loop:
	call .bardraw
	
	mov16 dx, 5, 6
	call os_move_cursor
	mov si, DISK_BUFFER
	cmp byte [.halfnum], 0
	je .zerohalf
	add si, 256
	
.zerohalf:
	pusha
	call .datadraw
	popa
	mov16 dx, 54, 6
	call os_move_cursor
	call .asciidraw
	
	mov16 dx, 1, 2	; Print the input label
	call os_move_cursor
	mov al, '>'
	call os_putchar
	
	mov ax, 0920h			; Clear the screen for the next input
	clr bh
	mov bl, [57000]
	mov cx, 60
	int 10h
	
	call .sectordraw

	mov16 dx, 2, 2			; Print the input label
	call os_move_cursor
	call os_show_cursor		; Get a command from the user
	mov ax, .input_buffer
	call os_input_string
	
	mov si, .input_buffer	; Decode the command
	call os_string_uppercase
	lodsb
	cmp al, 'Q'				; 'Q' typed?
	je .exit
	cmp al, 'S'
	je .sectorselect
	cmp al, 'H'
	je .selecthalf
	jmp .draw_loop
		
.sectordraw:
	mov16 dx, 40, 2
	call os_move_cursor
	mov ax, [.sectornum]
	call os_print_int
	ret
	
.asciidraw:
	lodsb
	cmp al, 32
	jge .asciichar
	mov al, '.'
.asciichar:
	call os_putchar
	
	call os_get_cursor_pos
	cmp dl, 70
	jl .asciidraw
	
	mov dl, 54
	inc dh	
	call os_move_cursor

	cmp dh, 22
	jl .asciidraw
	ret

.datadraw:
	lodsb
	call os_print_2hex
	
;	cmp si, disk_buffer+512
;	je .draw_loop
	
	push si
	mov si, .space
	call os_print_string
	pop si
	
	call os_get_cursor_pos
	cmp dl, 53
	jl .datadraw
	
	mov dl, 5
	inc dh	
	call os_move_cursor

	cmp dh, 22
	jl .datadraw
	ret
	
	
	
.selecthalf:
	lodsb
	cmp al, '0'
	je .selectfirsthalf
	mov byte [.halfnum], 1
	jmp .draw_loop
.selectfirsthalf:
	mov byte [.halfnum], 0
	jmp .draw_loop
	
.sectorselect:
	call os_string_to_int	; Decode the entered number
	mov [.sectornum], ax
	call os_convert_l2hts		; Entered number -> HTS
	mov bx, DISK_BUFFER		; Read the sector
	mov16 ax, 1, 2
	call os_get_boot_disk
	stc
	int 13h
	jc .error
	jmp .draw_loop
	
.error:
	mov ax, .msg1
	mov bx, .msg2
	mov cx, .msg2
	clr dx
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
	mov16 dx, 1, 6
	clr bl

.bardrawloop:
	call os_move_cursor

	mov al, [.halfnum]
	call os_print_1hex

	mov al, bl
	call os_print_2hex

	inc dh
	add bl, 10h
	jnz .bardrawloop
	ret



	.title_msg			db 'MichalOS Disk Inspector', 0
	.footer_msg			db 'q = Quit, sXYZ = Load sector XYZ, h0/h1 = Display 1st/2nd half', 0

	.halfnum			db 0
	.sectornum			dw 0
	
	.space				db ' ', 0
	
	.msg1				db 'Disk error!' ; Termination not necessary here
	.msg2				db 0
	
	.input_buffer:	; Has to be at the end!
; ------------------------------------------------------------------

