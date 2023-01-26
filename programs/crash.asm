; ------------------------------------------------------------------
; MichalOS INT 00 crash test
; ------------------------------------------------------------------

	%include "include/program.inc"
	
start:
	mov ax, 9
	mov bx, 0
	div bx

	ret
	