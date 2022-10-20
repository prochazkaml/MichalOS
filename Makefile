### MichalOS Makefile

.DEFAULT_GOAL := retail

# These targets aren't triggered by a change of a file.
.PHONY: clean

# This selects all programs and music files to be built.
PROGRAMS := \
	$(patsubst programs/%.asm,build/%.app,$(sort $(wildcard programs/*.asm))) \
	$(patsubst programs/gitignore/%.asm,build/%.app,$(sort $(wildcard programs/gitignore/*.asm)))
MMF := $(patsubst files/src/%.mus,build/%.mmf,$(sort $(wildcard files/src/*.mus)))
DRO := $(patsubst files/src/%.dro,build/%.drz,$(sort $(wildcard files/src/*.dro)))

# This selects all files to copy to the final image.
FILES := $(PROGRAMS) $(MMF) $(DRO) $(wildcard files/*.*) $(wildcard files/gitignore/*.*)

build:
	mkdir -p $@

build/images:
	mkdir -p $@

build/images/isoroot:
	mkdir -p $@

build/images/iso288root:
	mkdir -p $@

# Default target: builds the image and boots it.
retail: build/images/michalos.flp
	dosbox -conf misc/dosbox.conf -c "boot build/images/michalos.flp"

# Development target: builds as usual, but uses dosbox-debug instead of regular DOSBox.
debug: build/images/michalos.flp
	dosbox-debug -conf misc/dosbox.conf -c "boot build/images/michalos.flp"

# Noboot target: builds as usual, but does not boot the image.
noboot: build/images/michalos.flp

# "Big" floppy target: builds an 2.88 image (containing a 1.44 MB FAT filesystem and a 1.44 MB binary)
big: build/images/michalos288.flp
	dosbox -conf misc/dosbox.conf -c "boot build/images/michalos288.flp"

bigdebug: build/images/michalos288.flp
	dosbox-debug -conf misc/dosbox.conf -c "boot build/images/michalos288.flp"

bignoboot: build/images/michalos288.flp

# Bootloader target
build/boot.bin: boot/boot.asm | build
	nasm -O2 -w+all -f bin -o $@ -l build/boot.lst boot/boot.asm

# Kernel target
build/kernel.sys: kernel/main.asm kernel/features/*.asm | build
	nasm -O2 -w+all -f bin -I kernel/ -o $@ -l build/kernel.lst kernel/main.asm

# Assembles all programs.
# Note: % means file name prefix, $@ means output file and $< means source file.
build/%.app: programs/gitignore/%.asm programs/gitignore/%/*.asm programs/michalos.inc | build
	nasm -O2 -w+all -f bin -I programs/ -I programs/gitignore/ -o $@ -l $@.lst $< 
	
build/%.app: programs/gitignore/%.asm programs/michalos.inc | build
	nasm -O2 -w+all -f bin -I programs/ -I programs/gitignore/ -o $@ -l $@.lst $< 
	
build/%.app: programs/%.asm programs/%/*.asm programs/michalos.inc | build
	nasm -O2 -w+all -f bin -I programs/ -o $@ -l $@.lst $< 
	
build/%.app: programs/%.asm programs/michalos.inc | build
	nasm -O2 -w+all -f bin -I programs/ -o $@ -l $@.lst $< 
	
# Assembles all songs.
build/%.mmf: files/src/%.mus files/src/notelist.txt | build
	nasm -O2 -w+all -f bin -I files/src/ -o $@ $<

build/%.drz: files/src/%.dro | build
	misc/zx7/segmented_zx7 $< $@

# Builds the image.
build/images/michalos.flp: build/boot.bin build/kernel.sys \
					$(FILES) | build/images
	dd if=/dev/zero of=build/images/michalos.flp bs=512 count=2880
	dd conv=notrunc if=build/boot.bin of=build/images/michalos.flp
	
	mcopy -i $@ build/kernel.sys $(FILES) ::

build/images/michalos288.flp: build/images/michalos.flp files/gitignore/288data
	cp files/gitignore/288data build/288data
	truncate -s 1474560 build/288data
	cat build/images/michalos.flp build/288data > $@

# Optional target: builds a bootable ISO image for CDs.
iso: build/images/michalos.iso

build/images/michalos.iso: build/images/michalos.flp | build/images/isoroot
	rm -f $@
	cp $< build/images/isoroot/michalos.flp
	mkisofs -V 'MICHALOS' -input-charset iso8859-1 -o $@ -b michalos.flp build/images/isoroot/

bigiso: build/images/michalos288.iso

build/images/michalos288.iso: build/images/michalos288.flp | build/images/iso288root
	rm -f $@
	cp $< build/images/iso288root/michalos.flp
	mkisofs -V 'MICHALOS' -input-charset iso8859-1 -o $@ -b michalos.flp build/images/iso288root/

# Removes all of the built pieces.
clean:
	-rm -rf build
