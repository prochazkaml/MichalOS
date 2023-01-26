; ------------------------------------------------------------------
; About MichalOS
; ------------------------------------------------------------------

	%INCLUDE "include/program.inc"

start:
	mov ax, .msg1
	mov bx, .msg2
	clr cx
	clr dx
	call os_dialog_box

	call os_clear_screen

	mov si, .handler
	mov cx, 11932
	call os_attach_app_timer
	
.loop:
	hlt

	cmp word [.timer], 100
	jne .loop

	mov word [.timer], 0
	
	mov edx, [.new_edx]
	sub edx, [.old_edx]
	
	mov eax, [.new_eax]
	sub eax, [.old_eax]
	
	jnc .no_carry
	
	dec edx
	
.no_carry:
	mov ebx, 10
	div ebx
	
	call os_print_32int
	call os_print_newline
	
	call os_check_for_key
	cmp al, 27
	jne .loop
	
	call os_return_app_timer
	
	ret
	
.handler:
	mov eax, [.new_eax]
	mov [.old_eax], eax
	
	mov eax, [.new_edx]
	mov [.old_edx], eax

	rdtsc
	
	mov [.new_eax], eax
	mov [.new_edx], edx
	
	inc word [.timer]
	ret
	
	.timer		dw 0
	.old_eax	dd 0
	.old_edx	dd 0
	.new_eax	dd 0
	.new_edx	dd 0
	
	.msg1		db "This app measures the CPU clock speed", 0
	.msg2		db "(of core #0) in kHz. To exit, press Esc.", 0
	
; ------------------------------------------------------------------
