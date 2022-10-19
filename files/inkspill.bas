rem InkSpill port for MichalOS
rem Memory map:
rem  20000 - 60255: tile data
rem   1 - red
rem   2 - orange
rem   3 - yellow
rem   4 - green
rem   5 - blue
rem   6 - purple
rem   multiplied by 7 if tile is active
rem Used variables & strings:
rem a,b,c,d,e,x,y,z: temporary variables
rem g: game ended
rem l: steps left
rem h: reset requested
rem $1: temporary string

rem -----------------------------------------Resetovat hru
reset:
 cls
 cursor off

 g = 0
 l = 35
 h = 0
 
 for x = 0 to 15
  for y = 0 to 15
   rand a 1 6
   c = y * 16
   b = 20000 + x + c
   poke a b
  next y
 next x

 rem -----------------------------------------Pozadi: svetle seda
 ink 112
  for x = 0 to 24
   for y = 0 to 79
    move y x
    print " ";
   next y
  next x
 
 peek a 20000
 a = a * 7
 poke a 20000
 
rem -----------------------------------------Hlavni smycka
mainloop:
 gosub checkforactive
 if h = 1 then goto reset
 gosub gamecheck
 gosub render
 gosub controls
 goto mainloop
 
rem -----------------------------------------Zkontrolovat, zda je konec hry
gamecheck:
 e = 0
 for x = 0 to 15
  for y = 0 to 15
   c = y * 16
   b = 20000 + x + c
   peek a b
   d = a % 7
   if d = 0 then e = e + 1
  next y
 next x
 if e = 256 then goto youwin
 if l = 0 then goto youlose
 return
 
rem -----------------------------------------Hrac vyhral
youwin:
 if g = 1 then goto skipwin
 load "inkspill.dat" 20000
 g = 1
 ink 112
 move 1 15
 print "You win!"
skipwin:
 return

rem -----------------------------------------Hrac prohral
youlose:
 if g = 1 then goto skiplose
 load "inkspill.dat" 19744
 g = 1
 ink 112
 move 1 15
 print "Game over!"
skiplose:
 return
 
rem -----------------------------------------Render herniho planu a popisku
render:
 rem -----------------------------------------Popisky
 ink 112 
 move 1 1
 print "InkSpill"
 move 1 3
 print "Controls:"
 move 1 4
 ink 116
 print "Q - Red"
 move 1 5
 ink 118
 print "W - Orange/Brown"
 move 1 6
 ink 126
 print "E - Yellow"
 move 1 7
 ink 114
 print "R - Green"
 move 1 8
 ink 113
 print "T - Blue"
 move 1 9
 ink 117
 print "Y - Purple"
 
 ink 112
 move 1 10
 print "O - Reset the game"
 move 1 11
 print "P - Quit"
 move 1 13
 print "Remaining steps: ";
 number l $1
 print $1;
 print "  "
 move 1 14
 print "Acquired tiles: ";
 z = 0
 for x = 0 to 15
  for y = 0 to 15
   e = y * 16
   b = 20000 + x + e
   peek a b
   c = a % 7
   if c = 0 then z = z + 1
  next y
 next x
 number z $1
 print $1;
 print "  "
 
 rem -----------------------------------------Herni plan
 for x = 0 to 15
  for y = 0 to 15
   e = y * 16
   b = 20000 + x + e
   peek a b
   f = x * 2
   c = f + 30
   d = y + 1
   move c d
   e = a % 7
   if e = 0 then a = a / 7
   if a = 1 then ink 4
   if a = 2 then ink 6
   if a = 3 then ink 14
   if a = 4 then ink 2
   if a = 5 then ink 1
   if a = 6 then ink 5
   print chr 219
   c = c + 1
   move c d
   print chr 219
  next y
 next x
   
 return
 
rem -----------------------------------------Ovladani
controls:
 waitkey x
 if x = 'q' then goto red
 if x = 'w' then goto orange
 if x = 'e' then goto yellow
 if x = 'r' then goto green
 if x = 't' then goto blue
 if x = 'y' then goto purple
 if x = 'o' then goto resetgame
 if x = 'p' then goto exit
 h = 0
 return
 
resetgame:
 h = 1
 return
 
red:
 c = 1 * 7
 for x = 0 to 15
  for y = 0 to 15
   d = y * 16
   b = 20000 + x + d
   peek a b
   e = a % 7
   if e = 0 then poke c b
  next y
 next x
 l = l - 1
 return

orange:
 c = 2 * 7
 for x = 0 to 15
  for y = 0 to 15
   d = y * 16
   b = 20000 + x + d
   peek a b
   e = a % 7
   if e = 0 then poke c b
  next y
 next x
 l = l - 1
 return

yellow:
 c = 3 * 7
 for x = 0 to 15
  for y = 0 to 15
   d = y * 16
   b = 20000 + x + d
   peek a b
   e = a % 7
   if e = 0 then poke c b
  next y
 next x
 l = l - 1
 return

green:
 c = 4 * 7
 for x = 0 to 15
  for y = 0 to 15
   d = y * 16
   b = 20000 + x + d
   peek a b
   e = a % 7
   if e = 0 then poke c b
  next y
 next x
 l = l - 1
 return

blue:
 c = 5 * 7
 for x = 0 to 15
  for y = 0 to 15
   d = y * 16
   b = 20000 + x + d
   peek a b
   e = a % 7
   if e = 0 then poke c b
  next y
 next x
 l = l - 1
 return

purple:
 c = 6 * 7
 for x = 0 to 15
  for y = 0 to 15
   d = y * 16
   b = 20000 + x + d
   peek a b
   e = a % 7
   if e = 0 then poke c b
  next y
 next x
 l = l - 1
 return

rem -----------------------------------------Kontrolovani aktivnich policek
checkforactive:
 for z = 0 to 15
  for x = 0 to 15
   for y = 0 to 15
    c = y * 16
    b = 20000 + x + c
    peek a b
    d = a % 7
    if d = 0 then gosub activefound
   next y
  next x
 next z
 return

rem -----------------------------------------Aktivni dilek nalezen, zaktivuj
rem i ty ostatni okolo neho(pokud maji stejnou barvu)
activefound:
 c = a / 7
 
 d = y * 16
 
right:
 if x = 15 then goto left
 b = 20000 + x + d + 1
 peek a b
 if a = c then gosub activate
 
left:
 if x = 0 then goto down
 b = 20000 + x + d - 1
 peek a b
 if a = c then gosub activate
 
down:
 if y = 15 then goto up
 b = 20000 + x + d + 16
 peek a b
 if a = c then gosub activate
 
up:
 if y = 0 then goto activeset
 b = 20000 + x + d - 16
 peek a b
 if a = c then gosub activate
 
activeset:
 return

rem -----------------------------------------Aktivni dilek nalezen, zaktivuj
activate:
 a = a * 7
 poke a b
 return

rem -----------------------------------------Ukoncit hru
exit:
 end
