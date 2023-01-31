; ------------------------------------------------------------------
; Include file for MichalOS program development - syscalls
; ------------------------------------------------------------------

; ==================================================================
; MichalOS Graphics functions
; Some graphics routines have been borrowed from TachyonOS
; ==================================================================

; ------------------------------------------------------------------
; os_init_graphics_mode -- Initializes graphics mode.
; IN/OUT: None, registers preserved

os_init_graphics_mode equ 33020

; ------------------------------------------------------------------
; os_init_text_mode -- Deinitializes graphics mode.
; IN/OUT: None, registers preserved

os_init_text_mode equ 33095

; ------------------------------------------------------------------
; os_set_pixel -- Sets a pixel on the screen to a given value.
; IN: ES = destination memory segment, CX = X coordinate, AX = Y coordinate, BL = color
; OUT: None, registers preserved

os_set_pixel equ 33017

; ------------------------------------------------------------------
; os_draw_line -- Draws a line with the Bresenham's line algorithm.
; Translated from an implementation in C (http://www.edepot.com/linebresenham.html)
; IN: ES = destination memory segment, CX=X1, DX=Y1, SI=X2, DI=Y2, BL=colour
; OUT: None, registers preserved

os_draw_line equ 32999

; ------------------------------------------------------------------
; os_draw_rectangle -- Draws a rectangle.
; IN: ES = destination memory segment, CX=X1, DX=Y1, SI=X2, DI=Y2, BL=colour, CF = set if filled or clear if not
; OUT: None, registers preserved

os_draw_rectangle equ 33047

; ------------------------------------------------------------------
; os_draw_polygon -- Draws a freeform shape.
; IN: ES = destination memory segment, BH = number of points, BL = colour, SI = location of shape points data
; OUT: None, registers preserved
; DATA FORMAT: x1, y1, x2, y2, x3, y3, etc

os_draw_polygon equ 33002

; ------------------------------------------------------------------
; os_clear_graphics -- Clears the graphics screen with a given color.
; IN: ES = destination memory segment, BL = colour to set
; OUT: None, registers preserved

os_clear_graphics equ 33008

; ----------------------------------------
; os_draw_circle -- draw a circular shape
; IN: ES = destination memory segment, AL = colour, BX = radius, CX = middle X, DX = middle y
; OUT: None, registers preserved

os_draw_circle equ 33005

; ==================================================================
; MichalOS Text display output functions
; ==================================================================

; ------------------------------------------------------------------
; os_putchar -- Puts a character on the screen
; IN: AL = character
; OUT: None, registers preserved

os_putchar equ 32981

; ------------------------------------------------------------------
; os_put_chars -- Puts up to a set amount of characters on the screen
; IN: BL = terminator, DS:SI = location, CX = character count
; OUT: None, registers preserved

os_put_chars equ 32996

; ------------------------------------------------------------------
; os_print_string -- Displays text
; IN: DS:SI = message location (zero-terminated string)
; OUT: None, registers preserved

os_print_string equ 32771

; ------------------------------------------------------------------
; os_print_string_box -- Displays text inside a text-box.
; IN: DS:SI = message location (zero-terminated string), DL = left alignment
; OUT: None, registers preserved

os_print_string_box equ 32993

; ------------------------------------------------------------------
; os_format_string -- Displays colored text
; IN: DS:SI = message location (zero-terminated string), BL = text color
; OUT: None, registers preserved

os_format_string equ 32978

; ------------------------------------------------------------------
; os_clear_screen -- Clears the screen to background
; IN/OUT: None, registers preserved

os_clear_screen equ 32777

; ------------------------------------------------------------------
; os_move_cursor -- Moves cursor in text mode
; IN: DH, DL = row, column
; OUT: None, registers preserved

os_move_cursor equ 32774

; ------------------------------------------------------------------
; os_get_cursor_pos -- Return position of text cursor
; IN: None
; OUT: DH, DL = row, column

os_get_cursor_pos equ 32870

; ------------------------------------------------------------------
; os_show_cursor -- Turns on cursor in text mode
; IN/OUT: None, registers preserved

os_show_cursor equ 32903

; ------------------------------------------------------------------
; os_hide_cursor -- Turns off cursor in text mode
; IN/OUT: None, registers preserved

os_hide_cursor equ 32906

; ------------------------------------------------------------------
; os_draw_block -- Render block of specified colour
; IN: BL/DL/DH/SI/DI = colour/start X pos/start Y pos/width/finish Y pos
; OUT: None, registers preserved

os_draw_block equ 32945

; ------------------------------------------------------------------
; os_file_selector -- Show a file selection dialog
; IN: None
; OUT: AX = location of filename string (or carry set if Esc pressed)

os_file_selector equ 32855

; ------------------------------------------------------------------
; os_file_selector_filtered -- Show a file selection dialog only 
; with files mathing the filter
; IN: ES:BX = location of file extension list (0 if none)
; OUT: DS:AX = location of filename string (or carry set if Esc pressed)

os_file_selector_filtered equ 33122

; ------------------------------------------------------------------
; os_list_dialog_tooltip -- Show a dialog with a list of options and a tooltip.
; That means, when the user changes the selection, the application will be called back
; to change the tooltip's contents.
; IN: DS:AX = comma-separated list of strings to show (zero-terminated),
;     DS:BX = first help string, DS:CX = second help string
;     SI = key/display callback (see os_list_dialog_ex)
;     if AX = 0: DI = entry display callback, DX = number of entries
; OUT: AX = number (starts from 1) of entry selected; carry set if Esc pressed

os_list_dialog_tooltip equ 32912

; ------------------------------------------------------------------
; os_list_dialog -- Show a dialog with a list of options
; IN: ES:AX = comma-separated list of strings to show (zero-terminated),
;     ES:BX = first help string, ES:CX = second help string
; OUT: AX = number (starts from 1) of entry selected; carry set if Esc pressed

os_list_dialog equ 32936

; ------------------------------------------------------------------
; os_list_dialog_ex -- Show a dialog with a list of options
; IN: DS:BX = pointer to setup struct
;       Addr Size Description
;       000h word Pointer to entry display callback (accepts CX as entry ID, prints out result) - valid only if ptr to list is zero
;       002h word Pointer to comma-separated list of strings to show (zero-terminated)
;       004h word Pointer to key/entry change callback (accepts AX as entry ID, CX as keypress),
;       006h word Number of entries (if 0, then it is automatically calculated from 002h)
;       008h word Pointer to first help string (if 0, then the list will fill the whole dialog)
;       00Ah word Pointer to second help string
;       00Ch word (ES) Pointer to history data (points to a 5 byte array)
;       00Eh byte Screen X position
;       00Fh byte Screen Y position
;       010h byte Dialog width
;       011h byte Dialog height
;       012h word Source segment (used for comma-separated list & help strings)
; OUT: AX = number (starts from 1) of entry selected; carry set if Esc pressed

os_list_dialog_ex equ 33113

; ------------------------------------------------------------------
; os_select_list -- Draws a list of entries (defined by a callback) to select from.
; IN: AX = width/height, BL = color, CX = number of entries, DX = X/Y pos,
;     SI = callback (if C clear = accepts an entry ID in CX, prints an appropriate string,
;     if C set = accepts key input in AX, entry ID in CX; not required to preserve regs),
;     ES:DI = pointer to a history struct (word .num_of_entries, word .skip_num, byte .cursor) or 0 if none
; OUT: AX = number (starts from 1) of entry selected; carry set if Esc pressed

os_select_list equ 33110

; ------------------------------------------------------------------
; os_draw_background -- Clear screen with white top and bottom bars
; containing text, and a coloured middle section.
; IN: DS:AX/BX = top/bottom string locations, CX = colour (256 if the app wants to display the default background)
; OUT: None, registers preserved

os_draw_background equ 32807

; ------------------------------------------------------------------
; os_print_newline -- Reset cursor to start of next line
; IN/OUT: None, registers preserved

os_print_newline equ 32783

; ------------------------------------------------------------------
; os_dump_registers -- Dumps all register contents in hex to the screen
; IN: All registers
; OUT: None, registers preserved

os_dump_registers equ 32909

; ------------------------------------------------------------------
; os_input_dialog -- Get text string from user via a dialog box
; IN: ES:AX = string location, DS:BX = message to show
; OUT: None, registers preserved

os_input_dialog equ 32933

; ------------------------------------------------------------------
; os_password_dialog -- Get a password from user via a dialog box
; IN: ES:AX = string location, DS:BX = message to show
; OUT: None, registers preserved

os_password_dialog equ 33041

; ------------------------------------------------------------------
; os_dialog_box -- Print dialog box in middle of screen, with button(s)
; IN: DS:AX, DS:BX, DS:CX = string locations (set registers to 0 for no display),
; IN: DX = 0 for single 'OK' dialog,
;          1 for two-button 'OK' and 'Cancel' ('OK' selected by default),
;          2 for two-button 'OK' and 'Cancel' ('Cancel' selected by default)
; OUT: If two-button mode, AX = 0 for OK and 1 for cancel
; NOTE: Each string is limited to 40 characters

os_dialog_box equ 32825

; ------------------------------------------------------------------
; os_print_space -- Print a space to the screen
; IN/OUT: None, registers preserved

os_print_space equ 32873

; ------------------------------------------------------------------
; os_print_digit -- Displays contents of AX as a single digit
; Works up to base 37, ie digits 0-Z
; IN: AX = "digit" to format and print
; OUT: None, registers preserved

os_print_digit equ 32879

; ------------------------------------------------------------------
; os_print_1hex -- Displays low nibble of AL in hex format
; IN: AL = number to format and print
; OUT: None, registers preserved

os_print_1hex equ 32882

; ------------------------------------------------------------------
; os_print_2hex -- Displays AL in hex format
; IN: AL = number to format and print
; OUT: None, registers preserved

os_print_2hex equ 32885

; ------------------------------------------------------------------
; os_print_4hex -- Displays AX in hex format
; IN: AX = number to format and print
; OUT: None, registers preserved

os_print_4hex equ 32888

; ------------------------------------------------------------------
; os_print_8hex - Displays EAX in hex format
; IN: EAX = unsigned integer
; OUT: None, registers preserved

os_print_8hex equ 33065

; ------------------------------------------------------------------
; os_print_int -- Prints an integer in decimal.
; IN: AX = unsigned integer
; OUT: None, registers preserved

os_print_int equ 33101

; ------------------------------------------------------------------
; os_print_32int -- Prints a 32 bit integer in decimal.
; IN: EAX = unsigned integer
; OUT: None, registers preserved

os_print_32int equ 32951

; ------------------------------------------------------------------
; os_input_string -- Take string from keyboard entry
; IN: ES:AX = location of string
; OUT: None, registers preserved

os_input_string equ 32819

; ------------------------------------------------------------------
; os_input_password -- Take password from keyboard entry
; IN: ES:AX = location of string
; OUT: None, registers preserved

os_input_password equ 33077

; ------------------------------------------------------------------
; os_set_max_input_length -- Set the maximum length for the next string input
; IN: AL = maximum number of characters
; OUT: None, registers preserved

os_set_max_input_length equ 33131

; ------------------------------------------------------------------
; os_input_string_ex -- Take string from keyboard entry
; IN: ES:AX = location of string, CH = 0 if normal input, 1 if password input,
;     DS:SI = callback on keys where AL = 0 (input: AX = keypress)
; OUT: None, registers preserved

os_input_string_ex equ 33119

; ------------------------------------------------------------------
; os_color_selector - Pops up a color selector.
; IN: None
; OUT: color number (0-15)

os_color_selector equ 33053

; ------------------------------------------------------------------
; os_temp_box -- Draws a dialog box with up to 5 lines of text.
; IN: DS:SI/AX/BX/CX/DX = string locations (or 0 for no display)
; OUT: None, registers preserved

os_temp_box equ 33086

; ------------------------------------------------------------------
; os_reset_font -- Resets the font to the selected default.
; IN/OUT = None, registers preserved

os_reset_font equ 32990

; ------------------------------------------------------------------
; os_draw_logo -- Draws the MichalOS logo.
; IN: None
; OUT: A very beautiful logo :-)

