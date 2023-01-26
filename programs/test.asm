; ------------------------------------------------------------------
; MichalOS VESA mode checker
; ------------------------------------------------------------------

	%INCLUDE "include/program.inc"
	
%define one_button 0
%define two_buttons 1
%define empty_string 0
%define exit_application ret
%define string db
%define endstring , 0
%define default_background 256
	
%macro dialog_box 3-4 one_button
	mov ax, %1
	mov bx, %2
	mov cx, %3
	mov dx, %4
	call os_dialog_box	
%endmacro

%macro draw_background 3
	mov ax, %1
	mov bx, %2
	mov cx, %3
	call os_draw_background
%endmacro


start:
	draw_background title, empty, default_background
	dialog_box helloworldmsg, empty, empty
	exit_application
	
	title			string "MichalOS Test App" endstring
	empty			string empty_string
	helloworldmsg	string "Hello, World!" endstring
