	%include "michalos.inc"
	
start:
	finit				; Initialize the FPU
	
	fstcw [tmpword]
	or byte [tmpword + 1], 1100b	; Disable rounding
	fldcw [tmpword]
	
	fldpi				; ST0 = Pi
	call .print_float
	fdecstp
	fldz				; ST0 = Pi
	call .print_float
	fdecstp
	fld1				; ST0 = Pi
	call .print_float
	fdecstp
	fldlg2				; ST0 = Pi
	call .print_float
	fdecstp
	fldln2				; ST0 = Pi
	call .print_float
	fdecstp
	
	call os_wait_for_key
	ret
	
.print_float:
	fst qword [backup]	; Remember the test value for later
		
	; Get the digits before the decimal point

	mov di, buffer + 299
	std					; The digits will be backwards
	
	mov cx, 300
	
.loop:
	fst qword [tmp]		; ST0 = Pi

	fild word [mul10]	; ST0 = 10, ST1 = Pi
	fld qword [tmp]		; ST0 = Pi, ST1 = 10, ST2 = Pi
	fprem				; ST0 = Pi % 10, ST1 = 10, ST2 = Pi
	
	fistp word [tmpword]; ST0 = 10, ST1 = Pi
	fstp qword [tmp]	; ST0 = Pi
	
	fidiv word [mul10]	; ST0 = Pi / 10
	
	mov ax, [tmpword]
	stosb
	
	loop .loop
	
	; And now after the decimal point
	
	mov di, buffer + 300
	cld

	fstp qword [tmp]
	fld qword [backup]
	
	mov cx, 300
	
.loop2:
	fimul word [mul10]
	
	fst qword [tmp]

	fild word [mul10]
	fld qword [tmp]
	fprem
	
	fistp word [tmpword]
	fstp qword [tmp]
	
	mov ax, [tmpword]
	stosb
	
	loop .loop2
	
	; And now, print the digits
	mov si, buffer
	mov cx, 600
	
	test byte [backup + 7], 80h		; Negative?
	jz .prefixloop
	
	mov al, '-'
	call os_putchar
	
	; First, skip all of the prefix zeroes
	
.prefixloop:
	lodsb
	cmp al, 0
	jne .print
	
	loop .prefixloop
	
	; No digits were found, so it's zero

.print:
	push cx
	
	; Print the first digit
	
	add al, '0'
	call os_putchar	

	mov al, '.'
	call os_putchar
	
	mov cx, 14		; Print the next 14 digits
	
.print_loop:
	lodsb
	
	add al, '0'
	call os_putchar	

	loop .print_loop
	
	mov al, 'e'
	call os_putchar
	
	pop cx
	sub cx, 301
	mov ax, cx
	call os_sint_to_string
	mov si, ax
	call os_print_string
	
.exit:
	call os_print_newline
	ret
	
	tmp dq 0.0
	backup dq 0.0
	tmpword dw 0
	mul10 dw 10
	
buffer:
