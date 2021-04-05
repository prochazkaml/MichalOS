; Decompresses Einar Saukas' ZX7 compressed stream data in 16-bit real mode.
; ZX7 format and original Z80 decompressor by Einar Saukas.
; Original Z80 to 8086 conversion, and size-optimized version, by Peter Ferrie.
; Speed-optimized code by Peter Ferrie and Jim Leonard.
; 20160308
;
; The source for the conversion was the original "default" Z80 decompression
; code provided by Einar.  Further size optimization and unrolling were
; independently performed specifically for the 8086.
; Source is formatted for Borland Turbo Assembler IDEAL mode and NEAR calls,
; however it should be very easy to port to other assemblers if necessary.
;
; Input:
;   Call "dzx7_size" with:
;   DS:SI - Location of source compressed data
;   ES:DI - Location to put decompressed output

;==========================================================================
;dzx7_size assembles to 71 bytes.  It is the smallest routine and, for most
;material, the same speed as the original dzx7_standard conversion.
;==========================================================================

os_decompress_zx7:
        mov     al, 80h
        xor     cx, cx
        mov     bp, @@dzx7si_next_bit
        cld
@@dzx7si_copy_byte_loop:
        movsb                           ; copy literal byte
@@dzx7si_main_loop:
        call    bp
        jnc     @@dzx7si_copy_byte_loop ; next bit indicates either
                                        ; literal or sequence

; determine number of bits used for length (Elias gamma coding)
        xor     bx, bx
@@dzx7si_len_size_loop:
        inc     bx
        call    bp
        jnc     @@dzx7si_len_size_loop
        db      80h                     ; mask call
; determine length
@@dzx7si_len_value_loop:
        call    bp
@@dzx7si_len_value_skip:
        adc     cx, cx
        jb      @@dzx7si_next_bit_ret   ; check end marker
        dec     bx
        jnz     @@dzx7si_len_value_loop
        inc     cx                      ; adjust length

; determine offset
        mov     bl, [si]                ; load offset flag (1 bit) +
                                        ; offset value (7 bits)
        inc     si
        stc
        adc     bl, bl
        jnc     @@dzx7si_offset_end     ; if offset flag is set, load
                                        ; 4 extra bits
        mov     bh, 10h                 ; bit marker to load 4 bits
@@dzx7si_rld_next_bit:
        call    bp
        adc     bh, bh                  ; insert next bit into D
        jnc     @@dzx7si_rld_next_bit   ; repeat 4 times, until bit
                                        ; marker is out
        inc     bh                      ; add 128 to DE
@@dzx7si_offset_end:
        shr     bx, 1                   ; insert fourth bit into E

; copy previous sequence
        push    si
        mov     si, di
        sbb     si, bx                  ; destination = destination - offset - 1

        es     rep movsb

        pop     si                      ; restore source address
                                        ; (compressed data)
        jmp     @@dzx7si_main_loop
@@dzx7si_next_bit:
        add     al, al                  ; check next bit
        jnz     @@dzx7si_next_bit_ret   ; no more bits left?
        lodsb                           ; load another group of 8 bits
        adc     al, al
@@dzx7si_next_bit_ret:
        ret
