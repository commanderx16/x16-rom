# Commander X16 BASIC and KERNAL Source

This repository contains the Commander X16 BASIC and KERNAL source. It is derived from the [C64 version](https://github.com/mist64/c64rom) with all original symbols and comments intact.

## Building

* Requires
	* [cc65](https://github.com/cc65/cc65).
	* make
* Use `make` to build.
* The resulting file is `rom.bin` (`$C000`-`$BFFF`)
	
## Philosophy

* The KERNAL must be as compatible with a C64 as a C64 is with e.g. a Plus/4. It supports [all calls from $FF81 on](https://www.pagetable.com/?p=926).
* BASIC should be unchanged in its behavior compared to BASIC V2.
* The zeropage layout should be the same as on the C64.

## Credits

Michael Steil <mist64@mac.com>, [www.pagetable.com](https://www.pagetable.com/)