os_draw_logo equ 32852

; ------------------------------------------------------------------
; os_draw_icon -- Draws an icon (in the MichalOS format).
; IN: DS:SI = address of the icon
; OUT: None, registers preserved

os_draw_icon equ 33023

; ------------------------------------------------------------------
; os_option_menu -- Show a menu with a list of options
; IN: AX = comma-separated list of strings to show (zero-terminated)
; OUT: AX = number (starts from 1) of entry selected; carry set if Esc, left or right pressed

os_option_menu equ 32876

; ==================================================================
; MichalOS String manipulation functions
; ==================================================================

; ------------------------------------------------------------------
; os_string_encrypt -- Encrypts a string using a totally military-grade encryption algorithm
; IN: DS:SI = Input string/Output string
; OUT: None, registers preserved

os_string_encrypt equ 33014

; ------------------------------------------------------------------
; os_string_add -- Add a string on top of another string
; IN: DS:AX = Main string, DS:BX = Added string
; OUT: None, registers preserved

os_string_add equ 32897

; ------------------------------------------------------------------
; os_string_length -- Return length of a string
; IN: DS:AX = string location
; OUT AX = length (other regs preserved)

os_string_length equ 32810

; ------------------------------------------------------------------
; os_string_reverse -- Reverse the characters in a string
; IN: DS:SI = string location
; OUT: None, registers preserved

