extendedcpu:
	mov si, name
	call os_print_string
	cmp dword [extendedid], 0
	jge .error
	
	cmp eax, 80000004h
	jge cpuname
	
.error:
	mov si, noimp
	call os_print_string
	jmp cpuidcheck
	
cpuname:
	mov eax, 80000002h
	cpuid
	mov [p1], eax
	mov [p2], ebx
	mov [p3], ecx
	mov [p4], edx
	
	mov eax, 80000003h
	cpuid
	mov [p5], eax
	mov [p6], ebx
	mov [p7], ecx
	mov [p8], edx
	
	mov eax, 80000004h
	cpuid
	mov [p9], eax
	mov [p10], ebx
	mov [p11], ecx
	mov [p12], edx
	
	mov si, p1
	call os_print_string
	
cpuidcheck:	
	call os_print_newline
	mov si, cpuidbas
	call os_print_string
	mov eax, [basicid]
	call os_print_8hex
	mov si, unit_hex
	call os_print_string
	call os_print_newline
	
	mov si, cpuidext
	call os_print_string
	mov eax, [extendedid]
	call os_print_8hex
	mov si, unit_hex
	call os_print_string
	call os_print_newline
	
;mov ecx, 0xe7
;rdmsr
;call os_print_8hex
;mov eax, edx
;call os_print_8hex
;call os_print_newline
;mov ecx, 0xe8
;rdmsr
;call os_print_8hex
;mov eax, edx
;call os_print_8hex
;call os_print_newline

	
extendedcpuend:
	call os_wait_for_key
	jmp main_loop
	
	name		db 'Name            ', 0
	cpuidbas	db 'Basic CPUID:    ', 0
	cpuidext	db 'Ext. CPUID:     ', 0
