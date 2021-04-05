### MichalOS Makefile

.DEFAULT_GOAL := build

# These targets aren't triggered by a change of a file.
.PHONY: clean boot bootdebug

# This selects all programs and music files to be built.
PROGRAMS := $(patsubst %.asm,%.app,$(sort $(wildcard programs/*.asm)))
SONGS := $(patsubst %.mus,%.mmf,$(sort $(wildcard content/*.mus)))
DROS := $(patsubst %.dro,%.drz,$(sort $(wildcard content/*.dro)))

# This selects all files to copy to the final image.
FILEDIRS := programs/*.bas programs/*.dat content/*.pcx content/*.rad content/*.asc source/sys/*.sys programs/res/*.mlz
FILES := $(PROGRAMS) $(SONGS) $(DROS) $(foreach dir,$(FILEDIRS),$(sort $(wildcard $(dir))))

# Default target: build the image and boot it.
build: build/michalos.flp
	dosbox -conf misc/dosbox.conf

# Optional target: force rebuild everything.
force: clean build

# Development target: build as usual, but use dosbox-debug instead of regular DOSBox.
dev: build/michalos.flp
	dosbox-debug -conf misc/dosbox.conf

# Bootloader target
source/bootload/bootload.bin: source/bootload/bootload.asm
	nasm -O2 -w+orphan-labels -f bin -o source/bootload/bootload.bin source/bootload/bootload.asm

# Kernel target
source/michalos.sys: source/system.asm source/features/*.asm
	nasm -O2 -w+orphan-labels -f bin -I source/ -o source/michalos.sys source/system.asm -l source/system.lst

# Assembles all programs.
# Note: % means file name prefix, $@ means output file and $< means source file.
programs/%.app: programs/%.asm programs/%/*.asm programs/michalos.inc
	nasm -O2 -w+orphan-labels -f bin -I programs/ -o $@ $< #-l $@.lst 
	
programs/%.app: programs/%.asm programs/michalos.inc
	nasm -O2 -w+orphan-labels -f bin -I programs/ -o $@ $< #-l $@.lst 

# Assembles all songs.
content/%.mmf: content/%.mus content/notelist.txt
	nasm -O2 -w+orphan-labels -f bin -I content/ -o $@ $<

content/%.drz: content/%.dro
	misc/compress $< $@

# Builds the image.
build/michalos.flp: source/bootload/bootload.bin source/michalos.sys \
					$(PROGRAMS) $(SONGS) $(DROS)
	-rm build/*

	dd if=/dev/zero of=build/michalos.flp bs=512 count=2880
	dd status=noxfer conv=notrunc if=source/bootload/bootload.bin of=build/michalos.flp
	
	mcopy -i $@ source/michalos.sys ::michalos.sys
	$(foreach file,$(FILES),mcopy -i $@ $(file) ::$(notdir $(file));)

	mkisofs -quiet -V 'MICHALOS' -input-charset iso8859-1 -o build/michalos.iso -b michalos.flp build/

# Removes all of the built pieces.
clean:
	-rm build/*
	-rm programs/*.app
	-rm programs/*.lst
	-rm content/*.drz
	-rm content/*.mmf
	-rm source/*.sys
	-rm source/bootload/*.bin
