# MichalOS

![Desktop screenshot](https://user-images.githubusercontent.com/41787099/112810298-291bd880-907b-11eb-8d70-37cf3e56b18a.png)

This project is essentially a beefed-up version of MikeOS 4.5. It includes high-end OS features, such as:
- Screensaver with customizable timeout
- Customizable user interface (custom background, window colors etc.)
- Custom font
- On-screen clock with timezone support
- AdLib synthesizer support
- Build-in graphics drawing functions

Even though all of these mind-blowing features are included, the system requirements are kept to a minimum:
- Intel 80386 or higher, Pentium recommended
- At least 80 kB RAM, 256 kB recommended
- An EGA video card, VGA recommended
- A keyboard

## Building instructions

### First-time setup

```
sudo ./misc/zx7/build.sh
```

This command compiles and installs a program for compressing files using the ZX7 standard.

### Building the image

```
make
```

Couldn't get any simpler than that. [nasm](https://www.nasm.us/) is required for assembling the OS.
