### MichalOS Makefile

.DEFAULT_GOAL := retail

# These targets aren't triggered by a change of a file.
.PHONY: clean

# This selects all programs and music files to be built.
PROGRAMS := $(patsubst programs/%.asm,build/%.app,$(sort $(wildcard programs/*.asm)))
SONGS := $(patsubst files/src/%.mus,build/%.mmf,$(sort $(wildcard files/src/*.mus)))
DROS := $(patsubst files/src/%.dro,build/%.drz,$(sort $(wildcard files/src/*.dro)))

# This selects all files to copy to the final image.
FILES := $(PROGRAMS) $(SONGS) $(DROS) $(foreach dir,files/*.*,$(sort $(wildcard $(dir))))

build:
	mkdir -p $@

build/images:
	mkdir -p $@

# Default target: builds the image and boots it.
retail: build/images/michalos.flp
	dosbox -conf misc/dosbox.conf

# Development target: builds as usual, but uses dosbox-debug instead of regular DOSBox.
debug: build/images/michalos.flp
	dosbox-debug -conf misc/dosbox.conf

# Bootloader target
build/bootload.bin: system/bootload/bootload.asm | build
	nasm -O2 -w+all -f bin -o build/bootload.bin -l build/bootload.lst system/bootload/bootload.asm

# Kernel target
build/michalos.sys: system/kernel.asm system/features/*.asm | build
	nasm -O2 -w+all -f bin -I system/ -o build/michalos.sys -l build/kernel.lst system/kernel.asm

# Assembles all programs.
# Note: % means file name prefix, $@ means output file and $< means source file.
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
build/images/michalos.flp: build/bootload.bin build/michalos.sys \
					$(FILES) | build/images
	dd if=/dev/zero of=build/images/michalos.flp bs=512 count=2880
	dd conv=notrunc if=build/bootload.bin of=build/images/michalos.flp
	
	mcopy -i $@ build/michalos.sys ::michalos.sys
	$(foreach file,$(FILES),mcopy -i $@ $(file) ::$(notdir $(file));)

# Optional target: builds a bootable ISO image for CDs.
iso: build/images/michalos.iso

build/images/michalos.iso: build/images/michalos.flp
	-rm build/images/michalos.iso
	mkisofs -quiet -V 'MICHALOS' -input-charset iso8859-1 -o build/images/michalos.iso -b michalos.flp build/images/

# Removes all of the built pieces.
clean:
	-rm -rf build
