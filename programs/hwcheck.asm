; ------------------------------------------------------------------
; MichalOS Hardware checker
; ------------------------------------------------------------------

	%INCLUDE "include/program.inc"

start:
	clr eax			; Get the maximum parameter for basic CPUID
	cpuid
	mov [basicid], eax
	
	mov eax, 80000000h		; Get the maximum parameter for extended CPUID
	cpuid
	mov [extendedid], eax
	
main_loop:
	clr al
	mov cx, 64
	mov di, p1
	rep stosb
	
	call background
	mov ax, optionlist
	mov bx, optionmsg1
	mov cx, optionmsg2
	call os_list_dialog
	call background
	
	cmp ax, 1
	je checkvendor
	
	cmp ax, 2
	je checkfeatures
	
	cmp ax, 3
	je vesa
	
exit:
	call os_clear_screen
	ret
	
background:
	pusha
	call os_clear_screen
	mov ax, welcomemsg
	mov bx, footermsg
	mov cx, 11110000b
	call os_draw_background
	mov16 dx, 0, 2
	call os_move_cursor
	popa
	ret	
	
	%INCLUDE "hwcheck/basic.asm"
	%INCLUDE "hwcheck/features.asm"
	%INCLUDE "hwcheck/extended.asm"
	%INCLUDE "hwcheck/vesa.asm"
	
	basicid		dd 0
	extendedid	dd 0
	
	unit_kb		db ' kB', 0
	unit_mhz	db ' MHz', 0
	unit_hex	db 'h', 0
	
	noimp		db '<Unavailable>', 0
	enabled		db 'Enabled', 0
	disabled	db 'Disabled', 0

	welcomemsg	db 'MichalOS Hardware Checking Utility', 0
	footermsg	db 0
	
	optionmsg1	db 'Choose an option...', 0
	optionmsg2	db 0
	optionlist	db 'Basic system specifications,Processor features,VESA specifications', 0
	
buffer:	
	p0			dd 0
	p1			dd 0
	p2			dd 0
	p3			dd 0
	p4			dd 0
	p5			dd 0
	p6			dd 0
	p7			dd 0
	p8			dd 0
	p9			dd 0
	p10			dd 0
	p11			dd 0
	p12			dd 0
	p13			dd 0
	p14			dd 0
	p15			dd 0
	p16			dd 0
	pfinal		db 0
	
; ------------------------------------------------------------------

