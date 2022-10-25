; ------------------------------------------------------------------
; Space Inventors
; ------------------------------------------------------------------

	%INCLUDE "michalos.inc"

	jmp start
	
	; Global constants & variables
	
	color_palette		db 00000000b, 00100100b, 00010010b, 00110110b, 00001001b
	counter_table		db 10000000b, 11000000b, 11100000b, 11110000b, 11111000b, 11111100b, 11111110b
	screen_mapping		dw 3057, 817, 5297, 3050, 3064
	blanksprite			db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	character1			db 03h, 0Fh, 1Fh, 3Fh, 73h, 73h, 0FFh, 0FFh, 0FFh, 0EFh, 77h, 78h, 3Fh, 1Fh, 0Fh, 03h
	welcome_msg			db 'Welcome to Space Inventors!', 13, 10, 13, 10
	welcome_msg2		db 'Press Escape to quit the game', 13, 10
	welcome_msg3		db 'Press any other key to start!', 0
	gameover_msg		db 'GAME OVER!', 13, 10
	gameover_msg2		db 'Your final score is: ', 0
	gameover_msg3		db 'Press Enter to start again, or', 13, 10
	gameover_msg4		db 'press Escape to quit', 0
	play_area			equ 4000h
	current_piece		db 0
	current_score		dd 0
	game_begun			db 0
	
start:
	mov ax, 000Dh
	int 10h

	; Reprogram the timer to 60 Hz
	
	mov cx, 19886					; 60 Hz
	call os_set_timer_speed
	
	; Reprogram the color palette
	
	mov ax, 1000h
	clr bl
	mov si, color_palette
	
.palette_loop:
	mov bh, [si]
	int 10h
	
	inc si
	inc bl
	cmp bl, 5
	jl .palette_loop

	; Set up plane masking
	
	mov dx, 3CEh
	mov ax, 0005h
	out dx, ax

game_title_screen:

	; TO-DO: Display a NICE title screen

	clr dx
	call os_move_cursor
	mov si, welcome_msg
	mov bl, 15
	call os_format_string
	
	call os_wait_for_key
	
	cmp al, 27
	je game_over.exit
	
game_start:
	call clear_screen

	mov dword [current_score], 0	; Clear all the variables
	mov byte [current_piece], 0
	mov byte [game_begun], 0
	
	mov di, play_area
	mov cx, 10						; Use WORDs to make it faster
	clr ax
	rep stosw
	
.main_loop:
	call check_for_creature

	mov byte [game_begun], 1
	
	call get_random_piece
	call update_screen				; Draw it all out

	cmp byte [sfx], 1
	jne .no_sfx

	mov ax, 523
	mov cx, 2
	call os_speaker_note_length

.no_sfx:
	call clear_counter				; Clear the current counter
	clr cx							; Reset the time counter
	
.key_detect:
	hlt								; Wait for ~1/60th of a second

	call draw_counter
	
	call os_check_for_key

	cmp ah, 72						; Up arrow key
	je .go_up
	
	cmp ah, 75						; Left arrow key
	je .go_left
	
	cmp ah, 77						; Right arrow key
	je .go_right
	
	cmp ah, 80						; Down arrow key
	je .go_down
	
	cmp al, 27						; Escape key
	je game_over

	mov eax, [current_score]
	mov ebx, 10000
	clr edx
	div ebx
	
	inc ax
	add cx, ax
	
	cmp cx, 320
	jge game_over
	
	jmp .key_detect					; If none from the above were pressed, check again
	
.go_up:
	pusha
	mov cx, 4						; Go up
	jmp .go_somewhere
	
.go_left:
	pusha
	mov cx, 12						; Go left
	jmp .go_somewhere
	
.go_right:
	pusha
	mov cx, 16						; Go right
	jmp .go_somewhere
	
.go_down:
	pusha
	mov cx, 8						; Go down
	jmp .go_somewhere
	
.go_somewhere:
	movzx bx, byte [current_piece]
	mov al, [play_area + bx]		; Get the current piece
	push bx
	add bx, cx						; Go to the previously selected destination
	cmp byte [play_area + bx], 0	; Is the destination already occupied?
	je .good
	
	cmp dword [current_score], 1000
	jl .small_punish
	
	sub dword [current_score], 1000	; That's a punishment!
	jmp .end_punish
	
.small_punish:
	mov dword [current_score], 0

.end_punish:
	call update_screen
	
	mov ax, 523 / 8
	mov cx, 10
	call os_speaker_note_length

	pop bx
	popa
	jmp .key_detect
	
.good:
	mov [play_area + bx], al
	pop bx
	
	mov byte [play_area + bx], 0	; Clear the current piece
	
	add dword [current_score], 10	; Add some score

	mov byte [sfx], 1

	popa
	jmp .main_loop
	
	sfx			db 0

