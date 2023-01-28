; ==================================================================
; MichalOS Low-level disk driver
; ==================================================================

; --------------------------------------------------------------------------
; os_int13 -- Perform a BIOS 13h call with extra precautions
; IN/OUT: depends on function in AH, high 16 bits of all 32-bit registers preserved, carry set if error

os_int13:
	call .roll			; Some BIOSes destroy (16..31) of all 32 bit regs
	pusha
	clr ax				; Some BIOSes need the upper word of EAX = 0
	call .roll

	stc					; Some BIOSes do not set CF on error
	int 13h

	call .roll
	popa
	call .roll
	ret

.roll:
	pushf
	ror eax, 16
	ror ebx, 16
	ror ecx, 16
	ror edx, 16
	ror esi, 16
	ror edi, 16
	ror ebp, 16
	popf
	ret

; --------------------------------------------------------------------------
; os_int13_protected -- Performs a BIOS 13h call with all regs preserved
; IN: depends on function in AH
; OUT: None, registers preserved

os_int13_protected:
	pushad
	push ds
	push es
	call os_int13
	pop es
	pop ds
	popad
	ret

; --------------------------------------------------------------------------
; os_int13_failsafe -- Performs a BIOS 13h call 3 times in case of error
; IN/OUT: depends on function in AH (DL must be drive number), high 16 bits of all 32-bit registers preserved, carry set if error

os_int13_failsafe:
	pusha
	call os_int13				; Attempt #1
	jnc .ok
	popa

	call os_disk_reset_device	; Reset device and try again

	pusha
	call os_int13				; Attempt #2
	jnc .ok
	popa

	call os_disk_reset_device	; Reset device and try again

	pusha
	call os_int13				; Third time's a charm!

.ok:
	add sp, 16					; Restore stack without popping regs
	ret

; --------------------------------------------------------------------------
; os_int13_failsafe_protected -- Performs a BIOS 13h call with all regs preserved 3 times in case of error
; IN: depends on function in AH
; OUT: None, registers preserved

os_int13_failsafe_protected:
	pushad
	push ds
	push es
	call os_int13_failsafe
	pop es
	pop ds
	popad
	ret

; --------------------------------------------------------------------------
; os_disk_get_param_table -- Get the pointer to the disk param table
; IN: DL = drive number, OUT: DS:DI = pointer to param table

os_disk_get_param_table:
	mov ds, [cs:driversgmt]		; Segment 0

	movzx di, dl				; Each entry is 8 bytes wide
	shl di, 3

	add di, DISK_PARAMS			; Add the offset to the table
	ret

; --------------------------------------------------------------------------
; os_disk_reset_device -- Resets a given disk device
; IN: DL = drive number, OUT: carry set if error

os_disk_reset_device:
	pusha
	push ds
	call os_disk_get_param_table

	cmp byte [di + 1], 0
	je .reset_chs

.exit:
	pop ds
	popa
	ret

.reset_chs:
	mov ah, 0				; Perform a reset via legacy CHS
	call os_int13_protected
	jmp .exit				; Pass along the carry flag

; --------------------------------------------------------------------------
; os_disk_detect_drive -- Read basic information about the drive if a change occured
; IN: DL = drive number, OUT: carry set if error
;
; Disk info format:
;   00 (byte) = drive number
;   01 (byte) = mode (0 = CHS, 1 = LBA)
;   If CHS:
;     02-03 (word) = number of sectors per track
;     04-05 (word) = number of tracks
;     06 (byte) = number of heads
;   If LBA:
;     02-05 (dword) = number of sectors
;     06-07 (word) = bytes per sector

os_disk_detect_drive:
	pusha
	push ds

	call os_disk_get_param_table
	
	mov [di], dl			; Start populating the table

;	cmp dl, 80h				; Check if we're dealing with a floppy or fixed disk
;	jae .fixed_disk			; TODO: CHECK IF LBA ACTUALLY WORKS! (now disabled)

	; Floppy (drive number 00-7F)

.get_chs:
	cmp byte [di + 1], 0FFh	; Has this drive been initialized at all?
	je .skip_chs_check

	mov ah, 16h				; Check if a disk change occured, if it did, do not re-load the params
	call os_int13_protected
	jnc .end

.skip_chs_check:
	push di
	push es
	mov ah, 8				; Get drive parameters
	call os_int13_failsafe
	pop es
	pop di

	jc .end

	mov byte [di + 1], 0	; Mark as CHS drive

	mov ax, cx				; Number of sectors per track
	and ax, 3Fh
	mov [di + 2], ax

	and cl, 11000000b		; Number of tracks
	shr cl, 6
	rol cx, 8
	inc cx
	mov [di + 4], cx

	mov dl, dh				; Number of heads
	inc dl					; Head numbers start at 0 - add 1 for total
	mov [di + 6], dl

	clc

.end:
	pop ds
	popa
	ret

.fixed_disk:
	; Fixed disk (drive number 80-FF)

	mov ah, 41h				; Detect LBA support
	mov bx, 55AAh
	call os_int13

	jc .get_chs				; Fall back to CHS if not supported

	cmp byte [di + 1], 0FFh	; Has this drive been initialized at all?
	je .skip_lba_check

	mov ah, 49h				; Check if a disk change occured, if it did, do not re-load the params
	call os_int13_protected
	jnc .end

