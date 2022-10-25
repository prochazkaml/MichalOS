; ------------------------------------------------------------------
; About MichalOS
; ------------------------------------------------------------------

	%INCLUDE "michalos.inc"

start:
	mov bx, .footer_msg
	call draw_background

	mov16 dx, 0, 2
	call os_move_cursor

	call os_draw_logo
	
	mov16 dx, 2, 10
	call os_move_cursor
	call os_get_os_name
	call os_print_string
	mov si, .commitver
	call os_print_string
	
	mov16 dx, 0, 12
	call os_move_cursor
	mov si, .introtext
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

	mov16 dx, 0, 2
	call os_move_cursor

	call os_draw_logo
	
	mov16 dx, 0, 10
	call os_move_cursor
	mov si, .hoftext
	call os_print_string
	
	call os_hide_cursor
	
	call os_wait_for_key
	cmp al, ' '
	je start
	cmp al, 'l'
	je .license
	
	ret
	
.license:
	clr cl

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
	test cl, cl
	jz .licenseloop
	
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
		
	.introtext				db '  MichalOS: Copyright (C) Michal Prochazka, 2017-2022', 13, 10
							db '  MichalOS Font & logo: Copyright (C) Krystof Kubin, 2017-2022', 13, 10, 10
							db '  If you find a bug, or you just have a feature request, please leave a ticket', 13, 10
							db '  in the Issues section on GitHub. I welcome all kinds of feedback.', 13, 10, 10, 
							db '  https://github.com/prochazkaml/MichalOS', 13, 10, 10
							db '  https://www.prochazka.ml/', 0
	
	.hoftext				db '  Special thanks to: (in alphabetical order)', 13, 10
							db '    fanzyflani for porting the Reality AdLib Tracker to NASM', 13, 10
							db '    Ivan Ivanov for discovering and helping with fixing bugs', 13, 10
							db '    Jasper Ziller for making the Fisher game', 13, 10
							db '    Leonardo Ono for making the Snake game', 13, 10
							db '    MikeOS developers for making the base OS - MikeOS :)', 13, 10
							db '    My wonderful classmates for providing feedback (and doing bug-hunting)', 13, 10
							db '    REALITY for releasing the Reality AdLib Tracker source code back in 1995', 13, 10
							db '    Sebastian Mihai for creating & releasing the source code of aSMtris', 13, 10
							db '    Shoaib Jamal for making the MichalOS website', 13, 10
							db '    ZeroKelvinKeyboard for creating TachyonOS & writing apps for MikeOS', 13, 10, 0

	.footer_msg				db '[Space] Visit the hall of fame [L] View the license', 0
	.footer_msg_hall		db '[Space] Go back [L] View the license', 0
	.footer_msg_lic			db '[Space] Visit the hall of fame [L] Go back [Up/Down] Scroll', 0

	.commitver				db ' ', GIT, 0

	.licensetext:			incbin "../misc/LICENSE"
							db 0

print_text_wall:
	pusha
;	mov al, cl
;	call os_print_2hex
	
	test cl, cl
	jz .print_loop
	
.skip_loop:
	lodsb
	
	test al, al
	jz .exit
	
	cmp al, 10
	jne .skip_loop
	
	loop .skip_loop
	
.print_loop:
	lodsb
	test al, al
	jz .exit
	
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