game_over:
	mov byte [sfx], 1

	call clear_screen
	
	clr dx
	call os_move_cursor
	
	mov si, gameover_msg			; Print the game over screen
	mov bl, 15
	call os_format_string
	
	mov eax, [current_score]		; Get the current score...
	call os_print_32int
	call os_print_newline
	
	mov si, gameover_msg3
	call os_format_string
	
.loop:
	call os_wait_for_key
	cmp al, 13
	je game_start					; We want to play again!
	cmp al, 27
	jne .loop						; Do we want to quit?
	
.exit:
	; Reprogram the timer back to 18.2 Hz
	
	clr cx							; 18.2 Hz
	call os_set_timer_speed
	
	ret

; Clear the entire screen.
; IN: nothing
; OUT: nothing
clear_screen:
	pusha
	push es
	
	mov dx, 3C4h					; Select all EGA color planes
	mov ax, 0F02h
	out dx, ax
	
	clr di
	mov ax, 0A000h
	mov es, ax

	clr ax							; Use WORDs to make it faster
	mov cx, 4000
	rep stosw
	
	pop es
	popa
	ret

; Clears the time counter.
; IN: nothing
; OUT: nothing
clear_counter:
	pusha
	push es
	
	mov dx, 3C4h					; Select all EGA color planes
	mov ax, 0F02h
	out dx, ax
	
	mov di, 7600					; 7600: X=0, Y=190
	mov ax, 0A000h
	mov es, ax

	clr ax							; Use WORDs to make it faster
	mov cx, 200
	rep stosw
	
	pop es
	popa
	ret

; Draw the cime counter.
; IN: CX = value (0-320)
; OUT: nothing
draw_counter:
	pusha
	push es
	mov dx, 3C4h					; Select all EGA color planes
	mov ax, 0F02h
	out dx, ax
	
	mov ax, cx
	clr dx
	mov bx, 8
	div bx							; How many 8-bit cells can we fill?
	
	push dx							; Save the remainder for later
	mov bx, 0A000h
	mov es, bx
	mov di, 7600					; 7600: X=0, Y=190
	
	mov cx, ax
	test cx, cx						; Is the counter value < 8?
	jz .draw_remainder
	
	mov al, 255
	
.full_loop:
	clr bx
	call .draw_cell

	inc di
	dec cx
	jnz .full_loop
	
.draw_remainder:
	pop bx
	
	test bx, bx
	jz .exit
	
	dec bx
	
	mov al, [counter_table + bx]
	clr bx
	call .draw_cell
	
.exit:
	pop es
	popa
	ret
	
.draw_cell:							; AL = bit field (???), EBX = 0, EDI = pointer to VRAM
	push di
	add di, bx
	stosb
	pop di
	
;	mov [es:di + bx], al
	add bx, 40
	cmp bx, 400
	jne .draw_cell
	ret
	
; Checks if there is any fully assembled creature.
; IN: nothing
; OUT: nothing
check_for_creature:
	pusha
	mov bx, 4	; Point it to the 1st slot after the 'current piece box'

.loop:
	cmp byte [play_area + 0 + bx], 0
	je .empty_space
	cmp byte [play_area + 1 + bx], 0
	je .empty_space
	cmp byte [play_area + 2 + bx], 0
	je .empty_space
	cmp byte [play_area + 3 + bx], 0
	je .empty_space

	add dword [current_score], 490			; We've got an assembled creature, add 500 to the score (10 was already given)
	
	mov ax, 220

	mov cl, [play_area + 0 + bx]			; Is the creature assembled with the same pieces?
	cmp cl, [play_area + 1 + bx]
	jne .not_the_same
	
	cmp cl, [play_area + 2 + bx]
	jne .not_the_same
	
	cmp cl, [play_area + 3 + bx]
	jne .not_the_same
	
	mov ax, 330
	add dword [current_score], 1000			; Add some more to motivate the player
	
.not_the_same:
	mov cx, 4

	mov dword [play_area + bx], 0F0F0F0Fh	; Perform a little animation
	call update_screen

	call os_speaker_note_length

	mov dword [play_area + bx], 0
	call update_screen

	shl ax, 1
	call os_speaker_note_length

	mov dword [play_area + bx], 0F0F0F0Fh	; (make all 4 squares blink)
	call update_screen

	shl ax, 1
	call os_speaker_note_length

	mov byte [sfx], 0

	mov dword [play_area + bx], 0			; Clear the whole box (4 bytes = 1 dword)
	
.empty_space:
	add bx, 4
	cmp bx, 20								; Are we done with all the squares?
	jne .loop
	
	mov di, play_area
	clr bx
	clr al
	
.empty_loop:
	add al, [di + bx]
	inc bx
	cmp bx, 20
	jne .empty_loop
	
	test al, al								; Are all the squares empty?
	jnz .no_bonus
	
	cmp byte [game_begun], 0				; Are we at the start of the game (on start, the board is empty)
	je .no_bonus
	
	add dword [current_score], 10000		; That's a lottery prize!
	
.no_bonus:
	popa
	ret


