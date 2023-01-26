; ------------------------------------------------------------------
; Include file for MichalOS program or kernel module development
; ------------------------------------------------------------------

	BITS 16
	ORG 100h
	
	%include "include/constants.asm"
	%include "include/syscalls.asm"

; -----------------------------------------------------------------
