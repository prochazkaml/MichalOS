; ==================================================================
; MichalOS Shutdown handler
; ==================================================================

os_reboot:
	jmp 0FFFFh:0

os_shutdown:
	mov si, .sub_shutdown_data
	mov di, 100h
	call os_decompress_zx7
	jmp 100h

.sub_shutdown_data:
	incbin "sub_shutdown.zx7"

; ==================================================================
