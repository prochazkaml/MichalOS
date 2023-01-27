; ==================================================================
; MichalOS bootloader
; ==================================================================

	BITS 16

	%macro clr 1
		xor %1, %1
	%endmacro

	%macro mov16 3
		mov %1, (%2 + %3 * 256)
	%endmacro

	jmp short bootloader_start	; Jump past disk description section
	nop				; Pad out before disk description

; ------------------------------------------------------------------
; Disk description table, to make it a valid floppy
; Note: some of these values are hard-coded in the source!
; Values are those used by IBM for 1.44 MB, 3.5" diskette

OEMLabel			db "MICHALOS"		; Disk label
BytesPerSector		dw 512				; Bytes per sector
SectorsPerCluster	db 1				; Sectors per cluster
ReservedForBoot		dw 1				; Reserved sectors for boot record
NumberOfFats		db 2				; Number of copies of the FAT
RootDirEntries		dw 224				; Number of entries in root dir
										; (224 * 32 = 7168 = 14 sectors to read)
LogicalSectors		dw 2880				; Number of logical sectors
MediumByte			db 0F0h				; Medium descriptor byte
SectorsPerFat		dw 9				; Sectors per FAT
SectorsPerTrack		dw 18				; Sectors per track (36/cylinder)
Sides				dw 2				; Number of sides/heads
HiddenSectors		dd 0				; Number of hidden sectors
LargeSectors		dd 0				; Number of LBA sectors
DriveNo				dw 0				; Drive No: 0
Signature			db 41				; Drive signature: 41 for floppy
VolumeID			dd 00000000h		; Volume ID: any number
VolumeLabel			db "MICHALOS   "	; Volume Label: any 11 chars
FileSystem			db "FAT12   "		; File system type: don't change!

; ------------------------------------------------------------------
; Main bootloader code

bootloader_start:
	cld						; The default direction for string operations
							; will be 'up' - incrementing address in RAM

	mov ax, 07C0h			; Set data segment to where we're loaded
	mov ds, ax

	mov ax, 0360h			; Move the bootloader to the start of memory
	mov es, ax
	
	clr si
	clr di

	mov cx, 512
	rep movsb
	
	jmp 0360h:entrypoint
	
entrypoint:
	mov ds, ax

	cli				; Disable interrupts while changing stack
	mov ss, ax
	mov sp, 7FFEh	; Set stack just below the kernel
	sti				; Restore interrupts

	mov si, startmsg
	call print_string

	; NOTE: A few early BIOSes are reported to improperly set DL

	mov [bootdev], dl		; Save boot device number
	mov ah, 8			; Get drive parameters
	int 13h
	jc fatal_disk_error
	and cx, 3Fh			; Maximum sector number
	mov [SectorsPerTrack], cx	; Sector numbers start at 1
	movzx dx, dh			; Maximum head number
	add dx, 1			; Head numbers start at 0 - add 1 for total
	mov [Sides], dx
	
	clr eax				; Needed for some older BIOSes

; First, we need to load the root directory from the disk. Technical details:
; Start of root = ReservedForBoot + NumberOfFats * SectorsPerFat = logical 19
; Number of root = RootDirEntries * 32 bytes/entry / 512 bytes/sector = 14
; Start of user data = (start of root) + (number of root) = logical 33

floppy_ok:				; Ready to read first block of data
	mov bx, ds
	mov es, bx

	mov ax, 19			; Root dir starts at logical sector 19
	call l2hts

read_root_dir:
	mov16 ax, 14, 2		; Params for int 13h: read 14 floppy sectors
	stc				; A few BIOSes do not set properly on error
	int 13h				; Read sectors using BIOS

	jnc search_dir			; If read went OK, skip ahead
	call reset_floppy		; Otherwise, reset floppy controller and try again
	jnc read_root_dir		; Floppy reset OK?

	jmp reboot			; If not, fatal double error

search_dir:
	mov di, buffer		; Root dir is now in [buffer]

	mov cx, [RootDirEntries]	; Search all (224) entries
	clr ax				; Searching at offset 0

next_root_entry:
	pusha
	mov si, kern_filename		; Start searching for kernel filename
	mov cx, 11
	rep cmpsb
	popa
	je found_file_to_load		; Pointer DI will be at offset 11

	add di, 32			; Bump searched entries by 1 (32 bytes per entry)

	loop next_root_entry

	mov si, file_not_found		; If kernel is not found, bail out
	jmp reboot

found_file_to_load:			; Fetch cluster and load FAT into RAM
	mov ax, [di+26]		; Offset 26, contains 1st cluster
	mov [cluster], ax

	mov ax, 1			; Sector 1 = first sector of first FAT
	call l2hts

read_fat:
	mov16 ax, 9, 2		; int 13h params: read 9 (FAT) sectors
	stc
	int 13h				; Read sectors using the BIOS

	jnc load_file_sector	; If read went OK, skip ahead
	call reset_floppy		; Otherwise, reset floppy controller and try again
	jnc read_fat			; Floppy reset OK?

