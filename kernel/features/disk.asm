; ==================================================================
; MichalOS Disk access functions
; ==================================================================

; ------------------------------------------------------------------
; os_report_free_space -- Returns the amount of free space on disk
; IN: None
; OUT: AX = Number of sectors free

os_report_free_space:
	pusha
	mov word [.counter], 0
	mov word [.sectors_read], 0
	
	call int_read_fat				; Read the FAT into memory
	mov si, DISK_BUFFER
	
.loop:
	; 0 = nothing, 1 = 1st nibble, 2 = 2nd nibble, 3 = 3rd nibble, G = data we don't care about

	mov ax, [si]					; AX = 3333GGGG11112222
	mov bh, [si + 1]				; BX = GGGG111122223333
	mov bl, [si + 2]
	
	rol ax, 4						; AX = GGGG111122223333
	
	and ah, 0Fh						; AX = 0000111122223333
	and bh, 0Fh						; BX = 0000111122223333
		
	test ax, ax
	jnz .no_increment_1
	
	inc word [.counter]
	
.no_increment_1:
	test bx, bx
	jnz .no_increment_2
	
	inc word [.counter]
	
.no_increment_2:
	add si, 3						; Increment the pointer
	add word [.sectors_read], 2		; Increment the counter of sectors
	
	cmp word [.sectors_read], 2847	; Are we done? (33 of the sectors are the bootloader, FAT and root dir)
	jl .loop
	
	popa
	mov ax, [.counter]

	ret
	
	.counter		dw 0
	.sectors_read	dw 0

; ------------------------------------------------------------------
; os_get_file_list -- Generate comma-separated string of files on floppy
; IN/OUT: AX = location to store zero-terminated filename string

os_get_file_list:
	pusha

	mov byte [.num_entries], 0
	mov [.extension_list], bx
	
	call int_save_footer
	jc .no_msg

	mov si, .msg_load
	call os_print_string

.no_msg:
	mov word [.file_list_tmp], ax

	call int_read_root_dir
	jnc .show_dir_init		; No errors, continue

	mov ax, floppyreseterror
	call os_fatal_error
	
.show_dir_init:
	clr ax
	mov si, DISK_BUFFER		; Data reader from start of filenames

	mov word di, [.file_list_tmp]	; Name destination buffer


.start_entry:
	mov al, [si+11]			; File attributes for entry
	cmp al, 0Fh			; Windows marker, skip it
	je .skip

	test al, 08h			; Is this a directory entry or volume label?
	jnz .skip			; Yes, ignore it

	mov al, [si]
	cmp al, 229			; If we read 229 = deleted filename
	je .skip

	test al, al			; 1st byte = entry never used
	jz .done
	
	mov cx, 1			; Set char counter
	mov dx, si			; Beginning of possible entry

.testdirentry:
	inc si
	mov al, [si]			; Test for most unusable characters
	cmp al, ' '			; Windows sometimes puts 0 (UTF-8) or 0FFh
	jl .nxtdirentry
	cmp al, '~'
	ja .nxtdirentry

	inc cx
	cmp cx, 11			; Done 11 char filename?
	je .gotfilename
	jmp .testdirentry


.gotfilename:				; Got a filename that passes testing
	mov si, dx			; DX = where getting string
	xor cx, cx
	
.loopy:
	lodsb
	cmp al, ' '
	je .ignore_space
	stosb
	
.ignore_space:
	inc cx
	cmp cx, 8
	je .add_dot
	cmp cx, 11
	je .done_copy
	jmp .loopy

.add_dot:
	mov byte [es:di], '.'
	inc di
	jmp .loopy

.done_copy:
	mov byte [es:di], ','		; Use comma to separate filenames
	inc di
	inc byte [.num_entries]
	
.nxtdirentry:
	mov si, dx			; Start of entry, pretend to skip to next

.skip:
	add si, 32			; Shift to next 32 bytes (next filename)
	jmp .start_entry


.done:
	cmp byte [.num_entries], 0
	je .no_dec
	
	dec di

