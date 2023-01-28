; ------------------------------------------------------------------
; MichalOS INT 00 crash test
; ------------------------------------------------------------------

	%include "include/program.inc"
	
start:
	mov eax, 12342123h
	mov ebx, 69696969h
	mov ecx, 44444444h
	mov edx, 65465465h
	mov esi, 87658786h
	mov edi, 65432123h
	
	call os_dump_registers
	call os_wait_for_key

	mov ax, 9
	mov bx, 0
	div bx

	ret
	