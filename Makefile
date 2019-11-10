ifdef RELEASE_VERSION
	VERSION_DEFINE="-DRELEASE_VERSION=$(RELEASE_VERSION)"
endif
ifdef PRERELEASE_VERSION
	VERSION_DEFINE="-DPRERELEASE_VERSION=$(PRERELEASE_VERSION)"
endif

AS           = ca65
LD           = ld65

ARGS_KERNAL=-g
ARGS_BASIC=-g
#ARGS_MONITOR=-g
#ARGS_DOS=-g
#ARGS_GEOS=-g


ASFLAGS      = -I geos/inc -I geos -g

GEOS_SOURCES= \
	geos/kernal/bitmask/bitmask2.s \
	geos/kernal/conio/conio1.s \
	geos/kernal/conio/conio2.s \
	geos/kernal/conio/conio3a.s \
	geos/kernal/conio/conio4.s \
	geos/kernal/conio/conio6.s \
	geos/kernal/dlgbox/dlgbox1a.s \
	geos/kernal/dlgbox/dlgbox1b.s \
	geos/kernal/dlgbox/dlgbox1c.s \
	geos/kernal/dlgbox/dlgbox1d.s \
	geos/kernal/dlgbox/dlgbox1e1.s \
	geos/kernal/dlgbox/dlgbox1e2.s \
	geos/kernal/dlgbox/dlgbox1f.s \
	geos/kernal/dlgbox/dlgbox1g.s \
	geos/kernal/dlgbox/dlgbox1h.s \
	geos/kernal/dlgbox/dlgbox1i.s \
	geos/kernal/dlgbox/dlgbox1j.s \
	geos/kernal/dlgbox/dlgbox1k.s \
	geos/kernal/dlgbox/dlgbox2.s \
	geos/kernal/files/files10.s \
	geos/kernal/files/files1a2a.s \
	geos/kernal/files/files1a2b.s \
	geos/kernal/files/files1b.s \
	geos/kernal/files/files2.s \
	geos/kernal/files/files3.s \
	geos/kernal/files/files6a.s \
	geos/kernal/files/files6b.s \
	geos/kernal/files/files6c.s \
	geos/kernal/files/files7.s \
	geos/kernal/files/files8.s \
	geos/kernal/graph/clrscr.s \
	geos/kernal/graph/inlinefunc.s \
	geos/kernal/graph/graphicsstring.s \
	geos/kernal/graph/graph2l1.s \
	geos/kernal/graph/pattern.s \
	geos/kernal/graph/inline.s \
	geos/kernal/header/header.s \
	geos/kernal/hw/hw1a.s \
	geos/kernal/hw/hw1b.s \
	geos/kernal/hw/hw2.s \
	geos/kernal/hw/hw3.s \
	geos/kernal/icon/icon1.s \
	geos/kernal/icon/icon2.s \
	geos/kernal/init/init1.s \
	geos/kernal/init/init2.s \
	geos/kernal/init/init3.s \
	geos/kernal/init/init4.s \
	geos/kernal/irq/irq.s \
	geos/kernal/jumptab/jumptab.s \
	geos/kernal/keyboard/keyboard1.s \
	geos/kernal/keyboard/keyboard2.s \
	geos/kernal/keyboard/keyboard3.s \
	geos/kernal/load/deskacc.s \
	geos/kernal/load/load1a.s \
	geos/kernal/load/load1b.s \
	geos/kernal/load/load1c.s \
	geos/kernal/load/load2.s \
	geos/kernal/load/load3.s \
	geos/kernal/load/load4b.s \
	geos/kernal/mainloop/mainloop1.s \
	geos/kernal/mainloop/mainloop3.s \
	geos/kernal/math/shl.s \
	geos/kernal/math/shr.s \
	geos/kernal/math/muldiv.s \
	geos/kernal/math/neg.s \
	geos/kernal/math/dec.s \
	geos/kernal/math/random.s \
	geos/kernal/math/crc.s \
	geos/kernal/memory/memory1a.s \
	geos/kernal/memory/memory1b.s \
	geos/kernal/memory/memory2.s \
	geos/kernal/memory/memory3.s \
	geos/kernal/menu/menu1.s \
	geos/kernal/menu/menu2.s \
	geos/kernal/menu/menu3.s \
	geos/kernal/misc/misc.s \
	geos/kernal/mouse/mouse1.s \
	geos/kernal/mouse/mouse2.s \
	geos/kernal/mouse/mouse3.s \
	geos/kernal/mouse/mouse4.s \
	geos/kernal/mouse/mouseptr.s \
	geos/kernal/panic/panic.s \
	geos/kernal/patterns/patterns.s \
	geos/kernal/process/process1.s \
	geos/kernal/process/process2.s \
	geos/kernal/process/process3a.s \
	geos/kernal/process/process3aa.s \
	geos/kernal/process/process3b.s \
	geos/kernal/process/process3c.s \
	geos/kernal/reu/reu.s \
	geos/kernal/serial/serial1.s \
	geos/kernal/serial/serial2.s \
	geos/kernal/sprites/sprites.s \
	geos/kernal/time/time1.s \
	geos/kernal/time/time2.s \
	geos/kernal/tobasic/tobasic2.s \
	geos/kernal/vars/vars.s \
	geos/kernal/start/start64.s \
	geos/kernal/bitmask/bitmask1.s \
	geos/kernal/bitmask/bitmask3.s \
	geos/kernal/bswfont/bswfont.s \
	geos/kernal/conio/conio3b.s \
	geos/kernal/conio/conio5.s \
	geos/kernal/files/files9.s \
	geos/kernal/fonts/fonts1.s \
	geos/kernal/fonts/fonts2.s \
	geos/kernal/fonts/fonts3.s \
	geos/kernal/fonts/fonts4.s \
	geos/kernal/fonts/fonts4a.s \
	geos/kernal/fonts/fonts4b.s \
	geos/kernal/graph/bitmapclip.s \
	geos/kernal/graph/bitmapup.s \
	geos/kernal/graph/line.s \
	geos/kernal/graph/point.s \
	geos/kernal/graph/rect.s \
	geos/kernal/graph/scanline.s \
	geos/kernal/mainloop/mainloop2.s \
	geos/kernal/ramexp/ramexp1.s \
	geos/kernal/ramexp/ramexp2.s \
	geos/kernal/rename.s \
	geos/kernal/tobasic/tobasic1.s \
	geos/kernal/drvcbdos.s

