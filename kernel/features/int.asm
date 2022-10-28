; ==================================================================
; MichalOS Interrupt management & app timer functions
; ==================================================================

; -----------------------------------------------------------------
; os_modify_int_handler -- Change location of interrupt handler
; IN: CL = int number, DI:SI = handler location
; OUT: None, registers preserved

os_modify_int_handler:
	pusha

.no_pusha:
	cli

	movzx bx, cl		; Move supplied int into BX
	shl bx, 2			; Multiply by four to get position
	
	mov [fs:bx], si		; First store offset
	mov [fs:bx + 2], di	; Then segment of our handler
	
	sti
	popa
	ret

; -----------------------------------------------------------------
; os_get_int_handler -- Change location of interrupt handler
; IN: CL = int number
; OUT: DI:SI = handler location

os_get_int_handler:
	push bx

	movzx bx, cl			; Move supplied int into BX
	shl bx, 2			; Multiply by four to get position
	
	mov si, [fs:bx]		; First store offset
	mov di, [fs:bx + 2]	; Then segment of our handler

	pop bx
	ret

; ------------------------------------------------------------------
; os_pause -- Delay execution for a specified number of ticks (18.2 Hz by default)
; IN: AX = amount of ticks to wait
; OUT: None, registers preserved

os_pause:
	mov [pause_timer], ax

.wait_loop:
	cmp word [pause_timer], 0
	jne .wait_loop
	ret

; -----------------------------------------------------------------
; os_attach_app_timer -- Attach a timer interrupt to an application and sets the timer speed
; Formula: speed = (105000000 / 88) / frequency
; IN: SI = handler location, CX = speed
; OUT: None, registers preserved

os_attach_app_timer:
	pusha
	mov [timer_application_offset], si
	mov byte [timer_application_attached], 1
	
	jmp os_set_timer_speed.no_pusha
	
; -----------------------------------------------------------------
; os_return_app_timer -- Returns the timer interrupt back to the system and resets the timer speed
; IN/OUT: None, registers preserved

os_return_app_timer:
	pusha
	mov byte [timer_application_attached], 0
	
	clr cx
	call os_set_timer_speed
	
	mov cl, 1Ch					; RTC handler
	mov si, os_compat_int1C
	mov di, cs
	jmp os_modify_int_handler.no_pusha
	
; -----------------------------------------------------------------
; os_set_timer_speed -- Sets the timer's trigger speed.
; Formula: speed = (105000000 / 88) / frequency
; IN: CX = speed
; OUT: Nothing, registers preserved

os_set_timer_speed:
	pusha
	
.no_pusha:
	mov [current_timer_speed], cx
	
	mov al, 00110110b	; Timer 0, square wave
	out 43h, al
	mov al, cl
	out 40h, al
	mov al, ch
	out 40h, al

	pushad
	clr edx
	mov eax, 105000000*60/88	; Ticks per minute

	dec cx				; 0x0000 -> 0xFFFF
	movzx ecx, cx
	inc ecx				; 0xFFFF -> 0x10000

	div ecx

	mov [current_timer_freq], eax
	popad

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
	
	cmp dword [screensaver_timer], 0
	je .no_update_screensaver
	
	dec dword [screensaver_timer]
	
.no_update_screensaver:
	cmp word [pause_timer], 0
	je .no_update_pause_timer
	
	dec word [pause_timer]
	
.no_update_pause_timer:
	cmp byte [system_ui_state], 1
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
	current_timer_freq			dd 0	; in Hz/64

	screensaver_timer			dd 0
	pause_timer					dw 0

; ==================================================================