os_string_reverse equ 32939

; ------------------------------------------------------------------
; os_find_char_in_string -- Find location of character in a string
; IN: DS:SI = string location, AL = character to find
; OUT: AX = location in string, or 0 if char not present

os_find_char_in_string equ 32867

; ------------------------------------------------------------------
; os_string_uppercase -- Convert zero-terminated string to upper case
; IN: DS:AX = string location
; OUT: None, registers preserved

os_string_uppercase equ 32813

; ------------------------------------------------------------------
; os_string_lowercase -- Convert zero-terminated string to lower case
; IN: DS:AX = string location
; OUT: None, registers preserved

os_string_lowercase equ 32816

; ------------------------------------------------------------------
; os_string_copy -- Copy one string into another
; IN: DS:SI = source, ES:DI = destination (programmer ensure sufficient room)
; OUT: None, registers preserved

os_string_copy equ 32822

; ------------------------------------------------------------------
; os_string_join -- Join two strings into a third string
; IN: DS:AX = string one, DS:BX = string two, ES:CX = destination string
; OUT: None, registers preserved

os_string_join equ 32828

; ------------------------------------------------------------------
; os_string_chomp -- Strip leading and trailing spaces from a string
; IN: DS:AX = string location
; OUT: None, registers preserved

os_string_chomp equ 32837

