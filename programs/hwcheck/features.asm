checkfeatures:
	mov eax, [basicid]		; Is the CPU compatible with this instruction?
	cmp eax, 1
	jge features
	
	jmp main_loop
	
features:	
	mov eax, 1
	cpuid
	mov di, 24000
features_loop:
	mov al, dl
	and al, 1
	mov [di], al
	shr edx, 1

	inc di
	cmp di, 24032
	jl near features_loop
	
features_loop2:
	mov al, cl
	and al, 1
	mov [di], al
	shr ecx, 1
	
	inc di
	cmp di, 24064
	jl near features_loop2
	
features_output:
	mov di, 24000
	mov cx, feature00
	mov dl, 0
	mov dh, 1
	
features_loop_output:
	call os_move_cursor
	
	mov si, cx
	call os_print_string
	
	mov al, [di]
	cmp al, 1
	je near feature_enabled
	
	mov si, disabled
	call os_print_string
	
feature_loop_continue:
	inc di
	inc dh
	add cx, 14
	
	cmp di, 24064
	je near feature_end
	
	cmp dh, 24
	je near feature_loop_nextcolumn
	
	jmp features_loop_output
	
feature_enabled:
	mov si, enabled
	call os_print_string
	jmp feature_loop_continue
	
feature_loop_nextcolumn:
	add dl, 26
	mov dh, 1
	jmp features_loop_output
	
feature_end:
	call os_wait_for_key
	jmp main_loop
	
	feature00 db 'fpu:         ', 0
	feature01 db 'vme:         ', 0
	feature02 db 'de:          ', 0
	feature03 db 'pse:         ', 0
	feature04 db 'tsc:         ', 0
	feature05 db 'msr:         ', 0
	feature06 db 'pae:         ', 0
	feature07 db 'mce:         ', 0
	feature08 db 'cx8:         ', 0
	feature09 db 'apic:        ', 0
	feature10 db '<reserved>   ', 0
	feature11 db 'sep:         ', 0
	feature12 db 'mtrr:        ', 0
	feature13 db 'pge:         ', 0
	feature14 db 'mca:         ', 0
	feature15 db 'cmov:        ', 0
	feature16 db 'pat:         ', 0
	feature17 db 'pse-36:      ', 0
	feature18 db 'psn:         ', 0
	feature19 db 'clfsh:       ', 0
	feature20 db '<reserved>   ', 0
	feature21 db 'ds:          ', 0
	feature22 db 'acpi:        ', 0
	feature23 db 'mmx:         ', 0
	feature24 db 'fxsr:        ', 0
	feature25 db 'sse:         ', 0
	feature26 db 'sse2:        ', 0
	feature27 db 'ss:          ', 0
	feature28 db 'htt:         ', 0
	feature29 db 'tm:          ', 0
	feature30 db 'ia64:        ', 0
	feature31 db 'pbe:         ', 0
	feature32 db 'sse3:        ', 0
	feature33 db 'pclmulqdq:   ', 0
	feature34 db 'dtes64:      ', 0
	feature35 db 'monitor:     ', 0
	feature36 db 'ds-cpl:      ', 0
	feature37 db 'vmx:         ', 0
	feature38 db 'smx:         ', 0
	feature39 db 'est:         ', 0
	feature40 db 'tm2:         ', 0
	feature41 db 'ssse3:       ', 0
	feature42 db 'cnxt-id:     ', 0
	feature43 db 'sdbg:        ', 0
	feature44 db 'fma:         ', 0
	feature45 db 'cx16:        ', 0
	feature46 db 'xtpr:        ', 0
	feature47 db 'pdcm:        ', 0
	feature48 db '<reserved>   ', 0
	feature49 db 'pcid:        ', 0
	feature50 db 'dca:         ', 0
	feature51 db 'sse4.1:      ', 0
	feature52 db 'sse4.2:      ', 0
	feature53 db 'x2apic:      ', 0
	feature54 db 'movbe:       ', 0
	feature55 db 'popcnt:      ', 0
	feature56 db 'tsc-deadline:', 0
	feature57 db 'aes:         ', 0
	feature58 db 'xsave:       ', 0
	feature59 db 'osxsave:     ', 0
	feature60 db 'avx:         ', 0
	feature61 db 'f16c:        ', 0
	feature62 db 'rdrnd:       ', 0
	feature63 db 'hypervisor:  ', 0
