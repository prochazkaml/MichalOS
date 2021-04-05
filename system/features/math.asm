; ==================================================================
; MATH ROUTINES
; ==================================================================

; ------------------------------------------------------------------
; os_seed_random -- Seed the random number generator based on the current state of registers and time
; IN: every register; OUT: Nothing (registers preserved)

os_seed_random:
	pusha

	mov ah, 02h
	int 1Ah
	
	xor ax, bx
	add ax, cx
	xor ax, dx
	add ax, si
	xor ax, di
	add ax, sp
	xor ax, bp
	add ax, 0xDEAD
	xor ax, 0xBEEF
	
	mov [os_random_seed], ax	; Store the data
	popa
	ret


	os_random_seed	dw 0


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
	push bx

	mov ax, [os_random_seed]
	mov dx, 0x7383			; The magic number (random.org)
	mul dx				; DX:AX = AX * DX
	mov [os_random_seed], ax

	pop bx
 	pop dx
	ret


; ------------------------------------------------------------------
; os_bcd_to_int -- Converts a binary coded decimal number to an integer
; IN: AL = BCD number; OUT: AX = integer value

os_bcd_to_int:
	pusha

	mov bl, al			; Store entire number for now

	and ax, 0Fh			; Zero-out high bits
	mov cx, ax			; CH/CL = lower BCD number, zero extended

	shr bl, 4			; Move higher BCD number into lower bits, zero fill msb
	mov al, 10
	mul bl				; AX = 10 * BL

	add ax, cx			; Add lower BCD to 10*higher
	mov [.tmp], ax

	popa
	mov ax, [.tmp]			; And return it in AX!
	ret


	.tmp	dw 0

	
; ------------------------------------------------------------------
; os_int_to_bcd -- Converts an integer to a binary coded decimal number
; IN: AL = integer value; OUT: AL = BCD number

os_int_to_bcd:
	pusha
	movzx ax, al
	xor dx, dx
	
	mov bx, 10
	div bx
	
	shl al, 4
	add dl, al
	
	mov [.tmp], dl
	popa
	mov al, [.tmp]
	ret

	.tmp	db 0


; Calculates EAX^EBX.
; IN: EAX^EBX = input
; OUT: EAX = result

os_math_power:
	pushad
	cmp ebx, 1
	je near .power_end
	cmp ebx, 0
	je near .zero
	mov ecx, ebx				; Prepare the data
	mov ebx, eax
.power_loop:
	mul ebx
	dec ecx
	cmp ecx, 1
	jnle .power_loop
.power_end:
	mov [.tmp_dword], eax
	popad
	mov eax, [.tmp_dword]
	xor edx, edx
	ret
.zero:
	popad
	mov eax, 1
	xor edx, edx
	ret
	
	.tmp_dword		dd 0
	.tmp_dword2		dd 0
	
; Calculates the EBX root of EAX.
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
	je near .root_exact
	jg near .root_range
	inc esi
	jmp .root_loop
.root_exact:
	mov [.tmp_dword], esi
	popad
	mov eax, [.tmp_dword]
	xor edx, edx
	ret
.root_range:
	mov [.tmp_dword2], esi
	dec esi
	mov [.tmp_dword], esi
	popad
	mov eax, [.tmp_dword]
	mov edx, [.tmp_dword2]
	ret
	
	.tmp_dword		dd 0
	.tmp_dword2		dd 0

; ==================================================================
