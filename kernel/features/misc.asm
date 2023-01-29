; ==================================================================
; MichalOS Miscellaneous functions
; ==================================================================

; ------------------------------------------------------------------
; os_run_zx7_module -- Decompresses a kernel module and runs it
; IN: DS:SI = compressed data
; OUT: Whatever the module returns

os_run_zx7_module:
	pusha
	push es

	movs es, cs
	mov di, 100h
	call os_decompress_zx7
	
	pop es
	popa
	jmp 100h

; ------------------------------------------------------------------
; os_exit -- Exits the application, launches another one (if possible)
; IN: AX = if not 0, then ptr to filename of application to be launched,
;     BX = 1 if the application calling os_exit should be re-launched after
;     the requested application exits
; OUT: None, register preserved

os_exit:
	; Mark special exit

	mov byte [app_exit_special], 1

	; Exit the application

	mov sp, [origstack]
	jmp finish

	app_exit_special	db 0

; ------------------------------------------------------------------
; os_clear_registers -- Clear all registers
; IN: None
; OUT: Cleared registers

os_clear_registers:
	xor eax, eax
	xor ebx, ebx
	xor ecx, ecx
	xor edx, edx
	xor esi, esi
	xor edi, edi
	ret

os_illegal_call:
	mov ax, .msg
	jmp os_fatal_error
	
	.msg db 'Called a non-existent system function', 0
	
; ------------------------------------------------------------------
; os_get_os_name -- Get the OS name string
; IN: None
; OUT: SI = OS name string, zero-terminated

os_get_os_name:
	mov si, osname
	ret

	osname	db 'MichalOS ', VERMAJ, '.', VERMIN, 0

; ------------------------------------------------------------------
; os_fatal_error -- Display error message and halt execution
; IN: AX = error message string location
; OUT: None, as it does not return

os_fatal_error:
	movs ds, cs
	mov si, .sub_fatalerr_data
	jmp os_run_zx7_module

.sub_fatalerr_data:
	incbin "sub_fatalerr.zx7"

; ------------------------------------------------------------------
; os_get_memory -- Gets the amount of system RAM.
; IN: None
; OUT: AX = conventional memory (in kB), BX = high memory (in kB)

os_get_memory:
	pusha
	xor cx, cx
	int 12h					; Get the conventional memory size...
	mov [cs:.conv_mem], ax	; ...and store it
	
	mov ah, 88h				; Also get the high memory (>1MB)...
	int 15h
	mov [cs:.high_mem], ax	; ...and store it too
	popa
	mov ax, [cs:.conv_mem]
	mov bx, [cs:.high_mem]
	ret

	.conv_mem	dw 0
	.high_mem	dw 0

; ------------------------------------------------------------------
; os_int_1Ah -- Middle-man between the INT 1Ah call and the kernel/apps (used for timezones).
; IN/OUT: same as int 1Ah

os_int_1Ah:
	push ds
	pusha

	movs ds, cs

	cmp ah, 2		; Read system time
	je .read_time
	
	cmp ah, 4		; Read system date
	je .read_date
	
	popa
	pop ds
	int 1Ah
	ret
	
.read_date:
	call .update_time

	popa
	mov dx, [.days]
	mov cx, [.years]
	pop ds
	ret
	
.read_time:
	call .update_time
	
	popa
	mov dh, [.seconds]
	mov cx, [.minutes]
	pop ds
	ret

.update_time:
	mov ah, 4
	int 1Ah
	mov [.days], dx
	mov [.years], cx
	
	mov ah, 2
	int 1Ah

	mov [.seconds], dh
	mov [.minutes], cx
	
	; Convert all of these values from BCD to integers
	
	mov cx, 7
	mov si, .seconds
	mov di, si
	
.loop:
	lodsb
	call os_bcd_to_int
	stosb
	
	loop .loop
	
	; Calculate the time with the time offset
	
	mov ax, [CONFIG_TIMEZONE_OFFSET]
	test ax, 8000h
	jnz .subtract
	
	xor dx, dx
	mov bx, 60
	div bx
	
	; DX = value to add to minutes
	; AX = value to add to hours
	
	add [.minutes], dl
	cmp byte [.minutes], 60
	jl .add_minutes_ok
	
	sub byte [.minutes], 60
	inc byte [.hours]
	cmp byte [.hours], 24
	jl .add_minutes_ok
	
	sub byte [.hours], 24
	inc byte [.days]
	
	; At this point I don't care
	
.add_minutes_ok:
	add [.hours], al
	cmp byte [.hours], 24
	jl .encodeandexit
	
	sub byte [.hours], 24
	inc byte [.days]
	
	jmp .encodeandexit
	
.subtract:
	neg ax
	
	xor dx, dx
	mov bx, 60
	div bx
	
	; DX = value to subtract from minutes
	; AX = value to subtract from hours

	sub [.minutes], dl
	cmp byte [.minutes], 0
	jge .sub_minutes_ok
	
	
	add byte [.minutes], 60
	dec byte [.hours]
	cmp byte [.hours], 0
	jge .sub_minutes_ok
	
	add byte [.hours], 24
	dec byte [.days]
	
	; At this point I don't care
	
.sub_minutes_ok:
	sub [.hours], al
	cmp byte [.hours], 0
	jge .encodeandexit
	
	add byte [.hours], 24
	dec byte [.days]
	
.encodeandexit:
	mov cx, 7
	mov si, .seconds
	mov di, si
	
.encode_loop:
	lodsb
	call os_int_to_bcd
	stosb
	loop .encode_loop

	ret
	
	
	.seconds	db 0
	.minutes	db 0
	.hours		db 0
	.days		db 0
	.months		db 0
	.years		db 0
	.centuries	db 0

; ------------------------------------------------------------------
; int_set_stack -- Sets up allocation for the system stack.
; IN: SI = return address, AX = RAM top (in 16-byte blocks),
;     BX = number of 16-byte blocks to allocate (up to 4096 blocks, 64 kB)
; *** DO NOT CALL, USE JMP AND PASS RETURN ADDRESS!!! ***

int_set_stack:
	cli
	sub ax, bx	; Calculate the stack segment by subtracting the ram top and blocks
	mov ss, ax

	shl bx, 4	; Calculate the top stack pointer value
	sub bx, 2
	mov sp, bx
	sti
	jmp si

; Generic jump location for function termination

int_popa_ret:
	popa
	ret

; ==================================================================
