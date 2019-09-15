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
	# C64
	ca65 -g -DC64 -o basic/basic-c64.o basic/basic.s
	ca65 -g -DC64 $(VERSION_DEFINE) -o kernal/kernal-c64.o kernal/kernal.s
	ld65 -C rom-c64.cfg -o rom-c64.bin basic/basic-c64.o kernal/kernal-c64.o -Ln rom-c64.txt
	dd if=rom-c64.bin of=basic-c64.bin bs=8k count=1
	dd if=rom-c64.bin of=kernal-c64.bin bs=8k skip=1 count=1

	#x16
	ca65 $(ARGS_BASIC) -DPS2 $(VERSION_DEFINE) -o basic/basic.o basic/basic.s

	ca65 $(ARGS_KERNAL) -g -DPS2 -DCBDOS $(VERSION_DEFINE) -o kernal/kernal.o kernal/kernal.s

	ca65 $(ARGS_MONITOR) -DMACHINE_X16=1 -DCPU_65C02=1 monitor/monitor.s -o monitor/monitor.o

	ca65 $(ARGS_DOS) -o cbdos/fat32.o cbdos/fat32.asm
	ca65 $(ARGS_DOS) -o cbdos/util.o cbdos/util.asm
	ca65 $(ARGS_DOS) -o cbdos/matcher.o cbdos/matcher.asm
	ca65 $(ARGS_DOS) -o cbdos/sdcard.o cbdos/sdcard.asm
	ca65 $(ARGS_DOS) -o cbdos/spi_r_byte.o cbdos/spi_r_byte.s
	ca65 $(ARGS_DOS) -o cbdos/spi_rw_byte.o cbdos/spi_rw_byte.s
	ca65 $(ARGS_DOS) -o cbdos/spi_select_device.o cbdos/spi_select_device.s
	ca65 $(ARGS_DOS) -o cbdos/spi_deselect.o cbdos/spi_deselect.s
	ca65 $(ARGS_DOS) -o cbdos/main.o cbdos/main.asm

	ca65 -o keymap/keymap.o keymap/keymap.s

	ld65 -C rom.cfg -o rom.bin basic/basic.o kernal/kernal.o monitor/monitor.o cbdos/fat32.o cbdos/util.o cbdos/matcher.o cbdos/sdcard.o cbdos/spi_r_byte.o cbdos/spi_rw_byte.o cbdos/spi_select_device.o cbdos/spi_deselect.o cbdos/main.o keymap/keymap.o -Ln rom.txt -m rom-map.txt

clean:
	rm -f basic/basic-c64.o kernal/kernal-c64.o rom-c64.bin basic-c64.bin kernal-c64.bin
	rm -f basic/basic.o kernal/kernal.o rom.bin
	rm -f monitor/monitor.o monitor/monitor_support.o
	rm -f cbdos/*.o
	rm -f keymap/keymap.o