; ------------------------------------------------------------------
; os_string_compare -- See if two strings match
; IN: DS:SI = string one, DS:DI = string two
; OUT: carry set if same, clear if different

os_string_compare equ 32834

; ------------------------------------------------------------------
; os_string_parse -- Take string (eg "run foo bar baz") and return
; pointers to zero-terminated strings (eg AX = "run", BX = "foo" etc.)
; IN: DS:SI = string
; OUT: AX, BX, CX, DX = individual strings

os_string_parse equ 32960

; ------------------------------------------------------------------
; os_string_to_int -- Convert decimal string to integer value
; IN: DS:SI = string location (max 5 chars, up to '65535')
; OUT: AX = number

os_string_to_int equ 32942

; ------------------------------------------------------------------
; os_string_to_hex -- Convert hexadecimal string to integer value
; IN: DS:SI = string location (max 8 chars, up to 'FFFFFFFF')
; OUT: EAX = number

os_string_to_hex equ 32840

; ------------------------------------------------------------------
; os_int_to_string -- Convert unsigned integer to string
; IN: AX = unsigned int
; OUT: DS:AX = string location

os_int_to_string equ 32792

; ------------------------------------------------------------------
; os_sint_to_string -- Convert signed integer to string
; IN: AX = signed int
; OUT: DS:AX = string location

