Commander X16 BASIC/KERNAL/DOS/GEOS ROM
=======================================

This is the Commander X16 ROM containing BASIC, KERNAL, DOS and GEOS. BASIC and KERNAL are derived from the [Commodore 64 versions](https://github.com/mist64/c64rom). GEOS is derived from the [C64/C128 version](https://github.com/mist64/geos).

* BASIC is fully compatible with Commodore BASIC V2, with some additions.
* KERNAL
	* supports the complete $FF81+ API.
	* adds lots of new API, including joystick, mouse and bitmap graphics.
	* supports the same $0300-$0332 vectors as the C64.
	* does not support tape (device 1) or software RS-232 (device 2).
* GEOS is fully compatible with the C64 version.
* DOS
	* is compatible with Commodore DOS (`$`, `SCRATCH`, `NEW`, ...).
	* works on SD cards with FAT32 filesystems.
	* supports long filenames, timestamps.
	* supports partitions and subdirectories (CMD-style).
* CodeX Interactive Assembly Environment
   * edit assembly code in RAM
   * save program, and debug information
   * run and debug assembly programs


Releases and Building
---------------------

<a href="https://travis-ci.org/commanderx16/x16-emulator"><img alt="Travis (.org)" src="https://img.shields.io/travis/commanderx16/x16-rom.svg?label=CI&logo=travis&logoColor=white&style=for-the-badge"></a>

Each [release of the X16 emulator][emu-releases] includes a compatible build of `rom.bin`. If you wish to build this yourself (perhaps because you're also building the emulator) see below.

> __WARNING:__ The emulator will currently work only with a contemporary version of `rom.bin`; earlier or later versions are likely to fail.

### Building the ROM

Building this source code requires only [GNU Make] and the [cc65] assembler. GNU Make is almost invariably available as a system package with any Linux distribution; cc65 less often so. 

- Red Hat/CentOS: `sudo yum install make cc65` 
- Debian/Ubuntu: `sudo apt-get install make cc65`

On macOS, cc65 in [homebrew](https://brew.sh/), which must be installed before issuing the following command:

- macOS: `brew install cc65`

If cc65 is not available as a package on your system, you'll need to install or build/install it per the instructions below.

Once the prerequisites are available, type `make` to build `rom.bin`. To use that with the emulator, copy it to the same directory as the `x16emu` binary or use `x16emu -rom .../path/to/rom.bin`.

*Additional Notes: For users of Red Hat Enterprise Linux 8, you will need to have CodeReady builder repositories enabled, for CentOS, this is called PowerTools. Additionally, you will need Fedora EPEL installed as well as cc65 does not come usually within the official repositories.*

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



Credits
-------

See [LICENSE.md](LICENSE.md)


Release Notes
-------------

### Release 41 ("Marrakech")

* KERNAL
	* keyboard
		* added 16 more keyboard layouts (28 total)
		* default layout ("ABC/X16") is now based on Macintosh "ABC - Extended" (full ISO-8859-15, no dead keys)
		* "keymap" API to activate a built-in keyboard layout
		* custom keyboard layouts can be loaded from disk (to $0:$A000)
		* Caps key behaves as expected
		* support for Shift+AltGr combinations
		* support for dead keys (e.g. ^ + e = ê)
		* PgUp/PgDown, End, Menu and Del generate PETSCII codes
		* Numpad support
		* Shift+Alt toggles between charsets (like C64)
		* Editor: "End" will position cursor on last line
	* VERA source/target support for `memory_fill`, `memory_copy`, `memory_crc`, `memory_decompress` [with PG Lewis]
	* fixed headerless load for verify/VRAM cases [Mike Ketchen]
	* don't reset screen colors on mode switch
* BASIC:
	* `BLOAD`, `BVLOAD` and `BVERIFY` commands for header-less loading [ZeroByteOrg]
	* `KEYMAP` command to change keyboard layout
	* support `DOS8`..`DOS31` (and `A=9:DOSA` etc.) to switch default device
	* `MOUSE` and `SCREEN` accept -1 as argument (was: $FF)
	* Changed auto-boot filename from `AUTOBOOT.X16*` to `AUTOBOOT.X16`
* Monitor:
	* fixed RMB/SMB disassembly
* Charset:
	* X16 logo included in ISO charset, code $AD, Shift+Alt+k in ISO mode

### Release 40 ("Bonn")

* KERNAL
	* Features
		* NMI & BRK will enter monitor
		* added ':' to some F-key replacements
		* allow scrolling screen DOWN: `PRINTCHR$($13)CHR$($91)`
		* Serial Bus works on hardware
	* Bugs
		* fixed SA during LOAD
		* fixed joystick routine messing with PS/2 keyboard [Natt Akuma]
	* API
		* keyhandler vector ($032E/$032F) doesn't need to return Z
		* PLOT API will clear cursor
* BASIC
		* on RESET, runs PRG starting with "AUTOBOOT.X16" from device 8 (N.B.: on host fs, name it "AUTOBOOT.X16*" for now!)
		* BOOT statement with the same function
* DOS
	* better detection of volume label
	* fixed `$=P` (list partitions), `$*=P`/`D` (dir filtering), hidden files
* MONITOR
	* fixed F3/F5 and CSR UP/DOWN auto-scrolling
	* fixed LOAD, SAVE, @
* CodeX
	* works this time! [mjallison42]

### Release 39 ("Buenos Aires")

* KERNAL
	* Adaptation to match Proto 2 Hardware
		* support for 4 SNES controllers
		* 512 KB ROM instead of 128 KB
		* new I/O layout
		* PS/2 and SNES controller GPIOs layout
		* banking through $00 and $01
	* Proto 2 Hardware Features
		* I2C bus (driver by Dieter Hauer, 2-clause BSD)
		* SMC: reset and shutdown support
		* RTC: DA$/TI$ and KERNAL APIs bridge to real-time-clock
	* Screen Features
		* New screen_mode API allows setting and getting current mode and resolution
		* support for 320x240 framebuffer (mode $80/128) [with gaekwad]
		* added 80x30,40x60,40x30,40x15,20x30,20x15 text modes (note new numbers!)
	* Keyboard Features
		* added KERNAL vector to allow intercepting PS/2 codes [Stefan B Jakobsson]
		* added kbdbuf_peek, kbdbuf_get_modifiers, kbdbuf_put API
	* Other Features
		* support for LOADing files without 2-byte PRG header [Elektron72]
		* support for LOAD into banked RAM (acptr and macptr)
		* support BEL code (PRINT CHR$(7))
		* keyboard joystick (joystick 0) supports all SNES buttons
		* support for 4 SNES controllers (joystick 1-4) [John J Bliss]
	* Bugs
		* fixed crash in FB_set_pixels for count>255 [Irmen de Jong]
		* fixed bank switching macros [Stephen Horn]
		* fixed preserving P in JSRFAR [CasaDeRobison]
		* fixed race condition in joystick_get [Elektron72]
		* removed ROM banking limitations from JSRFAR and FETVEC [Elektron72, Stefan B Jakobsson]
		* fixed disabling graphics layer when returning to text mode [Jaxartes]
		* fixed default cursor color when switching to text mode
		* reliable mouse_config support for screen sizes
* Math
	* renamed "fplib" to "math"
	* made Math package compatible with C128/C65, but fixing FADDT, FMULTT, FDIVT, FPWRT
* BASIC
	* Features
		* added BIN$ & HEX$ functions [Jimmy Dansbo]
		* added LOCATE statement
	* Bugs/Optimizations
		* removed extra space from BASIC error messages [Elektron72]
		* fixed DA$ and TI$ when accessed together or with BIN$()/HEX$() [Jaxartes]
		* fixed null handling in GET/READ/INPUT [Jaxartes]
		* fixed bank setting in VPOKE and VPEEK [Jaxartes]
		* fixed optional 'color' argument parsing for LINE, FRAME, RECT
* DOS
	* reliable memory initialization
	* fixed writing LFN directory entries across sector boundary
	* fixed missing partitions ($=P) if type is $0B
	* fixed loading to the passed-in address when SA is 0 [gaekwad]
	* fixed problem where macptr would always return C=0, masking errors
* GEOS
	* text input support
* CodeX
	* integrated CodeX Interactive Assembly Environment into ROM [mjallison42]

### Release 38 ("Kyoto")

* KERNAL
	* new `macptr` API to receive multiple bytes from an IEEE device
	* `load` uses `macptr` for LOAD speeds from SD card of about 140 KB/sec
	* hacked (non-functional) Commodore Serial to not hang
	* LOAD on IEEE without fn defaults to ":*"; changed F5 key to "LOAD"
	* fixed `screen_set_charset` custom charset [Rebecca G. Bettencourt]
	* fixed `stash` to preserve A
	* `entropy_get`: better entropy
* MATH
	* optimized addition, multiplication and SQR [Michael Jørgensen]
	* ported over `INT(.9+.1)` = 0 fix from C128
* BASIC
	* updated power-on logo to match the real X16 logo better
	* like LOAD/SAVE, OPEN now also defaults to last IEEE device (or 8)
	* fixed STOP key when showing directory listing (`DOS"$"`)
* CHARSET
	* changed PETSCII screen codes $65/$67 to PET 1/8th blocks
* DOS
	* switched to FAT32 library by Frank van den Hoef
	* rewrote most of DOS ("CMDR-DOS"), almost CMD FD/HD feature parity
		* write support
		* new "modify" mode ("M") that allows reading and writing
		* set-position support in PRG files (like sd2iec)
		* long filenames, full ISO-8859-15 translation
		* wildcards
		* subdirectories
		* partitions
		* timestamps
		* overwriting ("@:")
		* directory listing filter
		* partition listing
		* almost complete set of commands ("scratch", "rename", ...)
		* formatting a new filesystem ("new")
		* activity/error LED
		* detection of SD card presence, fallback to Commodore Serial
		* support for switching SD cards
		* details in the [CMDR-DOS README](https://github.com/commanderx16/x16-rom/blob/master/dos/README.md)
	* misc fixes [Mike Ketchen]

### Release 37 ("Geneva")

* API features
	* console
		* new: console_put_image (inline images)
		* new: console_set_paging_message (to pause after a full screen)
		* now respects window insets
		* try "TEST1" and "TEST2" in BASIC!
	* new entropy_get API to get randomness, used by MATH/BASIC RND function
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