.no_dec:
	mov byte [es:di], 0		; Zero-terminate string (gets rid of final comma)

	call int_restore_footer

	popa

	ret

	.num_entries		db 0
	.extension_list		dw 0
	.file_list_tmp		dw 0
	.msg_load			db 'Reading directory contents...', 0
	floppyreseterror	db 'Floppy reset fail', 0
	
; ------------------------------------------------------------------
; os_load_file -- Load a file into RAM
; IN: AX = location of filename, ES:CX = location in RAM to load file
; OUT: BX = file size (in bytes), carry set if file not found

os_load_file:
	pushad
	push es
	mov [.old_segment], es

	movs es, cs
	
	call os_string_uppercase

	call int_save_footer			; Message display routine
	jc .no_msg

	mov si, .msg_load
	call os_print_string
	mov si, ax
	call os_print_string

.no_msg:
	call int_filename_convert

	mov [.filename_loc], ax		; Store filename location
	mov [.load_position], cx	; And where to load the file!

	call int_read_root_dir
	jc .root_problem

.search_root_dir:
	mov cx, 224		; Search all entries in root dir
	mov bx, -32			; Begin searching at offset 0 in root dir

.next_root_entry:
	add bx, 32			; Bump searched entries by 1 (offset + 32 bytes)
	mov di, DISK_BUFFER		; Point root dir at next entry
	add di, bx

	mov al, [di]			; First character of name

	test al, al			; Last file name already checked?
	jz .root_problem

	cmp al, 229			; Was this file deleted?
	je .next_root_entry		; If yes, skip it

	mov al, [di+11]			; Get the attribute byte

	cmp al, 0Fh			; Is this a special Windows entry?
	je .next_root_entry

	test al, 18h			; Is this a directory entry or volume label?
	jnz .next_root_entry

	mov byte [di+11], 0		; Add a terminator to directory name entry

	mov ax, di			; Convert root buffer name to upper case
	call os_string_uppercase

	mov si, [.filename_loc]		; DS:SI = location of filename to load

	call os_string_compare		; Current entry same as requested?
	jc .found_file_to_load

	loop .next_root_entry

.root_problem:
	pop es
	popad
	clr bx			; If file not found or major disk error,

	stc				; return with size = 0 and carry set
	ret


.found_file_to_load:			; Now fetch cluster and load FAT into RAM
	mov eax, [di+28]			; Store file size to return to calling routine
	mov [.file_size], eax

	test eax, eax			; If the file size is zero, don't bother trying
	jz .end				; to read more clusters

	mov ax, [di+26]			; Now fetch cluster and load FAT into RAM
	mov word [.cluster], ax

	call int_read_fat
	jc .root_problem

.load_file_sector:
	movzx eax, word [.cluster]		; Convert sector to logical
	add eax, 31

	mov si, [.load_position]
	mov es, [.old_segment]
	mov dl, [bootdev]

	call os_disk_read_sector

	movs es, cs
	
	jc .root_problem


.calculate_next_cluster:
	mov ax, [.cluster]
	mov bx, 3
	mul bx
	mov bx, 2
	div bx				; DX = [CLUSTER] mod 2
	mov si, DISK_BUFFER		; AX = word in FAT for the 12 bits
	add si, ax
	mov ax, word [ds:si]

	test dx, dx			; If DX = 0 [CLUSTER] = even, if DX = 1 then odd
	jz .even			; If [CLUSTER] = even, drop last 4 bits of word
					; with next cluster; if odd, drop first 4 bits

.odd:
	shr ax, 4			; Shift out first 4 bits (belong to another entry)
	jmp .calculate_cluster_cont	; Onto next sector!

.even:
	and ax, 0FFFh			; Mask out top (last) 4 bits

.calculate_cluster_cont:
	mov word [.cluster], ax		; Store cluster

	cmp ax, 0FF8h
	jge .end

	add word [.old_segment], 512 / 16
	jmp .load_file_sector		; Onto next sector!


