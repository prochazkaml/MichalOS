![MichalOS Logo](https://i.ibb.co/fkk1SYF/Capture.png)

A 16-bit keyboard controlled operating system based on MikeOS 4.5, aimed to be more advanced and lightweight on the inside, but simple and easy to use on the outside.

It includes high-end OS features, such as:
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

## Screenshots

![Demo Tour](https://a.fsdn.com/con/app/proj/michalos/screenshots/Screenshot%20from%202019-07-11%2020-50-09.png/max/max/1)
![Login Screen](https://a.fsdn.com/con/app/proj/michalos/screenshots/Screenshot%20from%202019-07-11%2020-50-20.png/max/max/1)
![Desktop](https://a.fsdn.com/con/app/proj/michalos/screenshots/Screenshot%20from%202019-07-11%2020-50-27.png/max/max/1)
![Main Menu](https://a.fsdn.com/con/app/proj/michalos/screenshots/Screenshot%20from%202018-07-29%2008-56-45.png/max/max/1)
![Clock](https://a.fsdn.com/con/app/proj/michalos/screenshots/Screenshot%20from%202020-05-21%2014-41-54.png/max/max/1)
![Music Player](https://a.fsdn.com/con/app/proj/michalos/screenshots/Screenshot%20from%202020-05-21%2014-42-18.png/max/max/1)

## Building instructions

### Requirements

- Unix based Operating System (Debian is preferred)
- DosBox (For testing live builds) ``` sudo apt install dosbox ```
- Nasm (For assembling the OS) ``` sudo apt install nasm ```
- Make (Makefile & make commands) ``` sudo apt install make ```

### First-time setup

```
sudo ./misc/zx7/build.sh
```

This command compiles and installs a program for compressing files using the ZX7 standard.

### Building the image

```
make
```
## License

MichalOS is licensed under the BSD License
