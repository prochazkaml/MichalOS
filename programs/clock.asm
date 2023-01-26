; ------------------------------------------------------------------
; MichalOS Clock
; ------------------------------------------------------------------

	%INCLUDE "include/program.inc"

start:
	mov cx, 11932
	mov si, .interrupt
	call os_attach_app_timer
	
	call os_hide_cursor

.time:
	call os_speaker_off
	mov byte [.hundreds], 0FFh
	mov byte [.timer_running], 0
	
	call .draw_background
	
.timeloop:
	clc
	mov ah, 02h			; Get the time
	call os_int_1Ah

	mov [.seconds], dh
	mov [.minutes], cl
	mov [.hours], ch
	
	call .draw_time
	
	mov ah, 04h			; Get the date
	call os_int_1Ah

	mov [.day], dl
	mov [.month], dh
	mov [.year], cl
	mov [.century], ch

	call .draw_date
	
	hlt
	call os_check_for_key
	cmp al, 27
	je .exit
	cmp al, '2'
	je .stopwatch
	cmp al, '3'
	je .timer
	
	jmp .timeloop

.stopwatch:
	call os_speaker_off
	call .draw_background
	mov dword [.hours], 0
	mov byte [.timer_running], 0
	
.stopwatchloop:
	call .draw_time
	
	hlt
	call os_check_for_key
	
	cmp al, 27
	je .exit
	cmp al, '1'
	je .time
	cmp al, '3'
	je .timer
	cmp al, ' '
	je .toggle_stopwatch
	cmp al, 'x'
	je .reset_stopwatch
	
	jmp .stopwatchloop
	
	
.reset_stopwatch:
	mov dword [.hours], 0
	mov byte [.timer_running], 0
	jmp .stopwatchloop
	
.toggle_stopwatch:
	xor byte [.timer_running], 1
	jmp .stopwatchloop
	
.timer:
	call .draw_background
	mov dh, 7
	mov dl, 10
	call os_move_cursor
	mov si, .upstring
	call os_print_string
	
	mov dh, 17
	mov dl, 1
	call os_move_cursor
	mov si, .downstring
	call os_print_string
	
	mov dword [.hours], 0
	mov byte [.timer_running], 0
	
.timer_loop:
	call .draw_time
	hlt
	call os_check_for_key
	
	cmp al, 27
	je .exit
	cmp al, '1'
	je .time
	cmp al, '2'
	je .stopwatch
	cmp al, ' '
	je .toggle_timer
	cmp al, 'x'
	je .reset_timer
	
	mov si, .hours
	cmp al, 'q'
	je .inc_10
	cmp al, 'w'
	je .inc
	cmp al, 'a'
	je .dec_10
	cmp al, 's'
	je .dec
	
	mov si, .minutes
	cmp al, 'e'
	je .inc_10
	cmp al, 'r'
	je .inc
	cmp al, 'd'
	je .dec_10
	cmp al, 'f'
	je .dec
	
	mov si, .seconds
	cmp al, 't'
	je .inc_10
	cmp al, 'y'
	je .inc
	cmp al, 'g'
	je .dec_10
	cmp al, 'h'
	je .dec
	
	jmp .timer_loop

.reset_timer:
	mov dword [.hours], 0
	mov byte [.timer_running], 0
	call os_speaker_off
	jmp .timer_loop
	
.inc_10:
	mov al, [si]
	mov cx, 10
	
.inc_loop:
	call .increment_number_60
	loop .inc_loop
	mov [si], al
	jmp .timer_loop

.dec_10:
	mov al, [si]
	mov cx, 10
	
.dec_loop:
	call .decrement_number_60
	loop .dec_loop
	mov [si], al
	jmp .timer_loop

.inc:
	mov al, [si]
	call .increment_number_60
	mov [si], al
	jmp .timer_loop
	
.dec:
	mov al, [si]
	call .decrement_number_60
	mov [si], al
	jmp .timer_loop
	
.toggle_timer:
	xor byte [.timer_running], 2
	jmp .timer_loop
	
