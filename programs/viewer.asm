; ------------------------------------------------------------------
; MichalOS Image Viewer
; ------------------------------------------------------------------

	%INCLUDE "michalos.inc"

start:
	cmp byte [0E0h], 0				; Were we passed a filename?
	je .no_param_passed
	
	cmp byte [already_displayed], 1
	je .exit
	
	mov byte [already_displayed], 1
	
	mov ax, 0E0h
	jmp .check_file
	
.no_param_passed:
	call .draw_background
	
	mov bx, extension_number
	call os_file_selector_filtered		; Get filename
	
	jc .exit

.check_file:
	call os_file_exists
	jc .load_error

	mov bx, ax			; Save filename for now

	mov di, ax

	call os_string_length
	add di, ax			; DI now points to last char in filename

	dec di
	dec di
	dec di				; ...and now to first char of extension!
	
	pusha
	
	mov si, pcx_extension
	mov cx, 3
	rep cmpsb			; Does the extension contain 'PCX'?
	je .valid_pcx_extension		; Skip ahead if so
	
	popa
					; Otherwise show error dialog
	clr dx		; One button for dialog box
	mov ax, err_string
	mov bx, err_string2
	clr cx
	call os_dialog_box

	jmp start			; And retry

.valid_pcx_extension:
	popa
		
	push ds
	push es
	mov ax, gs
	mov es, ax
	mov ax, bx
	clr cx		; Load PCX at GS:0000h
	call os_load_file

	call os_init_graphics_mode

	mov ax, 0A000h		; ES = video memory
	mov es, ax

	mov ax, gs			; DS = source file
	mov ds, ax
	
	mov si, 80h			; Move source to start of image data (First 80h bytes is header)
	clr di		; Start our loop at top of video RAM

.decode:
	mov cx, 1
	lodsb
	cmp al, 192			; Single pixel or string?
	jb .single
	and al, 63			; String, so 'mod 64' it
	mov cl, al			; Result in CL for following 'rep'
	lodsb				; Get byte to put on screen
.single:
	rep stosb			; And show it (or all of them)
	cmp di, 64001
	jb .decode


	mov dx, 3c8h		; Palette index register
	clr al		; Start at colour 0
	out dx, al			; Tell VGA controller that...
	inc dx				; ...3c9h = palette data register

	mov cx, 768			; 256 colours, 3 bytes each
.setpal:
	lodsb				; Grab the next byte.
	shr al, 2			; Palettes divided by 4, so undo
	out dx, al			; Send to VGA controller
	loop .setpal

	pop es
	pop ds

	call os_wait_for_key
	call os_init_text_mode
	jmp start

.draw_background:
	mov ax, title_msg		; Set up screen
	mov bx, footer_msg
	mov cx, 256
	call os_draw_background
	ret

.exit:
	mov byte [0E0h], 0
	ret
	
.load_error:
	mov ax, err_msg
	clr bx
	clr cx
	clr dx
	call os_dialog_box
	jmp .exit


	extension_number	db 1
	pcx_extension		db 'PCX', 0
	
	err_string	db 'Invalid file type!', 0
	err_string2	db '320x200x8bpp PCX only!', 0

	err_msg		db 'File not found!', 0

	title_msg	db 'MichalOS Image Viewer', 0
	footer_msg	db '', 0

	already_displayed	db 0
	
; ------------------------------------------------------------------

