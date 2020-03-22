Commander X16 BASIC/KERNAL/DOS/GEOS ROM
=======================================

This is the Commander X16 ROM containing BASIC, KERNAL, DOS and GEOS. BASIC and KERNAL are derived from the [Commodore 64 versions](https://github.com/mist64/c64rom). GEOS is derived from the [C64/C128 version](https://github.com/mist64/geos).

* BASIC is fully compatible with Commodore BASIC V2.
* KERNAL
	* supports the complete $FF81+ API.
	* has the same zero page and $0200-$033C memory layout as the C64.
	* does not support tape (device 1).
* GEOS is fully compatible with the C64 version.


Releases and Building
---------------------

<a href="https://travis-ci.org/commanderx16/x16-emulator"><img alt="Travis (.org)" src="https://img.shields.io/travis/commanderx16/x16-rom.svg?label=CI&logo=travis&logoColor=white&style=for-the-badge"></a>

Each [release of the X16 emulator][emu-releases] includes a compatible build of `rom.bin`. If you wish to build this yourself (perhaps because you're also building the emulator) see below.

> __WARNING:__ The emulator will currently work only with a contemporary version of `rom.bin`; earlier or later versions are likely to fail.

### Building the ROM

Building this source code requires only [GNU Make] and the [cc65] assembler. GNU Make is almost invariably available as a system package with any Linux distribution; cc65 less often so. 

- Red Hat: `sudo yum install make cc65`
- Debian: `sudo apt-get install make`

On macOS, cc65 in [homebrew](https://brew.sh/), which must be installed before issuing the following command:

- macOS: `brew install cc65`

If cc65 is not available as a package on your system, you'll need to install or build/install it per the instructions below.

Once the prerequisites are available, type `make` to build `rom.bin`. To use that with the emulator, copy it to the same directory as the `x16emu` binary or use `x16emu -rom .../path/to/rom.bin`.

### Building/Installing cc65

#### Linux Builds from Source

You'll need the basic set of tools for building C programs:
- Debian/Ubuntu: `sudo apt-get install build-essential git`

The cc65 source is [on GitHub][cc65]; clone and build it with:

    git clone https://github.com/cc65/cc65.git
    make -j4    # -j4 may be left off; it merely speeds the build

This will leave the binaries in the `bin/` subdirectory; you may use thes directly by adding them to your path, or install them to a standard directory:

    #   This assumes you have ~/.local/bin in your path.
    make install PREFIX=~/.local

#### Building and Packages for Other Systems

Consult the Nesdev Wiki [Installing CC65][nd-cc65] page for some hints, including Windows installs. However, the Debian packages they suggest from [trikaliotis.net] appear to have signature errors.


New Features
------------

* F-keys:
	F1: `LIST`
	F2: `MONITOR`
	F3: `RUN`
	F4: &lt;switch 40/80&gt;
	F5: `LOAD`
	F6: `SAVE"`
	F7: `DOS"$`
	F8: `DOS`
* New BASIC instructions
	* `MONITOR`: see below.
	* `DOS`:
	no argument: read disk status.
	"8" or "9" as an argument: switch default drive.
	"$" as an argument: show directory.
	all other arguments: send DOS command
	* `VPEEK`(bank, offset), `VPOKE` bank, offset, value to access video memory. "offset" is 16 bits, "bank" is bits 16-19 of the linear address.
	Note that the tokens for the new BASIC commands have not been finalized yet, so loading a BASIC program that uses the new keywords in a future version of the ROM will break!
* Support for `$` and `%` in BASIC expressions for hex and binary
* `LOAD` prints the start and end(+1) addresses
* Integrated Monitor derived from the [Final Cartridge III](https://github.com/mist64/final_cartridge).
	* `O00`..`OFF` to switch ROM and RAM banks
	* `OV0`..`OV4` to switch to video address space
* FAT32-formatted SD card as drive 8 as a full IEC (TALK/LISTEN & CBM DOS) compatible device:
	* read directory
	* load file
	* send "I" command
	* read status
	* everything else is unimplemented
* Some new KERNAL APIs (to be documented)


Big TODOs
---------

* DOS needs more features.
* BASIC needs more features.
* IEC is not working.
* PS/2 and SD have issues on real hardware.


ROM Map
-------

|Bank|Name   |Description                                            |
|----|-------|-------------------------------------------------------|
|0   |KERNAL |character sets (uploaded into VRAM), MONITOR, KERNAL   |
|1   |KEYBD  |Keyboard layout tables                                 |
|2   |CBDOS  |The computer-based CBM-DOS for FAT32 SD cards          |
|3   |GEOS   |GEOS KERNAL                                            |
|4   |BASIC  |BASIC interpreter                                      |
|5-7 |–      |*[Currently unused]*                                   |


RAM Map
-------

* fixed RAM:
	* $0000-$0400 KERNAL/BASIC/DOS system variables
	* $0400-$0800 currently unused
	* $0800-$9F00 BASIC RAM
* banked RAM:
	* banks 0-254: free for applications
	* bank 255: DOS buffers and variables


Credits
-------

* All new code, and additions to legacy code: &copy;2020 Michael Steil, [www.pagetable.com](https://www.pagetable.com/); 2-clause BSD license
* FAT32 and SD card drivers: &copy;2018 Thomas Woinke, Marko Lauke, [www.steckschein.de](https://steckschwein.de); MIT License
* `kernal/open-roms`: &copy;2019 Paul Gardner-Stephen, 2019; GPLv3 license
* `kernal/cbm`: &copy;1983 Commodore Business Machines (CBM)
* `basic`: &copy;1977 Microsoft Corp.
* `geos`: &copy;1985 Berlekey Softworks



Release Notes
-------------

### Release 37 ("Geneva")

* API features
	* console
		* new: console_put_image (inline images)
		* new: console_set_paging_message (to pause after a full screen)
		* now respects window insets
		* try "TEST1" and "TEST2" in BASIC!
	* new entropy_get API to get randomness, used by FPLIB/BASIC RND function
* KERNAL
	* support for VERA 0.9 register layout (Frank van den Hoef)
* BASIC
	* TI$ and DA$ (DATE$) are now connected to the new date/time API
	* TI is independent of TI$ and can be assigned
* DOS
	* enabled partition types 0x0b and 0x0c, should accept more image types
* Build
	* separated KERNAL code into core code and drivers
	* support for building KERNAL for C64
	* ROM banks are built independently
	* support to replace CBM channel and editor code with GPLed "open-roms" code by the MEGA65 project
* bug fixes
	* LOAD respects target address
	* FAT32 code no longer overwrites RAM
	* monitor is not as broken any more

### Release 36 ("Berlin")

* API Features
	* added console API for text-based interfaces with proportional font and styles support: console_init, console_put_char, console_get_char
	* added memory API:
		* memory_fill
		* memory_copy
		* memory_crc
		* memory_decompress (LZSA2)
	* added sprite API: sprite_set_image, sprite_set_position
	* renamed GRAPH_LL to FB (framebuffer)
	* GRAPH_init takes an FB graphics driver as an argument

* KERNAL features
	* detect SD card on TALK and LISTEN, properly fall back to serial
	* joystick scanning is done automatically in VBLANK IRQ; no need to call it manually any more
	* added VERA UART driver (device 2)
	* bank 1 is now the default after startup; KERNAL won't touch it
	* sprites and layer 0 are cleared on RESET
	* changed F5 to LOAD":* (filename required for IEEE devices)
	* GRAPH_move_rect supports overlapping [gaekwad]

* BASIC
	* default LOAD/SAVE device is now 8
	* added RESET statement [Ingo Hinterding]
	* added CLS statement [Ingo Hinterding]

* CHARSET
	* fixed capital Ö [Ingo Hinterding]
	* Changed Û, î, ã to be more consistent [Ingo Hinterding]

* bug fixes
	* COLOR statement with two arguments
	* PEEK for ROM addresses
	* keyboard code no longer changes RAM bank
	* fixed clock update
	* fixed side effects of Ctrl+A and color control codes [codewar65]

* misc
	* added 3 more tests, start with "TEST1"/"TEST2"/"TEST3" in BASIC:
	* TEST0: existing misc graphics test
	* TEST1: console text rendering, character wrapping
	* TEST2: console text rendering, word wrapping
	* TEST3: console text input, echo

### Release 35

* API Fetures
	* new KERNAL API: low-level and high-level 320x200@256c bitmap graphics
	* new KERNAL API: get mouse state
	* new KERNAL API: get joystick state
	* new KERNAL API: get/set date and time (old RDTIM call is now a 24 bit timer)
	* new floating point API, jump table at $FC00 on ROM bank 4 (BASIC)

* KERNAL Features
	* invert fg/bg color control code (Ctrl+A) [Daniel Mecklenburg Jr]
	
* BASIC
	* added `COLOR <fg, bg>` statement to set text color
	* added `JOY(n)` function (arg 1 for joy1, arg 2 for joy2)
	* added `TEST` statement to start graphics API unit test
	* `CHAR` statement supports PETSCII control codes (instead of GEOS control codes), including color codes

* misc
	* KERNAL variables for keyboard/mouse/clock drivers were moved from $0200-$02FF to RAM bank #0
	* $8F (set PETSCII-UC even if ISO) printed first after reset [Mikael O. Bonnier]

* bug fixes:
	* got rid of $2c partial instruction skip [Joshua Scholar]
	* fixed TI/TI$
	* fixed CBDOS infinite loop
	* zp address 0 is no longer overwritten by mouse code
	* mouse scanning is disabled if mouse is off
	* VERA state is correctly saved/restored by IRQ code

### Release 34

* new layout for zero page and KERNAL/BASIC variables:
	* $00-$7F available to the user
	* ($02-$52 are used if using BASIC graphics commands)
	* $80-$A3 used by KERNAL and DOS
	* $A4-$A8 reserved for KERNAL/DOS/BASIC
	* $A9-$FF used by BASIC
* new BASIC statements:
	* `SCREEN <mode>` (0: 40x30, 2: 80x60, 128: graphics)
	* `PSET <x>, <y>, <color>`
	* `LINE <x1>, <y1>, <x2>, <y2>, <color>`
	* `FRAME <x1>, <y1>, <x2>, <y2>, <color>`
	* `RECT <x1>, <y1>, <x2>, <y2>, <color>`
	* `CHAR <x>, <y>, <color>, <string>`
	* `MOUSE <n>` (0: off, 1: on)
* new BASIC functions:
	* `MX` (mouse X coordinate)
	* `MY` (mouse Y coordinate)
	* `MB` (mouse button; 1: left, 2: right, 4: third)
* new KERNAL calls:
	* `MOUSE`: configure mouse
	* `SCRMOD`: set screen mode
* new PS/2 mouse driver
* charsets are uploaded to VERA on demand
* GEOS font rendering uses less slant for faux italics characters
* misc GEOS KERNAL improvements and optimizations

### Release 33

* BASIC
	* additional LOAD syntax to load to a specific address `LOAD [filename[,device[,bank,address]]]`
	* LOAD into banked RAM will auto-wrap into successive banks
	* LOAD allows trailing garbage; great to just type `LOAD` into a directory line [John-Paul Gignac]
	* new BASIC statement: `VLOAD` to load into video RAM: `VLOAD [filename[,device[,bank,address]]]` [John-Paul Gignac]
	* complete jump table bridge
* KERNAL: memory size detection
* KERNAL: faster IRQ entry
* GEOS: converted graphics library to VERA 320x200@256c

### Release 32

* correct ROM banking:
	* BASIC and KERNAL now live on separate 16 KB banks ($C000-$FFFF)
	* BASIC `PEEK` will always access KERNAL ROM
	* BASIC `SYS` will have BASIC ROM enabled
* added GEOS
* added `OLD` statement to recover deleted BASIC program after `NEW` or `RESET`
* removed software RS-232, will be replaced by VERA UART later
* Full ISO mode support in Monitor

### Release 31

* switched to VERA 0.8 register layout; character ROM is uploaded on startup
* ISO mode: ISO-8859-15 character set, standard ASCII keyboard
* keyboard
	* completed US and UK keymaps so all C64 characters are reachable
	* support for AltGr
	* support for F9-F12
* allow hex and binary numbers in `DATA` statements [Frank Buss]
* switched SD card from VIA SPI to VERA SPI (works on real hardware!)
* fix: `VPEEK` overwriting `POKER` ($14/$15)
* fix: `STOP` sometimes not registering in BASIC programs

### Release 30

* support for 13 keyboard layouts; cycle through them using F9
* `GETJOY` call will fall back to keyboard (cursor/Ctrl/Alt/Space/Return), see Programmer's Reference Guide on how to use it
* startup message now shows ROM revision
* $FF80 contains the prerelease revision (negated)
* the 60 Hz IRQ is now generated by VERA VSYNC
* fix: `VPEEK` tokenization
* fix: CBDOS was not correctly preserving the RAM bank
* fix: KERNAL no longer uses zero page $FC-$FE



<!-------------------------------------------------------------------->
[GNU Make]: https://www.gnu.org/software/make/
[cc65]: https://cc65.github.io/
[emu-releases]: https://github.com/commanderx16/x16-emulator/releases
[nd-cc65]: https://wiki.nesdev.com/w/index.php/Installing_CC65
[trikaliotis.net]: https://spiro.trikaliotis.net/debian