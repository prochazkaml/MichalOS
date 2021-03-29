; ------------------------------------------------------------------
; MichalOS Calculator (32-bit)
; ------------------------------------------------------------------

	%INCLUDE "michalos.inc"

start:
	call .draw_background

	mov ax, .options
	mov bx, .options_name
	mov cx, .footer_msg
	call os_list_dialog
	
	jc .exit
	
	cmp ax, 1
	je .plus
	
	cmp ax, 2
	je .minus
	
	cmp ax, 3
	je .multiply
	
	cmp ax, 4
	je .divide
	
	cmp ax, 5
	je .power
	
	cmp ax, 6
	je .square_root
	
	cmp ax, 7
	je .cube_root
	
.plus:
	call .draw_background
	call .get_numbers

	clr edx
	add eax, ebx

	jmp .result
	
.minus:
	call .draw_background
	call .get_numbers

	clr edx
	sub eax, ebx

	jmp .result
	
.multiply:
	call .draw_background
	call .get_numbers

	clr edx
	mul ebx

	jmp .result
	
.divide:
	call .draw_background
	call .get_numbers

	cmp ebx, 0
	je near .divide_error
	clr edx
	div ebx

	jmp .result
	
.power:
	call .draw_background
	call .get_numbers

	call os_math_power
	jmp .result
	
.square_root:
	call .draw_background
	call .get_number

	mov ebx, 2
	call os_math_root
	
	cmp edx, 0
	jne .root_result
	
	jmp .result
	
.cube_root:
	call .draw_background
	call .get_number
	
	mov ebx, 3
	call os_math_root
	
	cmp edx, 0
	jne .root_result
	
	jmp .result
	
.get_number:
	mov ax, .firstnumberstring
	mov bx, .number_msg
	call os_input_dialog
	mov si, ax
	call os_string_to_32int
	ret
	
.get_numbers:
	mov ax, .firstnumberstring
	mov bx, .firstnumber_msg
	call os_input_dialog
	mov si, ax
	call os_string_to_32int
	push eax

	mov ax, .secondnumberstring
	mov bx, .secondnumber_msg
	call os_input_dialog
	mov si, ax
	call os_string_to_32int
	
	mov ebx, eax
	pop eax
	
	ret

.root_result:
	mov si, .root_msg1
	mov di, .resultmsg
	call os_string_copy
	
	call os_32int_to_string		; We already have the result in EAX
	mov bx, ax
	mov ax, .resultmsg
	call os_string_add
	
	mov bx, .root_msg2
	call os_string_add
	
	mov eax, edx
	call os_32int_to_string
	mov bx, ax
	mov ax, .resultmsg
	call os_string_add
	
	mov ax, .resultmsg
	clr bx
	clr cx
	clr dx
	call os_dialog_box
	
	jmp start

.result:
	mov si, .result_msg
	mov di, .resultmsg
	call os_string_copy
	
	call os_32int_to_string		; We already have the result in EAX
	mov bx, ax
	mov ax, .resultmsg
	call os_string_add	
	
	cmp edx, 0
	je near .skipremainder
	
	mov bx, .remainder_msg
	call os_string_add

	push ax
	mov eax, edx
	call os_32int_to_string

	mov bx, ax
	pop ax
	call os_string_add

	mov bx, .msg_end
	call os_string_add
	
.skipremainder:	
	clr bx
	clr cx
	clr dx
	call os_dialog_box
	
	jmp start
	
.divide_error:	
	mov ax, .divide_msg
	clr bx
	clr cx
	clr dx
	call os_dialog_box
	jmp start

.draw_background:
	mov ax, .title_msg
	mov bx, .footer_msg
	mov cx, 256
	call os_draw_background
	mov ch, 0
	ret
	
.exit:
	ret
	
	.title_msg			db 'MichalOS Calculator', 0
	.footer_msg			db 0

	.options_name		db 'Choose an operation...', 0
	.options			db '+ (Add),- (Subtract),* (Multiply),/ (Divide),^ (Power),', 0FBh, ' (Square root),3', 0FBh, ' (Cube root)', 0
	; 251 = root symbol

	.result_msg			db 'Answer: ', 0
	.remainder_msg		db ' (remainder: ', 0
	.msg_end			db ')', 0
	
	.root_msg1			db 'Answer: between ', 0
	.root_msg2			db ' and ', 0
	
	.divide_msg			db 'Cannot divide by zero!', 0
	
	.number_msg			db 'Enter a number:', 0
	.firstnumber_msg	db 'Enter the first number:', 0
	.secondnumber_msg	db 'Enter the second number:', 0
	
	.resultint			dd 2048 + 0
	.remainderint		dd 2048 + 4
	.firstnumber		dd 2048 + 8
	.secondnumber		dd 2048 + 12
	
	.firstnumberstring	equ 4096
	.secondnumberstring	equ 6144
	.resultmsg			equ 8192
	
	
; ------------------------------------------------------------------
