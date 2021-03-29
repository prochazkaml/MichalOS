; MichalOS menu file

ORG 0

mainmenu:			db 0
	.width			db 13
	.string_ptr		dw menuoptions
	.table_ptr		dw menuindex
	
appmenu:			db 0
	.width			db 20
	.string_ptr		dw appoptions
	.table_ptr		dw appindex
	
gamemenu:			db 0
	.width			db 19
	.string_ptr		dw gameoptions
	.table_ptr		dw gameindex
	
debugmenu:			db 0
	.width			db 31
	.string_ptr		dw debugoptions
	.table_ptr		dw debugindex
	
logout:				db 1
shutdown:			db 2

	menuoptions				db 'Programs,Games,Log out,Shut down', 0
	gameoptions				db 'Cosmic Flight,InkSpill,Space Inventors,aSMtris,Sudoku,Deep Sea Fisher,MikeTron,Muncher,Hangman,Snake', 0
	debugoptions			db 'Disk Detection Test,Keyboard Tester,Serial Communication Tester,RTC Clock Tester,Disk Sector Inspector,Memory Editor,Boxes,Dots,Mouse Tester,VESA Tester', 0
	appoptions				db 'File Manager,Text Editor,Image Viewer,Calculator,Clock,Terminal,Settings,ASCII art editor,Pixel art editor,Music player,Hardware checker,About MichalOS,Debug tools', 0

	menuindex				dw appmenu, gamemenu, logout, shutdown
	appindex				dw edit_name, viewer_name, calc_name, clock_name, cmd_name, config_name, ascii_name, pixel_name, player_name, hwcheck_name, about_name, debugmenu
	debugindex				dw debug1_name, debug2_name, debug3_name, debug4_name, debug5_name, debug6_name, debug7_name, debug8_name, debug9_name, debug10_name
	gameindex				dw cf_name, inkspill_name, spaceinv_name, asmtris_name, sudoku_name, fisher_name, miketron_name, muncher_name, hangman_name, snake_name
	
	edit_name				db 'EDIT.APP', 0
	viewer_name				db 'VIEWER.APP', 0
	calc_name				db 'CALC.APP', 0
	clock_name				db 'CLOCK.APP', 0
	cmd_name				db 'TERMINAL.APP', 0
	config_name				db 'CONFIG.APP', 0
	ascii_name				db 'ASCIIART.APP', 0
	pixel_name				db 'PIXEL.APP', 0
	player_name				db 'PLAYER.APP', 0
	hwcheck_name			db 'HWCHECK.APP', 0
	about_name				db 'ABOUT.APP', 0

	debug1_name				db 'DISKTEST.APP', 0
	debug2_name				db 'KBDTEST.APP', 0
	debug3_name				db 'SERIAL.APP', 0
	debug4_name				db 'RTCTEST.APP', 0
	debug5_name				db 'SECTOR.APP', 0
	debug6_name				db 'MEMEDIT.APP', 0
	debug7_name				db 'BOXES.APP', 0
	debug8_name				db 'DOTS.APP', 0
	debug9_name				db 'MOUSE.APP', 0
	debug10_name			db 'VESATEST.APP', 0
	
	cf_name					db 'CF.BAS', 0
	inkspill_name			db 'INKSPILL.BAS', 0
	spaceinv_name			db 'SPACEINV.APP', 0
	asmtris_name			db 'ASMTRIS.APP', 0
	sudoku_name				db 'SUDOKU.APP', 0
	fisher_name				db 'FISHER.APP', 0
	miketron_name			db 'MIKETRON.BAS', 0
	muncher_name			db 'MUNCHER.BAS', 0
	hangman_name			db 'HANGMAN.APP', 0
	snake_name				db 'SNAKE.APP', 0