; Gets a random piece, and places it randomly (if the slot is empty, of course).
; IN: nothing
; OUT: nothing
get_random_piece:
	pusha

	mov ax, 1						; Get a random number from 1...
	mov bx, 4						; ...to 4
	call os_get_random				; Pick a random color
	push cx
	
.try_again:
	clr ax
	mov bx, 3
	call os_get_random				; Pick a random slot (0-3)
	mov bx, cx
	
.check_for_emptiness:				; Check all the areas, if there's an empty space for the tile
	cmp byte [play_area + 4 + bx], 0
	je .empty_space
	cmp byte [play_area + 8 + bx], 0
	je .empty_space
	cmp byte [play_area + 12 + bx], 0
	je .empty_space
	cmp byte [play_area + 16 + bx], 0
	je .empty_space
	
	jmp .try_again
	
.empty_space:
	pop ax
	mov [play_area + bx], al		; Put the random piece in the middle
	mov [current_piece], bl			; Store the current piece
	popa
	ret

; Updates the screen.
; IN: nothing
; OUT: nothing
update_screen:
	pushad
	
	clr dx
	call os_move_cursor
	
	mov ax, 0920h
	mov16 bx, 15, 0
	mov cx, 20
	int 10h							; First, clear the score counter
	
	mov eax, [current_score]
	call os_32int_to_string
	mov si, ax
	mov bl, 15
	call os_format_string			; Print out the new score
	
	clr cl							; Counter

.loop:
	mov si, character1				; Index into the sprite data
	clr ch

	mov bx, cx
	shr bx, 2						; Divide BX by 4 to get the correct VRAM pointer
	shl bx, 1						; ...and multiply it by 2 (it's a word)
	mov di, [screen_mapping + bx]
	
	test cl, 02h					; Does CX & 02h = 02h?
	je .no_bottom					; In human-readable words: Is it the bottom half of the sprite?
	
	add si, 8						; Point to the second half of the sprite
	add di, 960						; Point to the correct VRAM location
	
.no_bottom:
	test cl, 01h					; Does CX & 01h = 01h?
	je .no_flip						; Again, in human terms: Is it the right side of the sprite?
	
	mov ch, 1						; Flip the sprite
	add di, 3						; Render the sprite on the right
	
.no_flip:
	movzx bx, cl

	pusha
	mov si, blanksprite
	mov ah, 15
	call draw_sprite				; First, clear the sprite
	popa
	
	mov ah, [play_area + bx]		; Get the color

	call draw_sprite				; Draw the sprite
	
	inc cl
	cmp cl, 20						; Are we done?
	jne .loop
	
	popad
	ret
	
; Draws an 8x8 sprite on the screen.
; IN: SI = pointer to the sprite, DI = pointer into the screen memory, CH = 1 to mirror it, AH = color
; OUT: nothing

draw_sprite:
	pushad
	push es
	
	mov dx, 3C4h					; Select an EGA color plane
	mov al, 02h
	out dx, ax						; Color is in AH already

	mov ax, 0A000h
	mov es, ax
	
	mov cl, 8
		
.loop:
	lodsb							; Get a byte from the sprite data
	
	call extend_byte				; Expand it
	
	push cx
	mov cx, 3						; Line draw counter
	
.draw_loop:
	push ebx
	ror ebx, 16
	mov [es:di], bl					; Draw the 1st byte
	pop ebx
	
	push ebx
	ror ebx, 8
	mov [es:di + 1], bl				; Draw the 2nd byte
	pop ebx
	
	mov [es:di + 2], bl				; Draw the 3rd byte
	
	add di, 40						; Point to the next line
	loop .draw_loop
	
	pop cx
	
	dec cl							; Are we done with the sprite?
	jnz .loop

	pop es
	popad
	ret
	
; Extends the byte 3 times (eg. 101b = 111000111b)
; IN: AL = 8-bit byte, CH = 1 to flip the sprite horizontally
; OUT: EBX = 24-bit word
extend_byte:
	pushad
	clr ah							; We only need the low 8 bits
	clr cl							; Counter
	clr ebx							; Temporary integer
	
.decode_loop:
	push bx
	clr dx							; Not to interfere with DIV
	mov bx, 2						; We don't have any registers left...
	div bx
	pop bx
	
	test ch, ch
	jz .no_flip
	
	add bx, dx
	rol ebx, 1
	add bx, dx
	rol ebx, 1
	add bx, dx
	rol ebx, 1
	jmp .flip_end
	
.no_flip:
	add bx, dx
	ror ebx, 1
	add bx, dx
	ror ebx, 1
	add bx, dx
	ror ebx, 1
	
.flip_end:
	inc cl
	cmp cl, 8
	jne .decode_loop
	
	test ch, ch
	jz .big_ror
	
	ror ebx, 1
	jmp .routine_end
	
.big_ror:
	ror ebx, 8
	
.routine_end:
	mov [.tmp_word], ebx
	popad
	mov ebx, [.tmp_word]
	ret

	.tmp_word		dd 0
