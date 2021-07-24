# MichalOS

A 16-bit keyboard controlled operating system based on MikeOS 4.5, aimed to be more advanced and lightweight on the inside, but simple and easy to use on the outside.

## New features

- Screensaver with customizable timeout
- Customizable user interface (custom background, window colors etc.)
- Custom font
- On-screen clock with timezone support
- AdLib synthesizer support
- Built-in graphics drawing functions

## System requirements

- Intel 80386 or higher, Pentium recommended
- At least 80 kB RAM, 256 kB recommended
- An EGA video card, VGA recommended
- A keyboard

## Screenshots

![Login screen](https://a.fsdn.com/con/app/proj/michalos/screenshots/Screenshot%20from%202019-07-11%2020-50-20.png/max/max/1)
![Desktop](https://a.fsdn.com/con/app/proj/michalos/screenshots/Screenshot%20from%202019-07-11%2020-50-27.png/max/max/1)

More screenshots are available in the [gallery](https://github.com/prochazkaml/MichalOS/blob/master/misc/gallery.md).

## Building instructions

For building the OS, a Unix-based system is required (Linux, BSD, WSL, macOS) with **NASM**, **mtools** and **make** installed. **DOSBox** is required for testing MichalOS builds (QEMU, [VirtualBox](https://github.com/prochazkaml/MichalOS/blob/master/misc/VirtualBox.md), VMware etc. could also be used, but you will be met with limited functionality).

On Debian GNU/Linux (and its derivates, such as Linux Mint or Ubuntu), these requirements can be met by running ```sudo apt-get install nasm mtools make dosbox```.

It is also necessary to install a ZX7 data compressor with ```cd misc/zx7 && sudo ./build.sh```, which requires gcc. It will install in the ```/usr/bin/``` directory.

Then, you can simply build the image by running ```make```.
