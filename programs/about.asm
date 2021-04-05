; ------------------------------------------------------------------
; About MichalOS
; ------------------------------------------------------------------

	%INCLUDE "michalos.inc"

start:
	mov bx, .footer_msg
	call draw_background

	call os_draw_logo
	
	mov16 dx, 2, 10
	call os_move_cursor
	mov si, osname
	call os_print_string
	
	mov16 dx, 0, 12
	call os_move_cursor
	mov si, .introtext0
	call os_print_string
	
	call os_hide_cursor
	
	call os_wait_for_key
	cmp al, ' '
	je .hall_of_fame
	cmp al, 'l'
	je .license
	
	ret

.hall_of_fame:
	mov bx, .footer_msg_hall
	call draw_background

	call os_draw_logo
	
	mov16 dx, 0, 10
	call os_move_cursor
	mov si, .hoftext0
	call os_print_string
	
	call os_hide_cursor
	
	call os_wait_for_key
	cmp al, ' '
	je start
	cmp al, 'l'
	je .license
	
	ret
	
.license:
	mov cl, 0

	call .draw_license

.licenseloop:
	call os_wait_for_key
	
	cmp al, ' '
	je .hall_of_fame
	cmp al, 'l'
	je start
	cmp ah, KEY_UP
	je .license_cur_up
	cmp ah, KEY_DOWN
	je .license_cur_down
	
	ret
	
.license_cur_down:
	cmp cl, 6
	je .licenseloop
	
	inc cl
	call .draw_license
	jmp .licenseloop
		
.license_cur_up:
	cmp cl, 0
	je .licenseloop
	
	dec cl
	call .draw_license
	jmp .licenseloop
		
.draw_license:
	mov bx, .footer_msg_lic
	push cx
	call draw_background
	pop cx
	
	mov si, .licensetext
	call print_text_wall
	ret
		
	.introtext0				db '  MichalOS: Copyright (C) Michal Prochazka, 2017-2021', 13, 10
	.introtext1				db '  MichalOS Font & logo: Copyright (C) Krystof Kubin, 2017-2021', 13, 10, 10
	.introtext2				db '  If you find a bug, or you just have a feature request, please leave a ticket', 13, 10
	.introtext3				db '  in the Tickets section on SourceForge. I welcome any kind of feedback.', 0
	
	.hoftext0				db '  Special thanks to: (in alphabetical order)', 13, 10
	.hoftext1				db '    fanzyflani for porting the Reality AdLib Tracker to NASM', 13, 10
	.hoftext2				db '    Ivan Ivanov for discovering and helping with fixing bugs', 13, 10
	.hoftext3				db '    Jasper Ziller for making the Fisher game', 13, 10
	.hoftext4				db '    Leonardo Ono for making the Snake game', 13, 10
	.hoftext5				db '    Mike Saunders for making the base OS - MikeOS :)', 13, 10
	.hoftext6				db '    My wonderful classmates for providing feedback (and doing bug-hunting)', 13, 10
	.hoftext7				db '    REALITY for releasing the Reality AdLib Tracker source code back in 1995', 13, 10
	.hoftext8				db '    Sebastian Mihai for creating & releasing the source code of aSMtris', 13, 10
	.hoftext9				db '    ZeroKelvinKeyboard for creating TachyonOS & writing apps for MikeOS', 13, 10, 0

	.footer_msg				db '[Space] Visit the hall of fame [L] View the license', 0
	.footer_msg_hall		db '[Space] Go back [L] View the license', 0
	.footer_msg_lic			db '[Space] Visit the hall of fame [L] Go back [Up/Down] Scroll', 0

	.licensetext:			incbin "../misc/LICENSE"
							db 0
							
	%INCLUDE "../system/features/name.asm"

print_text_wall:
	pusha
;	mov al, cl
;	call os_print_2hex
	
	cmp cl, 0
	je .print_loop
	
.skip_loop:
	lodsb
	
	cmp al, 0
	je .exit
	
	cmp al, 10
	jne .skip_loop
	
	loop .skip_loop
	
.print_loop:
	lodsb
	cmp al, 0
	je .exit
	
	call os_putchar
	
	call os_get_cursor_pos
	cmp dh, 24
	jne .print_loop
	
.exit:
	popa
	ret
	
draw_background:
	mov ax, .title_msg
	mov cx, 7
	call os_draw_background
	ret
	
	.title_msg			db 'About MichalOS', 0

; ------------------------------------------------------------------
