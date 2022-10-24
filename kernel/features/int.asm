; -----------------------------------------------------------------
; os_modify_int_handler -- Change location of interrupt handler
; IN: CL = int number, DI:SI = handler location

os_modify_int_handler:
	pusha

	cli

	push es
	
	mov es, [driversgmt]
	
	movzx bx, cl			; Move supplied int into BX

	shl bx, 2			; Multiply by four to get position
	
	mov [es:bx], si		; First store offset

	add bx, 2
	
	mov [es:bx], di		; Then segment of our handler

	pop es
	
	sti

	popa
	ret

; -----------------------------------------------------------------
; os_get_int_handler -- Change location of interrupt handler
; IN: CL = int number; OUT: DI:SI = handler location

os_get_int_handler:
	pusha

	push ds
	
	mov ds, [driversgmt]
	
	movzx bx, cl			; Move supplied int into BX

	shl bx, 2			; Multiply by four to get position
	
	mov si, [ds:bx]		; First store offset
	add bx, 2

	mov di, [ds:bx]		; Then segment of our handler

	pop ds

	mov [.tmp_word], si
	mov [.tmp_sgmt], di
	popa
	mov si, [.tmp_word]
	mov di, [.tmp_sgmt]
	ret

	.tmp_word	dw 0
	.tmp_sgmt	dw 0
	
; -----------------------------------------------------------------
; os_attach_timer_interrupt -- Attach a timer interrupt to an application and sets the timer speed
; Formula: speed = (105000000 / 88) / frequency
; IN: SI = handler location, CX = speed

os_attach_app_timer:
	pusha
	mov [timer_application_offset], si
	mov byte [timer_application_attached], 1
	
	call os_set_timer_speed
	popa
	ret
	
; -----------------------------------------------------------------
; os_return_timer_interrupt -- Returns the timer interrupt back to the system and resets the timer speed
; IN: nothing

os_return_app_timer:
	pusha
	mov byte [timer_application_attached], 0
	
	clr cx
	call os_set_timer_speed
	
	mov cl, 1Ch					; RTC handler
	mov si, os_compat_int1C
	mov di, cs
	call os_modify_int_handler
	popa
	ret
	
; -----------------------------------------------------------------
; os_set_timer_speed -- Sets the timer's trigger speed.
; Formula: speed = (105000000 / 88) / frequency
; IN: CX = speed

os_set_timer_speed:
	pusha
	
	mov [current_timer_speed], cx
	
	mov al, 00110110b	; Timer 0, square wave
	out 43h, al
	mov al, cl
	out 40h, al
	mov al, ch
	out 40h, al
	
	popa
	ret
	
; -----------------------------------------------------------------
; Interrupt call parsers

; Division by 0 error handler
os_compat_int00:
	mov ax, .msg
	jmp os_fatal_error

	.msg db 'CPU: Division by zero error', 0

os_compat_int05:
	mov ax, .msg
	jmp os_fatal_error

	.msg db 'User triggered crash', 0

os_compat_int0C:
	cli
	mov sp, 0FFFEh
	sti
	
	mov ax, .msg
	jmp os_fatal_error
	
	.msg db 'Stack overflow', 0
	
; Invalid opcode handler
os_compat_int06:
	mov ax, .msg
	jmp os_fatal_error

	.msg db 'CPU: Invalid opcode', 0

; Processor extension error handler
os_compat_int07:
	mov ax, .msg
	jmp os_fatal_error

	.msg db 'CPU: Processor extension error', 0

; System timer handler (8253/8254)
os_compat_int1C:
	cli
	pushad
	push ds
	push es
	
	mov ax, cs
	mov ds, ax
	mov es, ax
	
	cmp word [screensaver_timer], 0
	je .no_update_screensaver
	
	dec word [screensaver_timer]
	
.no_update_screensaver:
	cmp byte [0082h], 1
	je .no_update
	
	mov ah, 02h			; Get the time
	call os_int_1Ah
	cmp cx, [.tmp_time]
	je .no_update
	mov [.tmp_time], cx

	call os_print_clock

.no_update:
	cmp byte [cs:timer_application_attached], 1
	je .app_routine

	pop es
	pop ds
	popad
	sti
	iret

	.tmp_time	dw 0

.app_routine:
	call [cs:timer_application_offset]
	
	pop es
	pop ds	
	popad
	iret

	timer_application_attached	db 0
	timer_application_offset	dw 0
	
	current_timer_speed			dw 0
	
	screensaver_timer			dw 0