.end:
	pop es
	popad

	mov ebx, [.file_size]		; Get file size to pass back in BX
	call int_restore_footer

	clc				; Carry clear = good load
	ret


	.bootd					db 0 		; Boot device number
	.cluster				dw 0 		; Cluster of the file we want to load
	.pointer				dw 0 		; Pointer into DISK_BUFFER, for loading 'file2load'

	.filename_loc			dw 0		; Temporary store of filename location
	.load_position			dw 0		; Where we'll load the file
	.file_size				dd 0		; Size of the file

	.old_segment			dw 0
	
	.msg_load				db 'Loading ', 0
	
; --------------------------------------------------------------------------
; os_write_file -- Save (max 64K) file to disk
; IN: AX = filename, ES:BX = data location, CX = bytes to write
; OUT: Carry clear if OK, set if failure

os_write_file:
	pushad
	
	mov [.old_segment], es
	
	movs es, cs
		
	call int_save_footer			; Message display routine
	jc .no_msg

	mov si, .msg_save
	call os_print_string
	mov si, ax
	call os_print_string

.no_msg:
	mov si, ax
	call os_string_length
	test ax, ax
	jz .failure
	mov ax, si

	call os_string_uppercase

	call int_filename_convert	; Make filename FAT12-style
	jc .failure

	mov word [.filesize], cx
	mov word [.location], bx
	mov word [.filename], ax

	call os_file_exists		; Don't overwrite a file if it exists!
	jnc .failure


	; First, zero out the .free_clusters list from any previous execution
	pusha

	mov di, .free_clusters
	mov cx, 128
.clean_free_loop:
	mov word [di], 0
	inc di
	inc di
	loop .clean_free_loop

	popa


	; Next, we need to calculate now many 512 byte clusters are required

	mov ax, cx
	xor dx, dx
	mov bx, 512			; Divide file size by 512 to get clusters needed
	div bx
	cmp dx, 0
	jg .add_a_bit			; If there's a remainder, we need another cluster
	jmp .carry_on

.add_a_bit:
	add ax, 1
.carry_on:

	mov word [.clusters_needed], ax

	mov word ax, [.filename]	; Get filename back

	call os_create_file		; Create empty root dir entry for this file
	jc .failure		; If we can't write to the media, jump out

	mov word bx, [.filesize]
	test bx, bx
	jz .finished

	call int_read_fat		; Get FAT copy into RAM
	mov si, DISK_BUFFER + 3		; And point SI at it (skipping first two clusters)

	mov bx, 2			; Current cluster counter
	mov word cx, [.clusters_needed]
	xor dx, dx			; Offset in .free_clusters list

.find_free_cluster:
	lodsw				; Get a word
	and ax, 0FFFh			; Mask out for even
	jz .found_free_even		; Free entry?

.more_odd:
	inc bx				; If not, bump our counter
	dec si				; 'lodsw' moved on two chars; we only want to move on one

	lodsw				; Get word
	shr ax, 4			; Shift for odd
	or ax, ax			; Free entry?
	jz .found_free_odd

.more_even:
	inc bx				; If not, keep going
	jmp .find_free_cluster


.found_free_even:
	push si
	mov si, .free_clusters		; Store cluster
	add si, dx
	mov word [si], bx
	pop si

	dec cx				; Got all the clusters we need?
	jcxz .finished_list

	inc dx				; Next word in our list
	inc dx
	jmp .more_odd

.found_free_odd:
	push si
	mov si, .free_clusters		; Store cluster
	add si, dx
	mov word [si], bx
	pop si

	dec cx
	jcxz .finished_list

	inc dx				; Next word in our list
	inc dx
	jmp .more_even



.finished_list:

	; Now the .free_clusters table contains a series of numbers (words)
	; that correspond to free clusters on the disk; the next job is to
	; create a cluster chain in the FAT for our file

	xor cx, cx			; .free_clusters offset counter
	mov word [.count], 1		; General cluster counter

.chain_loop:
	mov word ax, [.count]		; Is this the last cluster?
	cmp word ax, [.clusters_needed]
	je .last_cluster

	mov di, .free_clusters

	add di, cx
	mov word bx, [di]		; Get cluster

	mov ax, bx			; Find out if it's an odd or even cluster
	xor dx, dx
	mov bx, 3
	mul bx
	mov bx, 2
	div bx				; DX = [.cluster] mod 2
	mov si, DISK_BUFFER
	add si, ax			; AX = word in FAT for the 12 bit entry
	mov ax, word [ds:si]

	or dx, dx			; If DX = 0, [.cluster] = even; if DX = 1 then odd
	jz .even

