; ------------------------------------------------------------------
; MichalOS Arcade
; ------------------------------------------------------------------

	%INCLUDE "michalos.inc"

start:
	mov ax, .gamelist
	mov bx, .help_msg1
	mov cx, .help_msg2
	mov si, .callback
	call os_list_dialog_tooltip

	shl ax, 1
	mov bx, ax

	mov byte [0082h], 1
	call [.bootlist - 2 + bx]

.dummy:
	ret

.callback:
	ret

	.gamelist	db "Donkey,Exit", 0
	.help_msg1	db "Please select a game:"	; No need to zero-terminate here
	.help_msg2	db 0

	.bootlist	dw donkey, .dummy

	%include "arcade/donkey.asm"