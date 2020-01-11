
MACHINE     ?= x16

AS           = ca65
LD           = ld65

ASFLAGS      = --cpu 65SC02 -g -D bsw=1 -D drv1541=1 -I geos/inc -I geos -D CPU_65C02=1 -D MACHINE_X16=1

BUILD_DIR=build/$(MACHINE)

KERNAL_SOURCES = \
	kernal/kernal.s \
	kernal/editor.s \
	kernal/kbdbuf.s \
	kernal/channel/channel.s \
	kernal/ieee_switch.s \
	kernal/serial.s \
	kernal/memory.s \
	kernal/lzsa.s \
	kernal/drivers/x16/x16.s \
	kernal/drivers/x16/memory.s \
	kernal/drivers/x16/screen.s \
	kernal/drivers/x16/ps2.s \
	kernal/drivers/x16/ps2kbd.s \
	kernal/drivers/x16/ps2mouse.s \
	kernal/drivers/x16/joystick.s \
	kernal/drivers/x16/clock.s \
	kernal/drivers/x16/rs232.s \
	kernal/drivers/x16/framebuffer.s \
	kernal/drivers/x16/sprites.s \
	kernal/graph/graph.s \
	kernal/console.s \
	kernal/fonts/fonts.s

KEYMAP_SOURCES = \
	keymap/keymap.s

CBDOS_SOURCES = \
	cbdos/zeropage.s \
	cbdos/fat32.s \
	cbdos/util.s \
	cbdos/matcher.s \
	cbdos/sdcard.s \
	cbdos/spi_rw_byte.s \
	cbdos/spi_select_device.s \
	cbdos/spi_deselect.s \
	cbdos/main.s

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
	geos/kernal/mainloop/mainloop.s \
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
	geos/kernal/process/process.s \
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
	geos/kernal/conio/conio5.s \
	geos/kernal/files/files9.s \
	geos/kernal/graph/bitmapclip.s \
	geos/kernal/graph/bitmapup.s \
	geos/kernal/graph/graph_bridge.s \
	geos/kernal/ramexp/ramexp1.s \
	geos/kernal/ramexp/ramexp2.s \
	geos/kernal/rename.s \
	geos/kernal/tobasic/tobasic1.s \
	geos/kernal/drvcbdos.s

BASIC_SOURCES= \
	kernsup/kernsup_basic.s \
	basic/basic.s \
	fplib/fplib.s

MONITOR_SOURCES= \
	kernsup/kernsup_monitor.s \
	monitor/monitor.s

CHARSET_SOURCES= \
	charset/petscii.s \
	charset/iso-8859-15.s \
	charset/copy.s


KERNAL_OBJS  = $(addprefix $(BUILD_DIR)/, $(KERNAL_SOURCES:.s=.o))
KEYMAP_OBJS  = $(addprefix $(BUILD_DIR)/, $(KEYMAP_SOURCES:.s=.o))
CBDOS_OBJS   = $(addprefix $(BUILD_DIR)/, $(CBDOS_SOURCES:.s=.o))
GEOS_OBJS    = $(addprefix $(BUILD_DIR)/, $(GEOS_SOURCES:.s=.o))
BASIC_OBJS   = $(addprefix $(BUILD_DIR)/, $(BASIC_SOURCES:.s=.o))
MONITOR_OBJS = $(addprefix $(BUILD_DIR)/, $(MONITOR_SOURCES:.s=.o))
CHARSET_OBJS = $(addprefix $(BUILD_DIR)/, $(CHARSET_SOURCES:.s=.o))

BANK_BINS = \
	$(BUILD_DIR)/kernal.bin \
	$(BUILD_DIR)/keymap.bin \
	$(BUILD_DIR)/cbdos.bin \
	$(BUILD_DIR)/geos.bin \
	$(BUILD_DIR)/basic.bin \
	$(BUILD_DIR)/monitor.bin \
	$(BUILD_DIR)/charset.bin

all: $(BANK_BINS)

clean:
	rm -rf $(BUILD_DIR)

$(BUILD_DIR)/%.s: %.stpl
	@mkdir -p $$(dirname $@)
	./convert_stpl.sh $< $@

$(BUILD_DIR)/%.o: %.s
	@mkdir -p $$(dirname $@)
	$(AS) $(ASFLAGS) $< -o $@


# Bank 0 : KERNAL
$(BUILD_DIR)/kernal.bin: $(KERNAL_OBJS) kernal-$(MACHINE).cfg
	@mkdir -p $$(dirname $@)
	$(LD) -C kernal-$(MACHINE).cfg $(KERNAL_OBJS) -o $@ -m $(BUILD_DIR)/kernal.map -Ln $(BUILD_DIR)/kernal.txt

# Bank 1 : KEYMAP
$(BUILD_DIR)/keymap.bin: $(KEYMAP_OBJS) keymap-$(MACHINE).cfg
	@mkdir -p $$(dirname $@)
	$(LD) -C keymap-$(MACHINE).cfg $(KEYMAP_OBJS) -o $@ -m $(BUILD_DIR)/keymap.map -Ln $(BUILD_DIR)/keymap.txt