.odd:
	and ax, 000Fh			; Zero out bits we want to use
	mov di, .free_clusters
	add di, cx			; Get offset in .free_clusters
	mov word bx, [di+2]		; Get number of NEXT cluster
	shl bx, 4			; And convert it into right format for FAT
	add ax, bx

	mov word [ds:si], ax		; Store cluster data back in FAT copy in RAM

	inc word [.count]
	inc cx				; Move on a word in .free_clusters
	inc cx

	jmp .chain_loop

.even:
	and ax, 0F000h			; Zero out bits we want to use
	mov di, .free_clusters
	add di, cx			; Get offset in .free_clusters
	mov word bx, [di+2]		; Get number of NEXT free cluster

	add ax, bx

	mov word [ds:si], ax		; Store cluster data back in FAT copy in RAM

	inc word [.count]
	inc cx				; Move on a word in .free_clusters
	inc cx

	jmp .chain_loop



.last_cluster:
	mov di, .free_clusters
	add di, cx
	mov word bx, [di]		; Get cluster

	mov ax, bx

	xor dx, dx
	mov bx, 3
	mul bx
	mov bx, 2
	div bx				; DX = [.cluster] mod 2
	mov si, DISK_BUFFER
	add si, ax			; AX = word in FAT for the 12 bit entry
	mov ax, word [ds:si]

	or dx, dx			; If DX = 0, [.cluster] = even; if DX = 1 then odd
	jz .even_last

.odd_last:
	and ax, 000Fh			; Set relevant parts to FF8h (last cluster in file)
	add ax, 0FF80h
	jmp .finito

.even_last:
	and ax, 0F000h			; Same as above, but for an even cluster
	add ax, 0FF8h


.finito:
	mov word [ds:si], ax

	call int_write_fat		; Save our FAT back to disk


	; Now it's time to save the sectors to disk!

	xor cx, cx

.save_loop:
	mov di, .free_clusters
	add di, cx
	movzx eax, word [di]

	test eax, eax
	jz .write_root_entry

	pushad

	add eax, 31
	mov si, [.location]
	mov es, [.old_segment]
	mov dl, [bootdev]
	
	call os_disk_write_sector

	movs es, cs
		
	popad

	add word [.location], 512
	inc cx
	inc cx
	jmp .save_loop


.write_root_entry:

	; Now it's time to head back to the root directory, find our
	; entry and update it with the cluster in use and file size

	call int_read_root_dir

	mov word ax, [.filename]
	call int_get_root_entry

	mov word ax, [.free_clusters]	; Get first free cluster

	mov word [di+26], ax		; Save cluster location into root dir entry

	mov word cx, [.filesize]
	mov word [di+28], cx

	mov byte [di+30], 0		; File size
	mov byte [di+31], 0

	call int_write_root_dir

.finished:
	call int_restore_footer
	popad
	mov es, [.old_segment]

	clc
	ret

.failure:
	call int_restore_footer
	popad
	mov es, [.old_segment]

	stc				; Couldn't write!
	ret


	.filesize				dw 0
	.cluster				dw 0
	.count					dw 0
	.location				dw 0

	.clusters_needed		dw 0

	.filename				dw 0

	.free_clusters			equ DISK_BUFFER + 7936 ; THIS IS A KLUDGE!!!

	.old_segment			dw 0

	.msg_save				db 'Saving ', 0
	
; --------------------------------------------------------------------------
; os_file_exists -- Check for presence of file on the floppy
; IN: AX = filename location; OUT: carry clear if found, set if not

os_file_exists:
	call os_string_uppercase

	push ax
	call os_string_length
	test ax, ax
	jz .failure
	pop ax

	push ax
	call int_read_root_dir

	mov di, DISK_BUFFER

	call int_filename_convert	; Make FAT12-style filename
	jc .failure

	call int_get_root_entry	; Set or clear carry flag
	pop ax

	ret

.failure:
	pop ax

	stc
	ret


