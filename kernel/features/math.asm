; ==================================================================
; MichalOS Math functions
; ==================================================================

; ------------------------------------------------------------------
; os_get_random -- Return a random integer between low and high (inclusive)
; IN: AX = low integer, BX = high integer
; OUT: CX = random integer

os_get_random:
	push dx
	push bx
	push ax

	sub bx, ax			; We want a number between 0 and (high-low)
	call .generate_random
	mov dx, bx
	inc dx
	mul dx
	mov cx, dx

	pop ax
	pop bx
	pop dx
	add cx, ax			; Add the low offset back
	ret

.generate_random:
	push dx

	mov ax, [cs:os_random_seed]
	mov dx, 0x7383			; The magic number (random.org)
	mul dx				; DX:AX = AX * DX
	mov [cs:os_random_seed], ax

 	pop dx
	ret

	os_random_seed	dw 0x7384

; ------------------------------------------------------------------
; os_bcd_to_int -- Converts a binary coded decimal number to an integer
; IN: AL = BCD number
; OUT: AX = integer value

os_bcd_to_int:
	push cx
	push bx

	mov bl, al			; Store entire number for now

	and ax, 0Fh			; Zero-out high bits
	mov cx, ax			; CH/CL = lower BCD number, zero extended

	shr bl, 4			; Move higher BCD number into lower bits, zero fill msb
	mov al, 10
	mul bl				; AX = 10 * BL

	add ax, cx			; Add lower BCD to 10*higher

	pop bx
	pop cx
	ret


; ------------------------------------------------------------------
; os_int_to_bcd -- Converts an integer to a binary coded decimal number
; IN: AL = integer value
; OUT: AL = BCD number

os_int_to_bcd:
	push bx
	push dx

	movzx ax, al
	xor dx, dx
	
	mov bx, 10
	div bx
	
	shl al, 4
	add al, dl
	
	pop dx
	pop bx
	ret


; ------------------------------------------------------------------
; os_math_power -- Calculates EAX^EBX.
; IN: EAX^EBX = input
; OUT: EAX = result

os_math_power:
	pushad
	cmp ebx, 1
	je .power_end

	test ebx, ebx
	jz .zero

	mov ecx, ebx				; Prepare the data
	mov ebx, eax

.power_loop:
	mul ebx
	dec ecx

	cmp ecx, 1
	jnle .power_loop

.power_end:
	mov [cs:.tmp_dword], eax
	popad
	mov eax, [cs:.tmp_dword]
	xor edx, edx
	ret

.zero:
	popad
	mov eax, 1
	xor edx, edx
	ret
	
	.tmp_dword		dd 0
	
; ------------------------------------------------------------------
; os_math_root -- Approximates the EBXth root of EAX.
; IN: EAX = input, EBX = root
; OUT: EAX(EDX = 0) = result; EAX to EDX = range

os_math_root:
	pushad
	mov ecx, eax				; Prepare the data
	mov esi, 2

.root_loop:
	mov eax, esi
	call os_math_power

	cmp eax, ecx
	je .root_exact
	jg .root_range
	
	inc esi
	jmp .root_loop

.root_exact:
	mov [cs:.tmp_dword], esi
	popad
	mov eax, [cs:.tmp_dword]
	xor edx, edx
	ret

.root_range:
	mov [cs:.tmp_dword], esi
	popad
	mov edx, [cs:.tmp_dword]
	mov eax, edx
	dec eax
	ret
	
	.tmp_dword		dd 0

; ==================================================================