.skip_lba_check:
	cmp bx, 0AA55h			; Fall back to CHS if signature invalid
	jne .get_chs

	push es

	push ds					; DS = BIOS drive param table, ES = our struct
	pop es

	mov al, 7Fh				; Allocate a buffer in the disk cache
	call os_disk_cache_alloc_sector

	mov ah, 48h				; Get drive parameters (extended)
	call os_int13_failsafe

	jc .lba_end

	inc di

	mov al, 1				; Mark as LBA drive
	stosb

	movsd					; Number of sectors

	lodsw					; Check if the drive is under 2^32 sectors
	test ax, ax
	jnz .lba_err

	lodsw
	test ax, ax
	jnz .lba_err

	movsw					; Bytes per sector

	clc

.lba_end:
	pop es

	pop ds
	popa
	ret

.lba_err:
	stc
	jmp .lba_end

; --------------------------------------------------------------------------
; os_disk_read_sector -- Read a single sector from disk
; IN: EAX = sector ID, ES:SI = 512 byte buffer, DL = drive number, OUT: carry set if error

os_disk_read_sector:
	pushad
	push ds
	call os_disk_detect_drive			; Detect drive change
	jc .err

	call os_disk_init_int13				; Prepare the params
	jc .err

;	call os_dump_registers

	call os_int13_failsafe_protected	; Read the sector
	jc .err

	clc

.err:
	pop ds
	popad
	ret

; --------------------------------------------------------------------------
; os_disk_read_multiple_sectors -- Read multiple sectors from disk
; IN: EAX = sector ID, CX = number of sectors, ES:SI = 512 byte buffer, DL = drive number, OUT: carry set if error

os_disk_read_multiple_sectors:
	pushad
	push es

.loop:
	call os_disk_read_sector	; Read a single sector
	jc .end

	inc eax						; Point to the next one

	mov bx, es					; Advance the memory pointer 512 bytes forward
	add bx, 32
	mov es, bx

	loop .loop

	clc

.end:
	pop es
	popad
	ret

; --------------------------------------------------------------------------
; os_disk_write_sector -- Write a single sector to disk
; IN: EAX = sector ID, ES:SI = 512 byte buffer, DL = drive number, OUT: carry set if error

os_disk_write_sector:
	pushad
	push ds
	call os_disk_detect_drive			; Detect drive change
	jc .err

	call os_disk_init_int13				; Prepare the params
	jc .err

	inc ah								; Select write operation (works for both CHS and LBA)

;	call os_dump_registers

	call os_int13_failsafe_protected	; Read the sector
	jc .err

	clc

.err:
	pop ds
	popad
	ret

; --------------------------------------------------------------------------
; os_disk_write_multiple_sectors -- Write multiple sectors to disk
; IN: EAX = sector ID, CX = number of sectors, ES:SI = 512 byte buffer, DL = drive number, OUT: carry set if error

os_disk_write_multiple_sectors:
	pushad
	push es

.loop:
	call os_disk_write_sector	; Write a single sector
	jc .end

	inc eax						; Point to the next one

	mov bx, es					; Advance the memory pointer 512 bytes forward
	add bx, 32
	mov es, bx

	loop .loop

	clc

.end:
	pop es
	popad
	ret

; --------------------------------------------------------------------------
; os_disk_init_int13 -- Converts a LBA value to the proper INT 13h params
; IN: EAX = sector ID, ES:SI = buffer pointer, DL = drive number
; OUT: carry set if error
;   If CHS:
;     ax = 0201h (CHS read - single sector)
;     ch/cl/dh = appropriate CHS params
;     dl = drive number
;     es:bx = pointer to buffer
;     destroyed DS, upper 16 bits of EAX, EBX
;   If LBA:
;     ax = 4200h (extended read)
;     dl = drive number
;     ds:si = pointer to populated disk packet

os_disk_init_int13:
	push di
	call os_disk_get_param_table

	cmp byte [di + 1], 0			; Does the disk use CHS addressing?
	je .init_chs

	cmp byte [di + 1], 1			; Does the disk use LBA?
	je .init_lba

.err:
	stc								; If neither, the drive is not initialized (which shouldn't happen) - bail out

.end:
	pop di
	ret

.init_chs:
	; LBA = (Track * NumberOfHeads + Head) * SectorsPerTrack + Sector - 1
	push edx

	clr edx
	movzx ebx, word [di + 2]		; Number of sectors per track
	div ebx							; EAX = (Track * NumberOfHeads + Head), (E)DX = Sector - 1 (max 63)

	inc dx							; DX = Sector
	mov cl, dl						; CL = Sector

	clr edx
	movzx ebx, byte [di + 6]		; Number of tracks
	div ebx							; (E)DX = Track, (E)AX = Head

	mov bx, dx
	pop edx

	mov dh, bl						; DH = Head
	mov ch, al						; CH = Track number (bits 0-7)

	shl ah, 6
	or cl, ah						; CL(6..7) = Track number (bits 8-9)

	mov ax, 0201h					; CHS read, sigle sector
	mov bx, si						; Output buffer pointer
	jmp .end

.init_lba:
	cmp word [di + 6], 512			; Check if the drive uses 512-byte sectors
	je .err							; If it does not, bail out

	push si
	mov si, .packet					; Initialize driver packet pointer

	push cs
	pop ds

	mov [si + 8], eax				; LBA address
	pop ax
	mov [si + 4], ax				; Buffer offset
	mov [si + 6], es				; Buffer segment

	jmp .end

.packet:
	db 10h		; Packet size
	db 0		; Reserved, should be zero
	dw 1		; Number of blocks
	dw 0		; Buffer offset
	dw 0		; Buffer segment
	dq 0		; LBA address
