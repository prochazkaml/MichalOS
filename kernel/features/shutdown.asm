; ==================================================================
; MichalOS Shutdown handler
; ==================================================================

os_reboot:
	jmp 0FFFFh:0

os_shutdown:
	mov si, .sub_shutdown_data
	jmp os_run_zx7_module

.sub_shutdown_data:
	incbin "sub_shutdown.zx7"

; ==================================================================
