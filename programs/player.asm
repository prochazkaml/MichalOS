; ------------------------------------------------------------------
; MichalOS Music Player
; ------------------------------------------------------------------

	%INCLUDE "michalos.inc"
	%INCLUDE "notelist.txt"

start:
	cmp byte [terminalflag], 1		; Were we passed a filename and ended the playback?
	je .exit
	
	call os_speaker_off
	call .draw_background

	cmp byte [0E0h], 0				; Were we passed a filename?
	je .no_file_chosen
	
	mov byte [terminalflag], 1
	
	mov ax, 0E0h
	
	call os_string_uppercase
	
	jmp .file_chosen
	
.no_file_chosen:
	mov ax, .choice
	mov bx, .choice_msg1
	mov cx, .choice_msg2
	mov si, .callback
	call os_list_dialog_tooltip
	
	jc .exit
	
	cmp ax, 1
	je piano
	
	cmp ax, 2
	je polypiano
	
	cmp ax, 3
	je .play_file
	
	cmp ax, 4
	je .play_duo
	
	cmp ax, 5
	je .exit
	
.play_file:
	mov byte [0087h], 1
	mov bx, .extension_number
	call os_file_selector		; Get filename
	mov byte [0087h], 0
	jc start

.file_chosen:
	mov bx, ax			; Save filename for now

	mov di, ax

	call os_string_length
	add di, ax			; DI now points to last char in filename

	dec di
	dec di
	dec di				; ...and now to first char of extension!
	
	pusha
	mov si, .mmf_extension
	mov cx, 3
	rep cmpsb			; Does the extension contain 'MMF'?
	je .valid_mmf_extension		; Skip ahead if so
	popa
	
	pusha
	mov si, .dro_extension
	mov cx, 3
	rep cmpsb
	je start_dro
	popa
	
	pusha
	mov si, .drz_extension
	mov cx, 3
	rep cmpsb
	je start_drz
	popa
	
	pusha
	mov si, .rad_extension
	mov cx, 3
	rep cmpsb
	je start_rad
	popa
					; Otherwise show error dialog
	clr dx		; One button for dialog box
	mov ax, .err_string
	mov bx, .err_string2
	clr cx
	call os_dialog_box

	cmp byte [terminalflag], 1				; Were we passed a filename and errored?
	je .exit
	
	jmp .play_file			; And retry
	
.valid_mmf_extension:
	popa

	call start_mono_mmf
	jmp start
	
.play_duo:
	mov ax, .duo_msg1
	clr bx
	clr cx
	clr dx
	call os_dialog_box

	call .draw_background
	
	mov byte [0087h], 1
	mov bx, .poly_mmf_num
	call os_file_selector		; Get the first filename
	mov byte [0087h], 0
	jc start

	mov cx, buffer
	call os_load_file
	
	mov ax, .duo_msg2
	clr bx
	clr cx
	clr dx
	call os_dialog_box

	call .draw_background

	mov byte [0087h], 1
	mov bx, .poly_mmf_num
	call os_file_selector		; Get the second filename
	mov byte [0087h], 0
	jc start

	mov cx, buffer2
	call os_load_file

	call start_poly_mmf
	jmp start
	
.draw_background:
	pusha
	mov ax, .title_msg
	mov bx, .footer_msg
	mov cx, 256
	call os_draw_background
	popa
	ret

.draw_clear_background:
	pusha
	mov ax, .title_msg
	mov bx, .footer_msg_2
	movzx cx, byte [57000]
	call os_draw_background
	popa
	ret
	
.draw_player_background:
	pusha
	mov ax, .title_msg
	mov bx, .footer_msg_3
	mov cx, 256
	call os_draw_background
	popa
	ret
	
.exit:
	mov byte [0E0h], 0

	call os_clear_screen
	ret
		
	jmp .play_file

