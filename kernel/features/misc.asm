; ==================================================================
; MichalOS Miscellaneous functions
; ==================================================================

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
	mov si, .sub_fatalerr_data
	mov di, 100h
	call os_decompress_zx7
	jmp 100h

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
	mov [.conv_mem], ax		; ...and store it
	
	mov ah, 88h				; Also get the high memory (>1MB)...
	int 15h
	mov [.high_mem], ax		; ...and store it too
	popa
	mov ax, [.conv_mem]
	mov bx, [.high_mem]
	ret

	.conv_mem	dw 0
	.high_mem	dw 0

; ------------------------------------------------------------------
; os_int_1Ah -- Middle-man between the INT 1Ah call and the kernel/apps (used for timezones).
; IN/OUT: same as int 1Ah

os_int_1Ah:
	pusha

	cmp ah, 2		; Read system time
	je .read_time
	
	cmp ah, 4		; Read system date
	je .read_date
	
	popa
	int 1Ah
	ret
	
.read_date:
	call .update_time
	popa
	mov dx, [.days]
	mov cx, [.years]
	ret
	
.read_time:
	call .update_time
	
	popa
	mov dh, [.seconds]
	mov cx, [.minutes]
	
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
	
	mov ax, [57081]
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

; Generic jump location for function termination

int_popa_ret:
	popa
	ret

; ==================================================================