; --------------------------------------------------------------------------
; os_create_file -- Creates a new 0-byte file on the floppy disk
; IN: AX = location of filename
; OUT: None, registers preserved

os_create_file:
	clc

	call os_string_uppercase
	call int_filename_convert	; Make FAT12-style filename
	pusha

	push ax				; Save filename for now

	call os_file_exists		; Does the file already exist?
	jnc .exists_error


	; Root dir already read into DISK_BUFFER by os_file_exists

	mov di, DISK_BUFFER		; So point DI at it!

	mov cx, 224			; Cycle through root dir entries
.next_entry:
	mov byte al, [di]
	test al, al			; Is this a free entry?
	jz .found_free_entry
	cmp al, 0E5h			; Is this a free entry?
	je .found_free_entry
	add di, 32			; If not, go onto next entry
	loop .next_entry
	
	mov ax, .err_msg		; Is the root directory full?
	call os_fatal_error

.exists_error:				; We also get here if above loop finds nothing
	pop ax				; Get filename back

	jmp .failure

.found_free_entry:
	pop si				; Get filename back
	mov cx, 11
	rep movsb			; And copy it into RAM copy of root dir (in DI)

	; Get the time information
	
	pusha
	mov ah, 2
	call os_int_1Ah

	mov al, ch			; Hours
	call os_bcd_to_int
	mov bx, ax
	shl bx, 6
	
	mov al, cl			; Minutes
	call os_bcd_to_int
	or bx, ax
	shl bx, 5
	
	shr dh, 1			; Seconds (they're stored as "doubleseconds")
	mov al, dh
	call os_bcd_to_int
	or bx, ax
	
	mov [.creation_time], bx
	mov [.write_time], bx

	; Get date information
	
	mov ah, 4
	call os_int_1Ah

	push dx
	mov al, ch			; Century
	call os_bcd_to_int
	mov bx, 100
	mul bx
	mov bx, ax
	
	mov al, cl			; Years
	call os_bcd_to_int
	add bx, ax
	
	sub bx, 1980		; Years are stored as "years past 1980"
	
	shl bx, 4
	pop dx
	
	mov al, dh			; Months
	call os_bcd_to_int
	or bx, ax
	shl bx, 5
	
	mov al, dl			; Days
	call os_bcd_to_int
	or bx, ax
	
	mov [.creation_date], bx
	mov [.write_date], bx
	popa
	
	mov si, .table		; Copy over all the attributes
	mov cx, 21
	rep movsb
	
	call int_write_root_dir
	jc .failure

	popa

	clc				; Clear carry for success
	ret

.failure:
	popa

	stc
	ret

;	.table			db 0, 0, 0, 0C6h, 07Eh, 0, 0, 0, 0, 0, 0, 0C6h, 07Eh, 0, 0, 0, 0, 0, 0, 0, 0 
	.table:
		.atttribute		db 0
		.reserved		times 2 db 0
		.creation_time	dw 0
		.creation_date	dw 0
		.reserved2		times 4 db 0
		.write_time		dw 0
		.write_date		dw 0
		.reserved3		times 6 db 0
	.err_msg		db 'Not enough space in directory', 0

; --------------------------------------------------------------------------
; os_remove_file -- Deletes the specified file from the filesystem
; IN: AX = location of filename to remove

os_remove_file:
	pusha
	call os_string_uppercase
	call int_filename_convert	; Make filename FAT12-style
	push ax				; Save filename

	clc

	call int_read_root_dir		; Get root dir into DISK_BUFFER

	mov di, DISK_BUFFER		; Point DI to root dir

	pop ax				; Get chosen filename back

	call int_get_root_entry	; Entry will be returned in DI
	jc .failure			; If entry can't be found


	mov ax, word [es:di+26]		; Get first cluster number from the dir entry
	mov word [.cluster], ax		; And save it

	mov byte [di], 0E5h		; Mark directory entry (first byte of filename) as empty

	inc di

	xor cx, cx			; Set rest of data in root dir entry to zeros
.clean_loop:
	mov byte [di], 0
	inc di
	inc cx
	cmp cx, 31			; 32-byte entries, minus E5h byte we marked before
	jl .clean_loop

	call int_write_root_dir	; Save back the root directory from RAM


	call int_read_fat		; Now FAT is in DISK_BUFFER
	mov di, DISK_BUFFER		; And DI points to it


.more_clusters:
	mov word ax, [.cluster]		; Get cluster contents

	test ax, ax			; If it's zero, this was an empty file
	jz .nothing_to_do

	mov bx, 3			; Determine if cluster is odd or even number
	mul bx
	mov bx, 2
	div bx				; DX = [first_cluster] mod 2
	mov si, DISK_BUFFER		; AX = word in FAT for the 12 bits
	add si, ax
	mov ax, word [ds:si]

	or dx, dx			; If DX = 0 [.cluster] = even, if DX = 1 then odd

	jz .even			; If [.cluster] = even, drop last 4 bits of word
					; with next cluster; if odd, drop first 4 bits
.odd:
	push ax
	and ax, 000Fh			; Set cluster data to zero in FAT in RAM
	mov word [ds:si], ax
	pop ax

	shr ax, 4			; Shift out first 4 bits (they belong to another entry)
	jmp .calculate_cluster_cont	; Onto next sector!

.even:
	push ax
	and ax, 0F000h			; Set cluster data to zero in FAT in RAM
	mov word [ds:si], ax
	pop ax

	and ax, 0FFFh			; Mask out top (last) 4 bits (they belong to another entry)

.calculate_cluster_cont:
	mov word [.cluster], ax		; Store cluster

	cmp ax, 0FF8h			; Final cluster marker?
	jae .end

	jmp .more_clusters		; If not, grab more

.end:
	call int_write_fat
	jc .failure

.nothing_to_do:
	popa

	clc
	ret

.failure:
	popa

	stc
	ret


	.cluster dw 0


; --------------------------------------------------------------------------
; os_rename_file -- Change the name of a file on the disk
; IN: AX = filename to change, BX = new filename (zero-terminated strings)
; OUT: carry set on error

os_rename_file:
	push bx
	push ax

	clc

	call int_read_root_dir		; Get root dir into DISK_BUFFER

	mov di, DISK_BUFFER		; Point DI to root dir

	pop ax				; Get chosen filename back

	call os_string_uppercase
	call int_filename_convert
	jc .fail_read
	
	call int_get_root_entry	; Entry will be returned in DI
	jc .fail_read			; Quit out if file not found

	pop bx				; Get new filename string (originally passed in BX)

	mov ax, bx

	call os_string_uppercase
	call int_filename_convert
	jc .fail_write
	
	mov si, ax

	mov cx, 11			; Copy new filename string into root dir entry in DISK_BUFFER
	rep movsb

	call int_write_root_dir	; Save root dir to disk
	jc .fail_write


	clc
	ret

.fail_read:
	pop ax

	stc
	ret

.fail_write:

	stc
	ret


; --------------------------------------------------------------------------
; os_get_file_size -- Get file size information for specified file
; IN: AX = filename; OUT: EBX = file size in bytes (up to 4GB)
; or carry set if file not found

os_get_file_size:
	pusha

	call os_string_uppercase
	call int_filename_convert

	clc

	push ax

	call int_read_root_dir
	jc .failure

	pop ax

	mov di, DISK_BUFFER

	call int_get_root_entry
	jc .failure

	mov ebx, [di+28]

	mov [.tmp], ebx

	popa

	mov ebx, [.tmp]


	ret

.failure:
	popa
	stc

	ret


	.tmp	dd 0

; --------------------------------------------------------------------------
; os_get_file_datetime -- Get file write time/date information for specified file
; IN: AX = filename; OUT: BX = time of creation (HHHHHMMMMMMSSSSS), CX = date of creation (YYYYYYYMMMMDDDDD)
; or carry set if file not found

os_get_file_datetime:
	pusha

	call os_string_uppercase
	call int_filename_convert

	clc

	push ax

	call int_read_root_dir
	jc .failure

	pop ax

	mov di, DISK_BUFFER

	call int_get_root_entry
	jc .failure

	mov ax, [di+22]
	mov bx, [di+24]

	mov [.tmp], ax
	mov [.tmp + 2], bx

	popa

	mov bx, [.tmp]
	mov cx, [.tmp + 2]


	ret

.failure:
	popa
	stc

	ret


	.tmp	dd 0


; ==================================================================
; INTERNAL OS ROUTINES -- Not accessible to user programs

; ------------------------------------------------------------------
; int_filename_deconvert -- Change 'TEST    BIN' into 'TEST.BIN' as per FAT12
; IN: DS:AX = filename string
; OUT: ES:AX = location of converted string

int_filename_deconvert:
	pusha
	movs es, cs

	mov si, ax
	mov di, int_filename

	cmp byte [si], ' '		; Special case - filename starts with a space
	je .error

	mov cx, 0

.basename_loop:
	lodsb

	inc cx

	cmp al, ' '				; If there's a space, skip forward
	je .basename_skip

	call int_filename_convert.check_valid_char
	jc .error

	stosb

	cmp cx, 8
	jne .basename_loop

.basename_finish:
	cmp byte [si], ' '		; Check if the extension is empty
	je .extension_skip

	mov al, '.'				; Otherwise add the period and parse the extension
	stosb

.extension_loop:
	lodsb

	inc cx

	cmp al, ' '
	je .extension_skip

	call int_filename_convert.check_valid_char
	jc .error

	stosb

	cmp cx, 11
	jne .extension_loop

.extension_finish:
	mov al, 0				; Zero-terminate the string
	stosb

	jmp int_filename_convert.exit

.basename_skip:
	lodsb

	cmp al, ' '
	jne .error

	inc cx
	cmp cx, 8
	jl .basename_skip

	jmp .basename_finish

.extension_skip:
	lodsb

	cmp al, ' '
	jne .error

	inc cx
	cmp cx, 11
	jl .extension_skip

	jmp .extension_finish

.error:
	popa
	mov ax, .invalid
	ret

	.invalid		db "[NAME ERROR]", 0

; ------------------------------------------------------------------
; int_filename_convert -- Change 'TEST.BIN' into 'TEST    BIN' as per FAT12
; IN: DS:AX = filename string
; OUT: ES:AX = location of converted string

int_filename_convert:
	pusha
	movs es, cs

	mov si, ax
	mov di, int_filename

	clr cx

.copy_loop:
	lodsb

	cmp al, '.'
	je .extension_found

	cmp al, 0
	je .finish

	; Check against allowed special characters

	call .check_valid_char
	jc .copy_loop

	stosb

	inc cx				; Go to the next character
	cmp cx, 8			; If the basename's full, go to the extension
	jge .extension_found

	jmp .copy_loop

.extension_found:
	cmp byte [si], 0	; Special case: filename is a single period
	je .do_unnamed

	test cx, cx			; Special case: filename starts with period
	jz .copy_loop

	cmp cx, 8			; If the basename was less than 8 chars, pad it out
	jl .basename_pad

	cmp al, '.'			; If the basename is larger than 8 chars, skip forward
	jne .basename_skip

.extension_loop:
	lodsb

	cmp al, 0
	je .finish

	; Check against allowed special characters

	call .check_valid_char
	jc .extension_loop

	stosb

	inc cx				; Go to the next character
	cmp cx, 11			; If the extension's full, finish
	jge .finish

	jmp .extension_loop

.basename_pad:
	mov al, ' '

.basename_pad_loop:
	stosb
	inc cx
	cmp cx, 8
	jl .basename_pad_loop

	jmp .extension_loop

.basename_skip:
	lodsb

	cmp al, '.'
	je .extension_loop

	cmp al, 0
	jne .basename_skip

;	jmp .finish			; Not necessary, can just fall through

.finish:
	test cx, cx			; Special case if the file name was empty or full of gibberish
	jz .do_unnamed

	cmp cx, 11
	jl .extension_pad

.exit:
	popa
	mov ax, int_filename
	ret

.extension_pad:
	mov al, ' '

.extension_pad_loop:
	stosb
	inc cx
	cmp cx, 11
	jl .extension_pad_loop

	jmp .exit

.do_unnamed:
	popa
	mov ax, .unnamed
	ret

.check_valid_char:
	; Is the character within ASCII range?

	cmp al, 0x21
	jb .check_valid_char_fail

	cmp al, 0x7E
	ja .check_valid_char_pass

	; There are certain blocked characters, so mask those off as well
	; (https://www.win.tue.nl/~aeb/linux/fs/fat/fat-1.html)

	pusha
	push ds
	movs ds, cs
	mov bl, al
	mov si, .banlist

.check_valid_char_loop:
	lodsb
	cmp al, bl
	je .check_valid_char_fail_pop

	cmp al, 0
	jne .check_valid_char_loop
	pop ds
	popa
	
.check_valid_char_pass:
	clc
	ret

.check_valid_char_fail_pop:
	pop ds
	popa

.check_valid_char_fail:
	stc
	ret

	.banlist		db 0x22, "*+,./:;<=>?[\]|", 0
	.unnamed		db "UNNAMED    ", 0

	int_filename	times 13 db 0

; --------------------------------------------------------------------------
; int_get_root_entry -- Search RAM copy of root dir for file entry
; IN: DS:AX = filename; OUT: ES:DI = location in DISK_BUFFER of root dir entry,
; or carry set if file not found

int_get_root_entry:
	pusha
	movs es, cs

	mov si, ax

	mov cx, 224			; Search all (224) entries
	mov di, DISK_BUFFER	; Point to next root dir entry

.to_next_root_entry:
	pusha
	mov cx, 11
	rep cmpsb
	popa
	je .found_file			; Pointer DI will be at offset 11, if file found

	add di, 32			; Bump searched entries by 1 (32 bytes/entry)
	loop .to_next_root_entry

	popa
	stc				; Set carry if entry not found
	ret

.found_file:
	mov word [.tmp], di		; Restore all registers except for DI
	popa
	mov word di, [.tmp]
	clc
	ret

	.tmp		dw 0


; --------------------------------------------------------------------------
; int_read_fat -- Read FAT entry from floppy into DISK_BUFFER
; IN: None
; OUT: carry set if failure

int_read_fat:
	pushad
	push es
	
	movs es, cs
	mov eax, 1
	mov cx, 9
	mov si, DISK_BUFFER
	call os_get_boot_disk
	call os_disk_read_multiple_sectors		; Read sectors, error status in CF

	pop es
	popad
	ret


; --------------------------------------------------------------------------
; int_write_fat -- Save FAT contents from DISK_BUFFER in RAM to disk
; IN: FAT in DISK_BUFFER; OUT: carry set if failure

int_write_fat:
	pushad
	push es
	
	movs es, cs
	mov eax, 1
	mov cx, 9
	mov si, DISK_BUFFER
	call os_get_boot_disk
	call os_disk_write_multiple_sectors		; Write sectors, error status in CF

	pop es
	popad
	ret


; --------------------------------------------------------------------------
; int_read_root_dir -- Get the root directory contents
; IN: None
; OUT: root directory contents in DISK_BUFFER, carry set if error

int_read_root_dir:
	pushad
	push es
	
	movs es, cs
	mov eax, 19
	mov cx, 14
	mov si, DISK_BUFFER
	call os_get_boot_disk
	call os_disk_read_multiple_sectors		; Read sectors, error status in CF

	pop es
	popad
	ret


; --------------------------------------------------------------------------
; int_write_root_dir -- Write root directory contents from DISK_BUFFER to disk
; IN: root dir copy in DISK_BUFFER; OUT: carry set if error

int_write_root_dir:
	pushad
	push es
	
	movs es, cs
	mov eax, 19
	mov cx, 14
	mov si, DISK_BUFFER
	call os_get_boot_disk
	call os_disk_write_multiple_sectors		; Write sectors, error status in CF

	pop es
	popad
	ret


; --------------------------------------------------------------------------
; os_get_boot_disk -- Returns the boot disk number.
; IN: None
; OUT: DL = boot disk number for use in INT 13h calls

os_get_boot_disk:
	mov dl, [cs:bootdev]
	ret
	
	bootdev db 0			; Boot device number

; ==================================================================