.draw_time:
	pusha
	mov al, [.hours]	; Draw the hours value
	mov dh, 9
	mov dl, 1
	rol al, 4
	call .draw_numbers
	add dl, 12
	rol al, 4
	call .draw_numbers
	add dl, 12

	call .draw_colon
	add dl, 4
	
	mov al, [.minutes]	; Draw the minutes value
	mov dh, 9
	rol al, 4
	call .draw_numbers
	add dl, 12
	rol al, 4
	call .draw_numbers
	add dl, 12
	
	call .draw_colon
	add dl, 4
	
	mov al, [.seconds]	; Draw the seconds value
	mov dh, 9
	rol al, 4
	call .draw_numbers
	add dl, 12
	rol al, 4
	call .draw_numbers
	add dl, 12

	mov al, [.hundreds]
	cmp al, 0FFh
	je .no_hundreds
	
	mov dh, 17
	mov dl, 76
	call os_move_cursor
	
	push ax
	mov al, 2Eh
	call os_putchar
	pop ax
	
	call os_print_2hex
	
.no_hundreds:
	popa
	ret
	
.draw_date:
	pusha	
	mov dh, 17
	mov dl, 1
	call os_move_cursor
	
	mov al, [.day]
	call os_bcd_to_int
	clr ah
	call os_print_int
	
	call os_print_space
	
	mov al, [.month]
	call os_bcd_to_int
	dec al
	clr ah
	mov bx, 10
	push dx
	mul bx
	pop dx
	add ax, .m1
	mov si, ax
	call os_print_string
	
	mov si, .spacer2
	call os_print_string
	
	mov al, [.century]
	call os_bcd_to_int
	clr ah
	mov cx, ax

	mov al, [.year]
	call os_bcd_to_int
	clr ah

	xchg ax, cx
	mov bl, 100
	mul bl
	add ax, cx
	
	call os_print_int
	
	mov si, .spacer
	call os_print_string
	popa
	ret
	
.draw_numbers:	; IN: low 4 bits of AL; DH/DL = cursor position
	pusha
	and al, 0Fh
	mov bl, al
	mov ax, 77
	mul bl
	add ax, .n00
	call os_move_cursor
	mov si, ax
	call os_print_string
	inc dh
	add ax, 11
	call os_move_cursor
	mov si, ax
	call os_print_string
	inc dh
	add ax, 11
	call os_move_cursor
	mov si, ax
	call os_print_string
	inc dh
	add ax, 11
	call os_move_cursor
	mov si, ax
	call os_print_string
	inc dh
	add ax, 11
	call os_move_cursor
	mov si, ax
	call os_print_string
	inc dh
	add ax, 11
	call os_move_cursor
	mov si, ax
	call os_print_string
	inc dh
	add ax, 11
	call os_move_cursor
	mov si, ax
	call os_print_string
	popa
	ret
	
.draw_colon:		; IN: DH/DL = cursor position
	pusha
	mov ax, .na0
	call os_move_cursor
	mov si, ax
	call os_print_string
	inc dh
	add ax, 3
	call os_move_cursor
	mov si, ax
	call os_print_string
	inc dh
	add ax, 3
	call os_move_cursor
	mov si, ax
	call os_print_string
	inc dh
	add ax, 3
	call os_move_cursor
	mov si, ax
	call os_print_string
	inc dh
	add ax, 3
	call os_move_cursor
	mov si, ax
	call os_print_string
	inc dh
	add ax, 3
	call os_move_cursor
	mov si, ax
	call os_print_string
	inc dh
	add ax, 3
	call os_move_cursor
	mov si, ax
	call os_print_string
	popa
	ret
	
.draw_background:
	mov ax, .title_msg
	mov bx, .footer_msg
	mov cx, [CONFIG_DESKTOP_BG_COLOR]
	call os_draw_background
	ret
	
.exit:
	call os_return_app_timer
	call os_show_cursor
	ret
	
.interrupt:
	cmp byte [.timer_running], 1
	jne .no_stopwatch
	
	mov al, [.hundreds]
	call .increment_number
	mov [.hundreds], al
	jnc .no_stopwatch
	
	mov al, [.seconds]
	call .increment_number_60
	mov [.seconds], al
	jnc .no_stopwatch
	
	mov al, [.minutes]
	call .increment_number_60
	mov [.minutes], al
	jnc .no_stopwatch
	
	mov al, [.hours]
	call .increment_number
	mov [.hours], al
	jnc .no_stopwatch
	