os_sint_to_string equ 32957

; ------------------------------------------------------------------
; os_get_time_string -- Get current time in a string (eg '10:25')
; IN: ES:BX = string location
; OUT: None, registers preserved

os_get_time_string equ 32849

; ------------------------------------------------------------------
; os_get_date_string -- Get current date in a string (eg '12/31/2007')
; IN: ES:BX = string location
; OUT: None, registers preserved

os_get_date_string equ 32858

; ------------------------------------------------------------------
; os_string_tokenize -- Reads tokens separated by specified char from
; a string. Returns pointer to next token, or 0 if none left
; IN: AL = separator char, DS:SI = beginning
; OUT: DI = next token or 0 if none

os_string_tokenize equ 32972

; ------------------------------------------------------------------
; os_string_callback_tokenizer -- Prints a token from string, requests are done by callback
; IN: DS:AX = comma-separated string
; OUT: AL = AH = max length of any token, CX = number of entries in the list,
;      DX:SI = callback location (if C clear, accepts CX as entry ID, prints out result)

os_string_callback_tokenizer equ 33128

; ------------------------------------------------------------------
; os_32int_to_string -- Converts an unsigned 32-bit integer into a string
; IN: EAX = unsigned int
; OUT: DS:AX = string location

os_32int_to_string equ 33059

; ------------------------------------------------------------------
; os_string_to_32int -- Converts a string into a 32-bit integer
; IN: DS:SI = string location
; OUT: EAX = unsigned integer

os_string_to_32int equ 33068

; ==================================================================
; MichalOS Miscellaneous functions
; ==================================================================

; ------------------------------------------------------------------
; os_read_config_byte -- Reads a byte from the config
; IN: BX = offset
; OUT: AL = value

os_read_config_byte equ 33134

; ------------------------------------------------------------------
; os_read_config_word -- Reads a word from the config
; IN: BX = offset
; OUT: AX = value

os_read_config_word equ 33137

; ------------------------------------------------------------------
; os_write_config_byte -- Writes a byte to the config
; NOTE: This will only affect the config in memory,
; run os_save_config to save the changes to disk!
; IN: BX = offset, AL = value
; OUT: None, registers preserved

os_write_config_byte equ 33140

; ------------------------------------------------------------------
; os_write_config_word -- Writes a byte to the config
; NOTE: This will only affect the config in memory,
; run os_save_config to save the changes to disk!
; IN: BX = offset, AX = value
; OUT: None, registers preserved

os_write_config_word equ 33143

; ------------------------------------------------------------------
; os_save_config -- Saves the current config to disk
; OUT: Carry set if error

os_save_config equ 33146

; ------------------------------------------------------------------
; os_exit -- Exits the application, launches another one (if possible)
; IN: AX = if not 0, then ptr to filename of application to be launched,
;     BX = 1 if the application calling os_exit should be re-launched after
;     the requested application exits
; OUT: None, register preserved

os_exit equ 32780

; ------------------------------------------------------------------
; os_clear_registers -- Clear all registers
; IN: None
; OUT: Cleared registers

