checkvendor:				; CPU vendor
	call background
	
	mov si, msg0
	call os_print_string
	
	mov eax, [basicid]		; Is the CPU compatible with this instruction?
	cmp eax, 1
	jge vendor
	
	mov si, noimp
	call os_print_string
	
	jmp checkfamily
	
vendor:
	mov eax, 0
	cpuid
	
	mov [p1], ebx
	mov [p2], edx
	mov [p3], ecx
	
	mov si, p1
	call os_print_string
	
checkfamily:				; Family info
	call os_print_newline

	mov eax, [basicid]		; Is the CPU compatible with this instruction?
	cmp eax, 1
	jge steppingid			; If it is, continue to the %INCLUDEd file below...
	
	mov si, msg1
	call os_print_string
	mov si, noimp
	call os_print_string
	call os_print_newline
	mov si, msg2
	call os_print_string
	mov si, noimp
	call os_print_string
	call os_print_newline
	mov si, msg3
	call os_print_string
	mov si, noimp
	call os_print_string
	call os_print_newline
	mov si, msg4
	call os_print_string
	mov si, noimp
	call os_print_string
	call os_print_newline

	call os_wait_for_key
	
	jmp main_loop

steppingid:
	mov eax, 1
	cpuid
	
	mov edx, 0
	mov ecx, 16
	div ecx
	
	mov [p1], edx
	
model:
	mov edx, 0
	mov ecx, 16
	div ecx
	
	mov [p2], edx
	
family:
	mov edx, 0
	mov ecx, 16
	div ecx
	
	mov [p3], edx
	
cputype:
	mov edx, 0
	mov ecx, 4
	div ecx
	
	mov [p4], edx
	
	mov edx, 0				; Skip the next 2 bits, they are reserved
	mov ecx, 4
	div ecx
	
extmodel:
	mov edx, 0
	mov ecx, 4
	div ecx
	
	mov [p5], edx
	
extfamily:
	mov edx, 0
	mov ecx, 4
	div ecx
	
	mov [p6], edx
	
familyoutput:
	mov si, msg1
	call os_print_string
	mov eax, [p1]
	call os_int_to_string
	mov si, ax
	call os_print_string
	call os_print_newline
	
	mov si, msg2
	call os_print_string
	mov eax, [p5]			; Get the high 4 bits
	mov bx, 16
	mul bx					; Multiply them by 16			
	mov ebx, eax			; Store the result to EBX
	mov eax, [p2]			; Get the low 4 bits
	add eax, ebx			; Add the high and low bits together
	call os_int_to_string
	mov si, ax
	call os_print_string
	call os_print_newline
	
	mov si, msg3
	call os_print_string
	mov eax, [p6]			; Get the high 4 bits
	mov bx, 16
	mul bx					; Multiply them by 16			
	mov ebx, eax			; Store the result to EBX
	mov eax, [p3]			; Get the low 4 bits
	add eax, ebx			; Add the high and low bits together
	call os_int_to_string
	mov si, ax
	call os_print_string
	call os_print_newline
	
	mov si, msg4
	call os_print_string
	mov eax, [p4]
	call os_int_to_string
	mov si, ax
	call os_print_string
	call os_print_newline
	
	mov si, convmem
	call os_print_string
	call os_get_memory
	call os_int_to_string
	mov si, ax
	call os_print_string
	mov si, unit_kb
	call os_print_string
	call os_print_newline
	
	mov si, highmem
	call os_print_string
	call os_get_memory
	mov ax, bx
	call os_32int_to_string
	mov si, ax
	call os_print_string
	mov si, unit_kb
	call os_print_string
	call os_get_memory
	cmp bx, 64512
	jne .not_more_ram

	mov si, or_more
	call os_print_string
	
.not_more_ram:
	call os_print_newline
	
	jmp extendedcpu
	
	msg0		db 'Vendor ID:      ', 0
	msg1		db 'Stepping ID:    ', 0
	msg2		db 'Model:          ', 0
	msg3		db 'Family:         ', 0
	msg4		db 'CPU type:       ', 0
	convmem		db 'Conv. memory:   ', 0
	highmem		db 'Ext. memory:    ', 0
	or_more		db ' (or more)', 0