DEPS= \
	geos/config.inc \
	geos/inc/c64.inc \
	geos/inc/const.inc \
	geos/inc/diskdrv.inc \
	geos/inc/geosmac.inc \
	geos/inc/geossym.inc \
	geos/inc/inputdrv.inc \
	geos/inc/jumptab.inc \
	geos/inc/kernal.inc \
	geos/inc/printdrv.inc

GEOS_OBJS=$(GEOS_SOURCES:.s=.o)

GEOS_BUILD_DIR=build

PREFIXED_GEOS_OBJS = $(addprefix $(GEOS_BUILD_DIR)/, $(GEOS_OBJS))

$(GEOS_BUILD_DIR)/%.o: %.s
	@mkdir -p `dirname $@`
	$(AS) $(ARGS_GEOS) -D bsw=1 -D drv1541=1 $(ASFLAGS) $< -o $@

all: $(PREFIXED_GEOS_OBJS)
	$(AS) -o kernsup/kernsup.o kernsup/kernsup.s
	$(AS) -o kernsup/irqsup.o kernsup/irqsup.s

	$(AS) $(ARGS_BASIC) $(VERSION_DEFINE) -o basic/basic.o basic/basic.s

	$(AS) $(ARGS_BASIC) $(VERSION_DEFINE) -o fplib/fplib.o fplib/fplib.s

	$(AS) $(ARGS_KERNAL) -g -DCBDOS $(VERSION_DEFINE) -o kernal/kernal.o kernal/kernal.s

	$(AS) $(ARGS_MONITOR) -DMACHINE_X16=1 -DCPU_65C02=1 monitor/monitor.s -o monitor/monitor.o

	$(AS) $(ARGS_DOS) -o cbdos/zeropage.o cbdos/zeropage.s
	$(AS) $(ARGS_DOS) -o cbdos/fat32.o cbdos/fat32.asm
	$(AS) $(ARGS_DOS) -o cbdos/util.o cbdos/util.asm
	$(AS) $(ARGS_DOS) -o cbdos/matcher.o cbdos/matcher.asm
	$(AS) $(ARGS_DOS) -o cbdos/sdcard.o cbdos/sdcard.asm
	$(AS) $(ARGS_DOS) -o cbdos/spi_rw_byte.o cbdos/spi_rw_byte.s
	$(AS) $(ARGS_DOS) -o cbdos/spi_select_device.o cbdos/spi_select_device.s
	$(AS) $(ARGS_DOS) -o cbdos/spi_deselect.o cbdos/spi_deselect.s
	$(AS) $(ARGS_DOS) -o cbdos/main.o cbdos/main.asm

	$(AS) -o keymap/keymap.o keymap/keymap.s

	(cd charset; bash convert.sh)
	$(AS) -o charset/petscii.o charset/petscii.tmp.s
	$(AS) -o charset/iso-8859-15.o charset/iso-8859-15.tmp.s

	$(LD) -C rom.cfg -o rom.bin basic/basic.o fplib/fplib.o kernal/kernal.o monitor/monitor.o cbdos/zeropage.o cbdos/fat32.o cbdos/util.o cbdos/matcher.o cbdos/sdcard.o cbdos/spi_rw_byte.o cbdos/spi_select_device.o cbdos/spi_deselect.o cbdos/main.o keymap/keymap.o charset/petscii.o charset/iso-8859-15.o kernsup/kernsup.o kernsup/irqsup.o $(PREFIXED_GEOS_OBJS) -Ln rom.txt -m rom.map

clean:
	rm -f kernsup/*.o
	rm -f basic/basic.o fplib/fplib.o kernal/kernal.o rom.bin
	rm -f monitor/monitor.o monitor/monitor_support.o
	rm -f cbdos/*.o
	rm -f keymap/keymap.o
	rm -f charset/petscii.o charset/iso-8859-15.o charset/iso-8859-15.tmp.s
	rm -rf build