os_clear_registers equ 32975

; ------------------------------------------------------------------
; os_get_os_name -- Get the OS name string
; IN: None
; OUT: DS:SI = OS name string, zero-terminated

os_get_os_name equ 33083

; ------------------------------------------------------------------
; os_get_memory -- Gets the amount of system RAM.
; IN: None
; OUT: AX = conventional memory (in kB), BX = high memory (in kB)

os_get_memory equ 33050

; ------------------------------------------------------------------
; os_int_1Ah -- Middle-man between the INT 1Ah call and the kernel/apps (used for timezones).
; IN/OUT: same as int 1Ah

os_int_1Ah equ 33032

; ==================================================================
; MichalOS Sound functions (PC speaker, YM3812)
; ==================================================================

; ------------------------------------------------------------------
; os_speaker_tone -- Generate PC speaker tone (call os_speaker_off to turn off)
; IN: AX = note frequency (in Hz)
; OUT: None, registers preserved

os_speaker_tone equ 32795

; ------------------------------------------------------------------
; os_speaker_raw_period -- Generate PC speaker tone (call os_speaker_off to turn off)
; IN: AX = note period (= 105000000 / 88 / freq)
; OUT: None, registers preserved

os_speaker_raw_period equ 33107

; ------------------------------------------------------------------
; os_speaker_note_length -- Generate PC speaker tone for a set amount of time and then stop
; IN: AX = note frequency, CX = length (in ticks)
; OUT: None, registers preserved

os_speaker_note_length equ 32900

; ------------------------------------------------------------------
; os_speaker_off -- Turn off PC speaker
; IN/OUT: None, registers preserved

os_speaker_off equ 32798

; ------------------------------------------------------------------
; os_speaker_muted -- Check if the PC speaker is muted
; OUT: ZF set if muted, clear if not

os_speaker_muted equ 33125

; ------------------------------------------------------------------
; os_start_adlib -- Starts the selected Adlib driver
; IN: SI = interrupt handler, CX = prescaler, BL = number of channels
; The interrupt will fire at 33144 Hz (the closest possible to 32768 Hz) divided by CX.
; Common prescaler values:
;		33 = ~1 kHz (1004.362 Hz)
;		663 = ~50 Hz (49.991 Hz)
;		1820 = ~18.2 Hz (18.211 Hz)
; OUT: None, registers preserved

os_start_adlib equ 32984

; ------------------------------------------------------------------
; os_stop_adlib -- Stops the Adlib driver
; IN/OUT: None, registers preserved

os_stop_adlib equ 33026

; ------------------------------------------------------------------
; os_adlib_regwrite -- Write to a YM3812 register
; IN: AH/AL - register address/value to write

os_adlib_regwrite equ 32843

; ------------------------------------------------------------------
; os_adlib_mute -- Mute the YM3812's current state
; IN/OUT: None

os_adlib_mute equ 33044

; ------------------------------------------------------------------
; os_adlib_unmute -- Unmute the YM3812's current state
; IN/OUT: None

os_adlib_unmute equ 33089

; ------------------------------------------------------------------
; os_adlib_calcfreq -- Play a frequency
; IN: AX - frequency, CL = channel
; OUT: None, registers preserved

os_adlib_calcfreq equ 32966

; ------------------------------------------------------------------
; os_adlib_noteoff -- Turns off a note
; IN: CL = channel
; OUT: None, registers preserved

os_adlib_noteoff equ 33029

; ==================================================================
; MichalOS Disk access functions
; ==================================================================

; ------------------------------------------------------------------
; os_report_free_space -- Returns the amount of free space on disk
; IN: None
; OUT: AX = Number of sectors free

os_report_free_space equ 32894

; ------------------------------------------------------------------
; os_get_file_list -- Generate comma-separated string of files on floppy
; IN/OUT: AX = location to store zero-terminated filename string

