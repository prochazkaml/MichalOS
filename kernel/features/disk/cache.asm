; ==================================================================
; MichalOS Disk cache driver
; ==================================================================

; --------------------------------------------------------------------------
; os_disk_cache_alloc_sector -- Allocates a free sector in the cache
; IN: DL = drive number, OUT: DS:SI = free 512 byte buffer

os_disk_cache_alloc_sector:
	; TODO
	ret

; --------------------------------------------------------------------------
; os_disk_cache_read_sector -- Read a single sector from cache or disk, if necessary
; IN: EAX = sector ID, ES:SI = 512 byte buffer, DL = drive number, OUT: carry set if error

os_disk_cache_read_sector:
	ret

; --------------------------------------------------------------------------
; os_disk_cache_write_sector -- Write a single sector to cache or flush disk, if necessary
; IN: EAX = sector ID, ES:SI = 512 byte buffer, DL = drive number, OUT: carry set if error

os_disk_cache_write_sector:
	ret