# Bank 2 : CBDOS
$(BUILD_DIR)/cbdos.bin: $(CBDOS_OBJS) cbdos-$(MACHINE).cfg
	@mkdir -p $$(dirname $@)
	$(LD) -C cbdos-$(MACHINE).cfg $(CBDOS_OBJS) -o $@ -m $(BUILD_DIR)/cbdos.map -Ln $(BUILD_DIR)/cbdos.txt

# Bank 3 : GEOS
$(BUILD_DIR)/geos.bin: $(GEOS_OBJS) geos-$(MACHINE).cfg
	@mkdir -p $$(dirname $@)
	$(LD) -C geos-$(MACHINE).cfg $(GEOS_OBJS) -o $@ -m $(BUILD_DIR)/geos.map -Ln $(BUILD_DIR)/geos.txt

# Bank 4 : BASIC
$(BUILD_DIR)/basic.bin: $(BASIC_OBJS) basic-$(MACHINE).cfg
	@mkdir -p $$(dirname $@)
	$(LD) -C basic-$(MACHINE).cfg $(BASIC_OBJS) -o $@ -m $(BUILD_DIR)/basic.map -Ln $(BUILD_DIR)/basic.txt

# Bank 5 : MONITOR
$(BUILD_DIR)/monitor.bin: $(MONITOR_OBJS) monitor-$(MACHINE).cfg
	@mkdir -p $$(dirname $@)
	$(LD) -C monitor-$(MACHINE).cfg $(MONITOR_OBJS) -o $@ -m $(BUILD_DIR)/monitor.map -Ln $(BUILD_DIR)/monitor.txt

# Bank 6 : CHARSET
$(BUILD_DIR)/charset.bin: $(CHARSET_OBJS) charset-$(MACHINE).cfg
	@mkdir -p $$(dirname $@)
	$(LD) -C charset-$(MACHINE).cfg $(CHARSET_OBJS) -o $@ -m $(BUILD_DIR)/charset.map -Ln $(BUILD_DIR)/charset.txt









ifdef RELEASE_VERSION
	VERSION_DEFINE="-DRELEASE_VERSION=$(RELEASE_VERSION)"
endif
ifdef PRERELEASE_VERSION
	VERSION_DEFINE="-DPRERELEASE_VERSION=$(PRERELEASE_VERSION)"
endif

AS           = ca65
LD           = ld65

ARGS_KERNAL=-DX16 --cpu 65SC02 -g
ARGS_BASIC=-DX16 --cpu 65SC02 -g
ARGS_MONITOR=-DX16 --cpu 65SC02 -g
ARGS_DOS=#-g
ARGS_GEOS=-DX16 #-g




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


PREFIXED_GEOS_OBJS = $(addprefix $(GEOS_BUILD_DIR)/, $(GEOS_OBJS))

x$(GEOS_BUILD_DIR)/%.o: %.s
	@mkdir -p `dirname $@`
	$(AS) $(ARGS_GEOS) -D bsw=1 -D drv1541=1 $(ASFLAGS) $< -o $@

xall: $(PREFIXED_GEOS_OBJS)
	$(AS) -DX16 -o kernsup/irqsup.o kernsup/irqsup.s




	(cd charset; bash convert.sh)
	$(AS) -o charset/petscii.o charset/petscii.tmp.s
	$(AS) -o charset/iso-8859-15.o charset/iso-8859-15.tmp.s

	$(LD) -C rom.cfg -o rom.bin \
		basic/basic.o \
		fplib/fplib.o \
		kernal/kernal.o \
		kernal/editor.o \
		kernal/kbdbuf.o \
		kernal/channel/channel.o \
		kernal/ieee_switch.o \
		kernal/serial.o \
		kernal/memory.o \
		kernal/lzsa.o \
		kernal/drivers/x16/x16.o \
		kernal/drivers/x16/memory.o \
		kernal/drivers/x16/screen.o \
		kernal/drivers/x16/ps2.o \
		kernal/drivers/x16/ps2kbd.o \
		kernal/drivers/x16/ps2mouse.o \
		kernal/drivers/x16/joystick.o \
		kernal/drivers/x16/clock.o \
		kernal/drivers/x16/rs232.o \
		kernal/drivers/x16/framebuffer.o \
		kernal/drivers/x16/sprites.o \
		kernal/graph/graph.o kernal/fonts/fonts.o \
		kernal/console.o \
		monitor/monitor.o \
		cbdos/zeropage.o \
		cbdos/fat32.o \
		cbdos/util.o \
		cbdos/matcher.o \
		cbdos/sdcard.o \
		cbdos/spi_rw_byte.o \
		cbdos/spi_select_device.o \
		cbdos/spi_deselect.o \
		cbdos/main.o \
		keymap/keymap.o \
		charset/petscii.o charset/iso-8859-15.o \
		kernsup/kernsup_basic.o kernsup/kernsup_monitor.o kernsup/irqsup.o \
		$(PREFIXED_GEOS_OBJS) \
		-Ln rom.txt -m rom.map

xclean:
	rm -f kernsup/*.o
	rm -f basic/basic.o fplib/fplib.o kernal/kernal.o rom.bin
	rm -f monitor/monitor.o monitor/monitor_support.o
	rm -f cbdos/*.o
	rm -f keymap/keymap.o
	rm -f charset/petscii.o charset/iso-8859-15.o charset/iso-8859-15.tmp.s
	rm -f kernal/graph.*.o kernal/fonts/*.o
	rm -f kernal/drivers/x16/*.o
	rm -rf build