os_get_file_list equ 32831

; ------------------------------------------------------------------
; os_load_file -- Load a file into RAM
; IN: AX = location of filename, ES:CX = location in RAM to load file
; OUT: BX = file size (in bytes), carry set if file not found

os_load_file equ 32801

; --------------------------------------------------------------------------
; os_write_file -- Save (max 64K) file to disk
; IN: AX = filename, ES:BX = data location, CX = bytes to write
; OUT: Carry clear if OK, set if failure

os_write_file equ 32915

; --------------------------------------------------------------------------
; os_file_exists -- Check for presence of file on the floppy
; IN: AX = filename location; OUT: carry clear if found, set if not

os_file_exists equ 32918

; --------------------------------------------------------------------------
; os_create_file -- Creates a new 0-byte file on the floppy disk
; IN: AX = location of filename
; OUT: None, registers preserved

os_create_file equ 32921

; --------------------------------------------------------------------------
; os_remove_file -- Deletes the specified file from the filesystem
; IN: AX = location of filename to remove

os_remove_file equ 32924

; --------------------------------------------------------------------------
; os_rename_file -- Change the name of a file on the disk
; IN: AX = filename to change, BX = new filename (zero-terminated strings)
; OUT: carry set on error

os_rename_file equ 32927

; --------------------------------------------------------------------------
; os_get_file_size -- Get file size information for specified file
; IN: AX = filename; OUT: EBX = file size in bytes (up to 4GB)
; or carry set if file not found

os_get_file_size equ 32930

; --------------------------------------------------------------------------
; os_get_file_datetime -- Get file write time/date information for specified file
; IN: AX = filename; OUT: BX = time of creation (HHHHHMMMMMMSSSSS), CX = date of creation (YYYYYYYMMMMDDDDD)
; or carry set if file not found

os_get_file_datetime equ 33011

; --------------------------------------------------------------------------
; os_get_boot_disk -- Returns the boot disk number.
; IN: None
; OUT: DL = boot disk number for use in INT 13h calls

os_get_boot_disk equ 33062

; ==================================================================
; MichalOS Keyboard input handling functions
; ==================================================================

; ------------------------------------------------------------------
; os_wait_for_key -- Waits for keypress and returns key
; Also handles the screensaver. TODO: move the screensaver code to "int.asm"
; IN: None
; OUT: AX = key pressed, other regs preserved

os_wait_for_key equ 32786

; ------------------------------------------------------------------
; os_check_for_key -- Scans keyboard buffer for input, but doesn't wait
; Also handles special keyboard shortcuts.
; IN: None
; OUT: AX = 0 if no key pressed, otherwise scan code

os_check_for_key equ 32789

; ==================================================================
; MichalOS/MikeOS 4.5 BASIC interpreter
; ==================================================================

; ------------------------------------------------------------------
; The BASIC interpreter execution starts here -- a parameter string
; is passed in SI and copied into the first string, unless SI = 0

os_run_basic equ 32963

; ==================================================================
; MichalOS Interrupt management & app timer functions
; ==================================================================

; -----------------------------------------------------------------
; os_modify_int_handler -- Change location of interrupt handler
; IN: CL = int number, DI:SI = handler location
; OUT: None, registers preserved

os_modify_int_handler equ 33056

; -----------------------------------------------------------------
; os_get_int_handler -- Change location of interrupt handler
; IN: CL = int number
; OUT: DI:SI = handler location

os_get_int_handler equ 33080

; ------------------------------------------------------------------
; os_pause -- Delay execution for a specified number of ticks (18.2 Hz by default)
; IN: AX = amount of ticks to wait
; OUT: None, registers preserved

os_pause equ 32804

; -----------------------------------------------------------------
; os_attach_app_timer -- Attach a timer interrupt to an application and sets the timer speed
; Formula: speed = (105000000 / 88) / frequency
; IN: DS:SI = handler location, CX = speed
; OUT: None, registers preserved