.callback:
	dec ax
	shl ax, 1
	mov bx, ax
	
	mov si, [.listitems + bx]
	mov dl, 42
	call os_print_string_box
	ret
	
	.choice_msg1		db 'Choose an option...', 0
	.choice_msg2		db 0
	.choice				db 'Monophonic piano (PC speaker),Polyphonic piano (Adlib),Play a file,Play duo (Adlib),Quit', 0
	
	.listitems			dw .listitem0, .listitem1, .listitem2, .listitem3, .listitem4

	.listitem0			db 'A 2', 0ACh, ' octave keyboard-controlled', 13, 10, \
						   'piano.', 13, 10, 10, \
						   'It will use the PC speaker for', 13, 10, \
						   'sound output, so only one note', 13, 10, \
						   'may be played at a time.', 0
						   
	.listitem1			db 'A 2', 0ACh, ' octave keyboard-controlled', 13, 10, \
						   'piano.', 13, 10, 10, \
						   'It will use an Adlib device for', 13, 10, \
						   'sound output, so up to 9 notes', 13, 10, \
						   'may be played at a time.', 13, 10, 10, \
						   'Tip: If your computer is too new to', 13, 10, \
						   'have an actual Adlib card, you may', 13, 10, \
						   'select PC speaker emulation in the', 13, 10, \
						   'Settings app:', 13, 10, 10, \
						   'Sound ', 1Ah, ' Set Adlib device driver.', 0
	
	.listitem2			db 'Play a compatible music file', 13, 10, \
						   'through the PC speaker or an Adlib', 13, 10, \
						   `device, based on the file's format.`, 13, 10, 10, \
						   'Compatible file formats:', 13, 10, \
						   '- MMF: MichalOS PCspk Music Format', 13, 10, \
						   '- DRO/DRZ: DOSBox Adlib capture', 13, 10, \
						   '- RAD: Reality Adlib Tracker', 0
	
	.listitem3			db 'Play 2 MMF (MichalOS PCspk Music', 13, 10, \
						   'Format) files at the same time', 13, 10, \
						   'through an Adlib device.', 0
	
	.listitem4			db 'Quit the application.', 0
	
	.duo_msg1			db 'Please select the first file.', 0
	.duo_msg2			db 'Please select the second file.', 0
	
	.title_msg			db 'MichalOS Music Player', 0
	.footer_msg			db 0
	.footer_msg_2		db '[Space] Mute all notes [Up/Down] Change octave', 0
	.footer_msg_3		db '[Space] Play/Pause [Escape] Stop', 0
	
	.octave				db 4
	
	.octavemsg			db 'Octave: ', 0
	
	.keydata1			db 2Ch, 2Dh, 2Eh, 2Fh, 30h, 31h, 32h, 33h, 34h, 35h
	.keydata2			db 1Fh, 20h, 22h, 23h, 24h, 26h, 27h
	.keydata3			db 10h, 11h, 12h, 13h, 14h, 15h, 16h, 17h, 18h, 19h, 1Ah, 1Bh
	.keydata4			db 03h, 04h, 06h, 07h, 08h, 0Ah, 0Bh, 0Dh, 00h
	
	.notedata1			dw C6, D6, E6, F6, G6, A6, B6, C7, D7, E7
	.notedata2			dw CS6, DS6, FS6, GS6, AS6, CS7, DS7
	.notedata3			dw C7, D7, E7, F7, G7, A7, B7, C8, D8, E8, F8, G8
	.notedata4			dw CS7, DS7, FS7, GS7, AS7, CS8, DS8, FS8
	
	.err_string			db 'Invalid file type!', 0
	.err_string2		db 'MMF, DRO 2.0 or RAD only!', 0
	
	.extension_number	db 4
	.mmf_extension		db 'MMF', 0
	.dro_extension		db 'DRO', 0
	.drz_extension		db 'DRZ', 0
	.rad_extension		db 'RAD', 0
	
	.poly_mmf_num		db 1
	.mmf_extension_2	db 'MMF', 0
	
	.adlib_msg1			db 'YM3812 not detected.', 0
	.adlib_msg2			db 'Do you want to continue?', 0
	
	.piano0 db 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 179, 13, 10
	.piano1 db 32, 179, 32, 32, 32, 83, 32, 32, 32, 68, 32, 32, 32, 179, 32, 32, 32, 71, 32, 32, 32, 72, 32, 32, 32, 74, 32, 32, 32, 179, 32, 32, 32, 50, 32, 32, 32, 51, 32, 32, 32, 179, 32, 32, 32, 53, 32, 32, 32, 54, 32, 32, 32, 55, 32, 32, 32, 179, 32, 32, 32, 57, 32, 32, 32, 48, 32, 32, 32, 179, 32, 32, 32, 61, 32, 32, 32, 179, 13, 10
	.piano2 db 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 179, 13, 10
	.piano3 db 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 219, 32, 32, 32, 179, 32, 32, 32, 219, 32, 32, 32, 179, 13, 10
	.piano4 db 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 32, 32, 32, 179, 13, 10
	.piano5 db 32, 179, 32, 90, 32, 179, 32, 88, 32, 179, 32, 67, 32, 179, 32, 86, 32, 179, 32, 66, 32, 179, 32, 78, 32, 179, 32, 77, 32, 179, 32, 81, 32, 179, 32, 87, 32, 179, 32, 69, 32, 179, 32, 82, 32, 179, 32, 84, 32, 179, 32, 89, 32, 179, 32, 85, 32, 179, 32, 73, 32, 179, 32, 79, 32, 179, 32, 80, 32, 179, 32, 91, 32, 179, 32, 93, 32, 179, 13, 10
	.piano6 db 32, 192, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 193, 196, 196, 196, 217, 0

	terminalflag		db 0
	
	%include "player/libs.asm"
	%include "player/dro.asm"
	%include "player/monommf.asm"
	%include "player/polymmf.asm"
	%include "player/rad.asm"
	%include "player/monopian.asm"
	%include "player/polypian.asm"

align 16
;test_module: incbin RAD_MODULE_NAME
buffer:
buffer2 equ buffer + 14000

; ------------------------------------------------------------------

