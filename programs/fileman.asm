; ------------------------------------------------------------------
; MichalOS File Manager
; ------------------------------------------------------------------

	%INCLUDE "michalos.inc"

start:
	mov [.load_segment], gs

	call .draw_background

	mov byte [32767], 0
	
	call os_file_selector
	jc .exit

	mov bx, ax
	mov cx, .screenstring
	mov ax, .root
	call os_string_join
	mov ax, bx
	
	push ax

	mov bx, cx
	
.commands:
	mov ax, .command_list			; Draw list of disk operations
	mov cx, .helpmsg
	
	mov word [0089h], 37
	call os_list_dialog
	mov word [0089h], 76

	jc .clearstack				; User pressed Esc?

	cmp ax, 1						; Otherwise respond to choice
	je .launch_file
	
	cmp ax, 2
	je .create_file
	
	cmp ax, 3
	je .delete_file
	
	cmp ax, 4
	je .rename_file
	
	cmp ax, 5
	je .copy_file
	
.clearstack:
	pop ax
	jmp start
	
.launch_file:
	mov al, 1
	mov [32767], al
	pop ax
	ret

.create_file:
	pop ax

	call .draw_background

	mov bx, .filename_msg			; Get a filename
	mov ax, .filename_input
	call os_input_dialog

	clr cx			; Create an empty file
	mov bx, 4096
	mov ax, .filename_input
	call os_write_file

	jc .writing_error

	jmp start

	

.delete_file:
	call .draw_background

	mov ax, .delete_confirm_msg		; Confirm delete operation
	clr bx
	clr cx
	mov dx, 1
	call os_dialog_box

	test ax, ax
	jz .ok_to_delete

	pop ax
	jmp start

.ok_to_delete:
	pop ax
	call os_remove_file
	jc .disk_error
	jmp start

.rename_file:
	call .draw_background

	pop ax
	
	mov si, ax				; And store it
	mov di, .filename_tmp1
	call os_string_copy

.retry_rename:
	call .draw_background

	mov bx, .filename_msg			; Get second filename
	mov ax, .filename_input
	call os_input_dialog

	mov si, ax				; Store it for later
	mov di, .filename_tmp2
	call os_string_copy

	mov ax, di				; Does the second filename already exist?
	call os_file_exists
	jnc .rename_fail			; Quit out if so

	mov ax, .filename_tmp1
	mov bx, .filename_tmp2

	call os_rename_file
	jc .writing_error

	jmp start


.rename_fail:
	mov ax, .err_file_exists
	clr bx
	clr cx
	clr dx
	call os_dialog_box
	jmp start


.copy_file:
	call .draw_background

	pop ax
	
	mov si, ax				; And store it
	mov di, .filename_tmp1
	call os_string_copy

	call .draw_background

	mov bx, .filename_msg			; Get second filename
	mov ax, .filename_input
	call os_input_dialog

	call os_file_exists
	jnc .file_exists
	
	mov si, ax
	mov di, .filename_tmp2
	call os_string_copy

	mov ax, .filename_tmp1
	mov bx, .filename_tmp2

	call os_get_file_size
	cmp ebx, 28672
	jl .no_copy_change
	
	mov word [.load_segment], gs
	mov word [.load_offset], 0000h
	
.no_copy_change:
	push es
	mov es, [.load_segment]
	mov cx, [.load_offset]
	call os_load_file
	
	mov byte [0086h], 5
	
	mov cx, bx
	mov bx, [.load_offset]
	mov ax, .filename_tmp2
	call os_write_file
	pop es
	
	jc .writing_error

	mov word [.load_segment], cs
	mov word [.load_offset], 1000h

	jmp start

.no_copy_file_selected:
	jmp start
	
.writing_error:
	mov word [.load_segment], cs
	mov word [.load_offset], 1000h

	call .draw_background

	clr bx
	clr cx
	clr dx

	cmp byte [0086h], 0
	je .failure0
	cmp byte [0086h], 1
	je .failure1
	cmp byte [0086h], 2
	je .failure2
	cmp byte [0086h], 3
	je .failure3
	cmp byte [0086h], 4
	je .failure4

	mov ax, .error_msg
	mov bx, .error_msg2
	call os_dialog_box
	jmp start

.failure0:
	mov ax, .failure0msg
	call os_dialog_box
	jmp start
	
.failure1:
	mov ax, .failure1msg
	call os_dialog_box
	jmp start
	
.failure2:
	mov ax, .failure2msg
	call os_dialog_box
	jmp start
	
.failure3:
	mov ax, .failure3msg
	call os_dialog_box
	jmp start
	
.failure4:
	mov ax, .failure4msg
	call os_dialog_box
	jmp start

.exit:
	call os_clear_screen
	ret


.draw_background:
	mov ax, .title_msg
	mov bx, .footer_msg
	mov cx, 256
	call os_draw_background
	ret

.disk_error:
	mov ax, .dk_error
	clr bx
	clr cx
	clr dx
	call os_dialog_box
	
	jmp start
	
.file_exists:
	mov ax, .err_file_exists
	clr bx
	clr cx
	clr dx
	call os_dialog_box
	
	jmp start

	
	.command_list			db 'Run application,Create file,Delete file,Rename,Copy file', 0

	.root					db 'A:/'
	.helpmsg				db 0
	
	.title_msg				db 'MichalOS File Manager', 0
	.footer_msg				db 0
	
	.delete_confirm_msg		db 'Are you sure?', 0

	.filename_msg			db 'Enter a new filename:', 0
	.filename_input			times 15 db 0
	.filename_tmp1			times 15 db 0
	.filename_tmp2			times 15 db 0

	.error_msg				db 'Error writing to the disk!', 0
	.error_msg2				db '(Disk is read-only/file already exists)?', 0

	.err_file_exists		db 'File with this name already exists!', 0

	.failure0msg			db 'Filename is too long!', 0
	.failure1msg			db 'Filename is empty!', 0
	.failure2msg			db 'Filename has no extension!', 0
	.failure3msg			db 'Filename has no basename!', 0
	.failure4msg			db 'Extension is too short!', 0

	.dk_error				db 'Disk error!', 0
	
	.load_segment			dw 0
	.load_offset			dw 0

	.screenstring			times 24 db 0

blank:
	
; ------------------------------------------------------------------