.no_stopwatch:
	cmp byte [.timer_running], 2
	jne .no_timer
	
	cmp dword [.hours], 0
	je .set_off

	mov al, [.hundreds]
	call .decrement_number
	mov [.hundreds], al
	jnc .no_timer
	
	mov al, [.seconds]
	call .decrement_number_60
	mov [.seconds], al
	jnc .no_timer
	
	mov al, [.minutes]
	call .decrement_number_60
	mov [.minutes], al
	jnc .no_timer
	
	mov al, [.hours]
	call .decrement_number
	mov [.hours], al
	jnc .no_timer
	
.no_timer:
	ret
	
.set_off:
	mov ax, 523
	call os_speaker_tone
	mov byte [.timer_running], 0
	ret
	
.increment_number:
	inc al
	mov bl, al
	and bl, 0Fh
	cmp bl, 10
	jne .no_adjust
	
	add al, 16
	and al, 0F0h
	cmp al, 0A0h
	jne .no_adjust
	
	clr al
	stc
	ret
	
.increment_number_60:
	inc al
	mov bl, al
	and bl, 0Fh
	cmp bl, 10
	jne .no_adjust
	
	add al, 16
	and al, 0F0h
	cmp al, 060h
	jne .no_adjust
	
	clr al
	stc
	ret
	
.decrement_number:
	dec al
	mov bl, al
	and bl, 0Fh
	cmp bl, 15
	jne .no_adjust
	
	and al, 0F0h
	add al, 9
	
	mov bl, al
	and bl, 0F0h
	cmp bl, 0F0h
	jne .no_adjust
	
	mov al, 99h
	stc
	ret
	
.decrement_number_60:
	dec al
	mov bl, al
	and bl, 0Fh
	cmp bl, 15
	jne .no_adjust
	
	and al, 0F0h
	add al, 9
	
	mov bl, al
	and bl, 0F0h
	cmp bl, 0F0h
	jne .no_adjust
	
	mov al, 59h
	stc
	ret
	