os_attach_app_timer equ 32969

; -----------------------------------------------------------------
; os_return_app_timer -- Returns the timer interrupt back to the system and resets the timer speed
; IN/OUT: None, registers preserved

os_return_app_timer equ 32987

; -----------------------------------------------------------------
; os_set_timer_speed -- Sets the timer's trigger speed.
; Formula: speed = (105000000 / 88) / frequency
; IN: CX = speed
; OUT: Nothing, registers preserved

os_set_timer_speed equ 32891

; ==================================================================
; MichalOS ZX7 decompression routine
; ==================================================================

; ------------------------------------------------------------------
; os_decompress_zx7 -- Decompresses ZX7-packed data.
; IN: DS:SI = source, ES:DI = destination
; OUT: None, registers preserved

os_decompress_zx7 equ 33038

; ==================================================================
; MichalOS Port I/O functions
; ==================================================================

; ------------------------------------------------------------------
; os_serial_port_enable -- Set up the serial port for transmitting data
; IN: AX = 0 for normal mode (9600 baud), or 1 for slow mode (1200 baud)
; OUT: None, registers preserved

os_serial_port_enable equ 32954

; ------------------------------------------------------------------
; os_send_via_serial -- Send a byte via the serial port
; IN: AL = byte to send via serial
; OUT: AH = Bit 7 clear on success

os_send_via_serial equ 32861

; ------------------------------------------------------------------
; os_get_via_serial -- Get a byte from the serial port
; IN: None
; OUT: AL = byte that was received, AH = Bit 7 clear on success

os_get_via_serial equ 32864

; ==================================================================
; MichalOS Math functions
; ==================================================================

; ------------------------------------------------------------------
; os_get_random -- Return a random integer between low and high (inclusive)
; IN: AX = low integer, BX = high integer
; OUT: CX = random integer

os_get_random equ 32948

; ------------------------------------------------------------------
; os_bcd_to_int -- Converts a binary coded decimal number to an integer
; IN: AL = BCD number
; OUT: AX = integer value

os_bcd_to_int equ 32846

; ------------------------------------------------------------------
; os_int_to_bcd -- Converts an integer to a binary coded decimal number
; IN: AL = integer value
; OUT: AL = BCD number

os_int_to_bcd equ 33035

; ------------------------------------------------------------------
; os_math_power -- Calculates EAX^EBX.
; IN: EAX^EBX = input
; OUT: EAX = result

os_math_power equ 33071

; ------------------------------------------------------------------
; os_math_root -- Approximates the EBXth root of EAX.
; IN: EAX = input, EBX = root
; OUT: EAX(EDX = 0) = result; EAX to EDX = range

os_math_root equ 33074

; ==================================================================
; MichalOS Low-level disk driver
; ==================================================================

; --------------------------------------------------------------------------
; os_disk_read_sector -- Read a single sector from disk
; IN: EAX = sector ID, ES:SI = 512 byte buffer, DL = drive number, OUT: carry set if error

os_disk_read_sector equ 33092

; --------------------------------------------------------------------------
; os_disk_read_multiple_sectors -- Read multiple sectors from disk
; IN: EAX = sector ID, CX = number of sectors, ES:SI = 512 byte buffer, DL = drive number, OUT: carry set if error

os_disk_read_multiple_sectors equ 33104

; --------------------------------------------------------------------------
; os_disk_write_sector -- Write a single sector to disk
; IN: EAX = sector ID, ES:SI = 512 byte buffer, DL = drive number, OUT: carry set if error

os_disk_write_sector equ 33098

; --------------------------------------------------------------------------
; os_disk_write_multiple_sectors -- Write multiple sectors to disk
; IN: EAX = sector ID, CX = number of sectors, ES:SI = 512 byte buffer, DL = drive number, OUT: carry set if error

os_disk_write_multiple_sectors equ 33116

