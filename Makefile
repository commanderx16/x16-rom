ifdef RELEASE_VERSION
	VERSION_DEFINE="-DRELEASE_VERSION=$(RELEASE_VERSION)"
endif
ifdef PRERELEASE_VERSION
	VERSION_DEFINE="-DPRERELEASE_VERSION=$(PRERELEASE_VERSION)"
endif

ARGS_KERNAL=-g
ARGS_BASIC=-g
#ARGS_MONITOR=-g
#ARGS_DOS=-g


all:
	#x16
	ca65 $(ARGS_BASIC) -DPS2 $(VERSION_DEFINE) -o basic/basic.o basic/basic.s

	ca65 $(ARGS_KERNAL) -g -DPS2 -DCBDOS $(VERSION_DEFINE) -o kernal/kernal.o kernal/kernal.s

	ca65 $(ARGS_MONITOR) -DMACHINE_X16=1 -DCPU_65C02=1 monitor/monitor.s -o monitor/monitor.o

	ca65 $(ARGS_DOS) -o cbdos/fat32.o cbdos/fat32.asm
	ca65 $(ARGS_DOS) -o cbdos/util.o cbdos/util.asm
	ca65 $(ARGS_DOS) -o cbdos/matcher.o cbdos/matcher.asm
	ca65 $(ARGS_DOS) -o cbdos/sdcard.o cbdos/sdcard.asm
	ca65 $(ARGS_DOS) -o cbdos/spi_rw_byte.o cbdos/spi_rw_byte.s
	ca65 $(ARGS_DOS) -o cbdos/spi_select_device.o cbdos/spi_select_device.s
	ca65 $(ARGS_DOS) -o cbdos/spi_deselect.o cbdos/spi_deselect.s
	ca65 $(ARGS_DOS) -o cbdos/main.o cbdos/main.asm

	ca65 -o keymap/keymap.o keymap/keymap.s

	ca65 -o charset/charset.o charset/charset.s
	(cd charset; bash convert.sh)
	ca65 -o charset/iso-8859-15.o charset/iso-8859-15.tmp.s

	ld65 -C rom.cfg -o rom.bin basic/basic.o kernal/kernal.o monitor/monitor.o cbdos/fat32.o cbdos/util.o cbdos/matcher.o cbdos/sdcard.o cbdos/spi_rw_byte.o cbdos/spi_select_device.o cbdos/spi_deselect.o cbdos/main.o keymap/keymap.o charset/charset.o charset/iso-8859-15.o -Ln rom.txt

clean:
	rm -f basic/basic.o kernal/kernal.o rom.bin
	rm -f monitor/monitor.o monitor/monitor_support.o
	rm -f cbdos/*.o
	rm -f keymap/keymap.o
	rm -f charset/charset.o charset/iso-8859-15.o charset/iso-8859-15.tmp.s