; ******************************************************************
fatal_disk_error:
; ******************************************************************
	mov si, disk_error		; If not, print error message and reboot
	jmp reboot			; Fatal double error

; Now we must load the FAT from the disk. Here's how we find out where it starts:
; FAT cluster 0 = media descriptor = 0F0h
; FAT cluster 1 = filler cluster = 0FFh
; Cluster start = ((cluster number) - 2) * SectorsPerCluster + (start of user)
;               = (cluster number) + 31

load_file_sector:
	mov ax, [cluster]		; Convert sector to logical
	add ax, 31

	call l2hts			; Make appropriate params for int 13h

	mov bx, [pointer]	; Set buffer past what we've already read

	mov16 ax, 1, 2		; int 13h read single sector
	stc
	int 13h

	mov si, point
	call print_string
	
	jnc calculate_next_cluster	; If there's no error...

	call reset_floppy		; Otherwise, reset floppy and retry
	jmp load_file_sector

	; In the FAT, cluster values are stored in 12 bits, so we have to
	; do a bit of maths to work out whether we're dealing with a byte
	; and 4 bits of the next byte -- or the last 4 bits of one byte
	; and then the subsequent byte!

calculate_next_cluster:
	mov ax, [cluster]
	imul ax, 3

	shr ax, 1			; CF = 1 if odd cluster

	pushf
	mov si, buffer
	add si, ax			; AX = word in FAT for the 12 bit entry
	lodsw
	popf

	jnc even			; If [cluster] is even, drop last 4 bits of word
						; with next cluster; if odd, drop first 4 bits

odd:
	shr ax, 4			; Shift out first 4 bits (they belong to another entry)
	jmp short next_cluster_cont

even:
	and ax, 0FFFh			; Mask out final 4 bits

next_cluster_cont:
	mov [cluster], ax		; Store cluster

	cmp ax, 0FF8h			; FF8h = end of file marker in FAT12
	jae end

	add word [pointer], 512		; Increase buffer pointer 1 sector length
	jmp load_file_sector

end:					; We've got the file to load!
	mov si, boot_complete
	call print_string
	
	mov dl, [bootdev]		; Provide kernel with boot device info

	jmp 8000h			; Jump to entry point of loaded kernel!

; ------------------------------------------------------------------
; BOOTLOADER SUBROUTINES

reboot:
	call print_string
	mov si, reboot_msg
	call print_string

	clr ax
	int 16h				; Wait for keystroke
	jmp 0FFFFh:0		; Reboot

print_string:				; Output string in SI to screen
	pusha

	mov ah, 0Eh			; int 10h teletype function

.repeat:
	lodsb				; Get char from string
	test al, al
	jz .done
	int 10h				; Otherwise, print it
	jmp .repeat

.done:
	popa
	ret

reset_floppy:		; IN: [bootdev] = boot device; OUT: carry set on error
	pusha
	clr ax
	mov dl, [bootdev]
	stc
	int 13h
	popa
	ret

l2hts:			; Calculate head, track and sector settings for int 13h
			; IN: logical sector in AX, OUT: correct registers for int 13h
	push ax

	mov bx, ax			; Save logical sector

	clr dx				; First the sector
	div word [SectorsPerTrack]
	add dl, 01h			; Physical sectors start at 1
	mov cl, dl			; Sectors belong in CL for int 13h
	mov ax, bx

	clr dx				; Now calculate the head
	div word [SectorsPerTrack]
	clr dx
	div word [Sides]
	mov dh, dl			; Head/side
	mov ch, al			; Track

	pop ax
	
	mov bx, buffer		; ES:BX points to our buffer

	mov dl, [bootdev]		; Set correct device
	
	ret

; ------------------------------------------------------------------
; STRINGS AND VARIABLES

	kern_filename	db "KERNEL  SYS"	; MichalOS Kernel

	disk_error		db " - disk error", 0
	file_not_found	db " - not found", 0
	boot_complete	db " OK", 0
	reboot_msg		db 13, 10, "Press any key to reboot" ; Carries over to the next string
	point			db ".", 0

	startmsg		db "Loading MichalOS ", VERMAJ, ".", VERMIN, " kernel" ; Termination not needed, as 1st byte of pointer will be always 0 on startup

	bootdev		equ VolumeID		; Boot device number
	cluster		equ VolumeID + 1	; Cluster of the file we want to load
	pointer		dw 8000h 			; Pointer into Buffer, for loading kernel

; ------------------------------------------------------------------
; END OF BOOT SECTOR AND BUFFER START

	times 510-($-$$) db 0	; Pad remainder of boot sector with zeros
	dw 0AA55h		; Boot signature (DO NOT CHANGE!)

buffer:				; Disk buffer begins (8k)


; ==================================================================

