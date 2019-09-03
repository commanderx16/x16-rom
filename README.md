# Commander X16 BASIC/KERNAL/DOS ROM

This is the Commander X16 ROM containing BASIC, KERNAL and DOS. BASIC and KERNAL are derived from the [Commodore 64 versions](https://github.com/mist64/c64rom).

* BASIC is fully compatible with Commodore BASIC V2.
* KERNAL
	* supports the complete $FF81+ API.
	* has the same zero page and $0200-$033C memory layout as the C64.
	* does not support tape (device 1).

## New Features

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

## Big TODOs

* DOS needs more features.
* BASIC needs more features.
* RS232 and IEC are not working.
* PS/2 and SD have issues on real hardware.

## ROM Map

* fixed ROM ($E000-$FFFF): KERNAL
* banked ROM ($C000-$DFFF):
	* bank 0: BASIC
	* bank 1: UTIL (monitor)
	* bank 2: DOS

## RAM Map

* fixed RAM:
	* $0000-$0400 KERNAL/BASIC/DOS system variables
	* $0400-$0800 currently unused
	* $0800-$9F00 BASIC RAM
* banked RAM:
	* banks 0-254: free for applications
	* bank 255: DOS buffers and variables


## Credits

This version is maintained by Michael Steil &lt;mist64@mac.com&gt;, [www.pagetable.com](https://www.pagetable.com/)