.no_adjust:
	clc
	ret

	.spacer				db '        ', 0
	.spacer2			db ', ', 0
	
	.title_msg			db 'MichalOS Clock', 0
	.footer_msg			db '[1/2/3] - Clock/Stopwatch/Timer, [Space] - Start stopwatch/timer, [X] - Reset', 0

	.timer_running		db 0
	.hours				db 0
	.minutes			db 0
	.seconds			db 0
	.hundreds			db 0
	.day				db 0
	.month				db 0
	.year				db 0
	.century			db 0
	
	.upstring			db 'Q           W               E           R               T           Y', 0
	.downstring			db 'A           S               D           F               G           H', 0
	
	.n00				db 32,  32,  219, 219, 219, 219, 219, 219, 32,  32,  0
	.n01				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n02				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n03				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n04				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n05				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n06				db 32,  32,  219, 219, 219, 219, 219, 219, 32,  32,  0

	.n10				db 32,  32,  32,  32,  219, 219, 32,  32,  32,  32,  0
	.n11				db 32,  32,  219, 219, 219, 219, 32,  32,  32,  32,  0
	.n12				db 219, 219, 32,  32,  219, 219, 32,  32,  32,  32,  0
	.n13				db 32,  32,  32,  32,  219, 219, 32,  32,  32,  32,  0
	.n14				db 32,  32,  32,  32,  219, 219, 32,  32,  32,  32,  0
	.n15				db 32,  32,  32,  32,  219, 219, 32,  32,  32,  32,  0
	.n16				db 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 0

	.n20				db 32,  32,  219, 219, 219, 219, 219, 219, 32,  32,  0
	.n21				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n22				db 32,  32,  32,  32,  32,  32,  219, 219, 32,  32,  0
	.n23				db 32,  32,  32,  32,  219, 219, 32,  32,  32,  32,  0
	.n24				db 32,  32,  219, 219, 32,  32,  32,  32,  32,  32,  0
	.n25				db 219, 219, 32,  32,  32,  32,  32,  32,  32,  32,  0
	.n26				db 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 0

	.n30				db 32,  32,  219, 219, 219, 219, 219, 219, 32,  32,  0
	.n31				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n32				db 32,  32,  32,  32,  32,  32,  32,  32,  219, 219, 0
	.n33				db 32,  32,  32,  32,  219, 219, 219, 219, 32,  32,  0
	.n34				db 32,  32,  32,  32,  32,  32,  32,  32,  219, 219, 0
	.n35				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n36				db 32,  32,  219, 219, 219, 219, 219, 219, 32,  32,  0
	
	.n40				db 219, 219, 32,  32,  32,  32,  32,  32,  32,  32,  0
	.n41				db 219, 219, 32,  32,  219, 219, 32,  32,  32,  32,  0
	.n42				db 219, 219, 32,  32,  219, 219, 32,  32,  32,  32,  0
	.n43				db 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 0
	.n44				db 32,  32,  32,  32,  219, 219, 32,  32,  32,  32,  0
	.n45				db 32,  32,  32,  32,  219, 219, 32,  32,  32,  32,  0
	.n46				db 32,  32,  32,  32,  219, 219, 32,  32,  32,  32,  0

	.n50				db 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 0
	.n51				db 219, 219, 32,  32,  32,  32,  32,  32,  32,  32,  0
	.n52				db 219, 219, 32,  32,  32,  32,  32,  32,  32,  32,  0
	.n53				db 219, 219, 219, 219, 219, 219, 219, 219, 32,  32,  0
	.n54				db 32,  32,  32,  32,  32,  32,  32,  32,  219, 219, 0
	.n55				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n56				db 32,  32,  219, 219, 219, 219, 219, 219, 32,  32,  0

	.n60				db 32,  32,  219, 219, 219, 219, 219, 219, 32,  32,  0
	.n61				db 219, 219, 32,  32,  32,  32,  32,  32,  32,  32,  0
	.n62				db 219, 219, 32,  32,  32,  32,  32,  32,  32,  32,  0
	.n63				db 219, 219, 219, 219, 219, 219, 219, 219, 32,  32,  0
	.n64				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n65				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n66				db 32,  32,  219, 219, 219, 219, 219, 219, 32,  32,  0

	.n70				db 219, 219, 219, 219, 219, 219, 219, 219, 219, 219, 0
	.n71				db 32,  32,  32,  32,  32,  32,  32,  32,  219, 219, 0
	.n72				db 32,  32,  32,  32,  32,  32,  219, 219, 32,  32,  0
	.n73				db 32,  32,  32,  32,  219, 219, 32,  32,  32,  32,  0
	.n74				db 32,  32,  219, 219, 32,  32,  32,  32,  32,  32,  0
	.n75				db 219, 219, 32,  32,  32,  32,  32,  32,  32,  32,  0
	.n76				db 219, 219, 32,  32,  32,  32,  32,  32,  32,  32,  0

	.n80				db 32,  32,  219, 219, 219, 219, 219, 219, 32,  32,  0
	.n81				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n82				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n83				db 32,  32,  219, 219, 219, 219, 219, 219, 32,  32,  0
	.n84				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n85				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n86				db 32,  32,  219, 219, 219, 219, 219, 219, 32,  32,  0

	.n90				db 32,  32,  219, 219, 219, 219, 219, 219, 32,  32,  0
	.n91				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n92				db 219, 219, 32,  32,  32,  32,  32,  32,  219, 219, 0
	.n93				db 32,  32,  219, 219, 219, 219, 219, 219, 219, 219, 0
	.n94				db 32,  32,  32,  32,  32,  32,  32,  32,  219, 219, 0
	.n95				db 32,  32,  32,  32,  32,  32,  32,  32,  219, 219, 0
	.n96				db 32,  32,  219, 219, 219, 219, 219, 219, 32,  32,  0

	.na0				db 32,  32,  0
	.na1				db 219, 219, 0
	.na2				db 32,  32,  0
	.na3				db 32,  32,  0
	.na4				db 32,  32,  0
	.na5				db 219, 219, 0
	.na6				db 32,  32,  0

	.m1					db 'January', 0, 0, 0
	.m2					db 'February', 0, 0
	.m3					db 'March', 0, 0, 0, 0, 0
	.m4					db 'April', 0, 0, 0, 0, 0
	.m5					db 'May', 0, 0, 0, 0, 0, 0, 0
	.m6					db 'June', 0, 0, 0, 0, 0, 0
	.m7					db 'July', 0, 0, 0, 0, 0, 0
	.m8					db 'August', 0, 0, 0, 0
	.m9					db 'September', 0
	.m10				db 'October', 0, 0, 0
	.m11				db 'November', 0, 0
	.m12				db 'December', 0, 0
	
	
; ------------------------------------------------------------------
