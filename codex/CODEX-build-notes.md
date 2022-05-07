Build notes for CodeX 
=====================

The CodeX Interactive Assembly Environment ROM mode allows the user to:

* edit assembly code in RAM
* save program, and debug information
* run and debug assembly programs

This note details a few items for someone building their own ROM. 

Generally CodeX will build as normal and be compiled into the proper ROM segment when you build the entire respository. 

CodeX provides most of its functionality in the ROM code, but some extra functionality is included with "plugins". These plugins are loaded from the default disk (8) at runtime. The functional pieces are:

* cx-dc - "Decompiler", which allows you to save your program as a text file. This functionality is accessed via function keys FILE -> TEXT.
* cx-sym - "Symbol viewer", allows you to view and edit labels and symbols. This functionality is accessed via function keys VIEW -> SYMB.

CodeX also has some example programs:

* HW.PRG (and debug files) - Hello World
* X16SKEL.PRG (and debug files) - Simple do nothing program but it provides a simple string print routine and defines label values for the zero page registers. 

Example programs and plugins can be bundled together after building the ROM. The Makefile requires that you have previously installed the [MTools package](https://www.gnu.org/software/mtools/). Use the following to create the special CODEX SDCard image.

	cd x16-rom/codex
	make codex.img

You can use this image with the Commander 16 emulator, using the `-sdcard` command line option. For use with physical hardware, copy all the elements of the CodeX disk image into your physical SDCard and restart your machine.

The rule to create codex.img is not run by default.
