
MACHINE     ?= x16
# also supported:
# * c64

ifdef RELEASE_VERSION
	VERSION_DEFINE="-DRELEASE_VERSION=$(RELEASE_VERSION)"
endif
ifdef PRERELEASE_VERSION
	VERSION_DEFINE="-DPRERELEASE_VERSION=$(PRERELEASE_VERSION)"
endif

AS           = ca65
LD           = ld65

# global includes
ASFLAGS     += -I inc
# for GEOS
ASFLAGS     += -D bsw=1 -D drv1541=1 -I geos/inc -I geos
# for monitor
ASFLAGS     += -D CPU_65C02=1
# KERNAL version number
ASFLAGS     +=  $(VERSION_DEFINE)
# put all symbols into .sym files
ASFLAGS     += -g

ifeq ($(MACHINE),x16)
ASFLAGS     += -D MACHINE_X16=1
# all files are allowed to use 65SC02 features
ASFLAGS     += --cpu 65SC02
else # c64
ASFLAGS     += -D MACHINE_C64=1
endif

BUILD_DIR=build/$(MACHINE)

KERNAL_CORE_SOURCES = \
	kernal/kernal.s \
	kernal/editor.s \
	kernal/kbdbuf.s \
	kernal/channel/channel.s \
	kernal/serial.s \
	kernal/memory.s \
	kernal/lzsa.s

KERNAL_GRAPH_SOURCES = \
	kernal/console.s \
	kernal/graph/graph.s \
	kernal/fonts/fonts.s

ifeq ($(MACHINE),c64)
	KERNAL_DRIVER_SOURCES = \
		kernal/drivers/c64/c64.s \
		kernal/drivers/c64/clock.s \
		kernal/drivers/c64/joystick.s \
		kernal/drivers/c64/kbd.s \
		kernal/drivers/c64/memory.s \
		kernal/drivers/c64/mouse.s \
		kernal/drivers/c64/rs232.s \
		kernal/drivers/c64/screen.s \
		kernal/drivers/c64/sprites.s
else
	KERNAL_DRIVER_SOURCES = \
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
		kernal/drivers/x16/sprites.s
endif

KERNAL_SOURCES = \
	$(KERNAL_CORE_SOURCES) \
	$(KERNAL_DRIVER_SOURCES)

ifneq ($(MACHINE),c64)
	KERNAL_SOURCES += \
		$(KERNAL_GRAPH_SOURCES) \
		kernal/ieee_switch.s
endif

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
	monitor/monitor.s \
	monitor/io.s \
	monitor/asm.s

CHARSET_SOURCES= \
	charset/petscii.s \
	charset/iso-8859-15.s

GENERIC_DEPS = \
	inc/kernal.inc \
	inc/mac.inc \
	inc/io.inc \
	inc/fb.inc \
	inc/banks.inc \
	inc/jsrfar.inc \
	inc/regs.inc \
	kernsup/kernsup.inc

KERNAL_DEPS = \
	$(GENERIC_DEPS) \
	kernal/fonts/fonts.inc

KEYMAP_DEPS = \
	$(GENERIC_DEPS)

CBDOS_DEPS = \
	$(GENERIC_DEPS) \
	cbdos/errno.inc \
	cbdos/debug.inc \
	cbdos/fat32.inc \
	cbdos/rtc.inc \
	cbdos/fcntl.inc \
	cbdos/spi.inc \
	cbdos/65c02.inc \
	cbdos/common.inc \
	cbdos/sdcard.inc \
	cbdos/vera.inc

GEOS_DEPS= \
	$(GENERIC_DEPS) \
	geos/config.inc \
	geos/inc/printdrv.inc \
	geos/inc/gkernal.inc \
	geos/inc/inputdrv.inc \
	geos/inc/diskdrv.inc \
	geos/inc/const.inc \
	geos/inc/jumptab.inc \
	geos/inc/geosmac.inc \
	geos/inc/geossym.inc \
	geos/inc/c64.inc

BASIC_DEPS= \
	$(GENERIC_DEPS) \
	fplib/fplib.inc

MONITOR_DEPS= \
	$(GENERIC_DEPS) \
	monitor/kernal.i

CHARSET_DEPS= \
	$(GENERIC_DEPS)

KERNAL_OBJS  = $(addprefix $(BUILD_DIR)/, $(KERNAL_SOURCES:.s=.o))
KEYMAP_OBJS  = $(addprefix $(BUILD_DIR)/, $(KEYMAP_SOURCES:.s=.o))
CBDOS_OBJS   = $(addprefix $(BUILD_DIR)/, $(CBDOS_SOURCES:.s=.o))
GEOS_OBJS    = $(addprefix $(BUILD_DIR)/, $(GEOS_SOURCES:.s=.o))
BASIC_OBJS   = $(addprefix $(BUILD_DIR)/, $(BASIC_SOURCES:.s=.o))
MONITOR_OBJS = $(addprefix $(BUILD_DIR)/, $(MONITOR_SOURCES:.s=.o))
CHARSET_OBJS = $(addprefix $(BUILD_DIR)/, $(CHARSET_SOURCES:.s=.o))

ifeq ($(MACHINE),c64)
	BANK_BINS = $(BUILD_DIR)/kernal.bin
else
	BANK_BINS = \
		$(BUILD_DIR)/kernal.bin \
		$(BUILD_DIR)/keymap.bin \
		$(BUILD_DIR)/cbdos.bin \
		$(BUILD_DIR)/geos.bin \
		$(BUILD_DIR)/basic.bin \
		$(BUILD_DIR)/monitor.bin \
		$(BUILD_DIR)/charset.bin
endif

all: $(BUILD_DIR)/rom.bin $(BUILD_DIR)/rom_labels.h

$(BUILD_DIR)/rom.bin: $(BANK_BINS)
	cat $(BANK_BINS) > $@

clean:
	rm -rf $(BUILD_DIR)


$(BUILD_DIR)/%.o: %.s
	@mkdir -p $$(dirname $@)
	$(AS) $(ASFLAGS) $< -o $@


# Bank 0 : KERNAL
$(BUILD_DIR)/kernal.bin: $(KERNAL_OBJS) $(KERNAL_DEPS) cfg/kernal-$(MACHINE).cfg
	@mkdir -p $$(dirname $@)
	$(LD) -C cfg/kernal-$(MACHINE).cfg $(KERNAL_OBJS) -o $@ -m $(BUILD_DIR)/kernal.map -Ln $(BUILD_DIR)/kernal.sym

# Bank 1 : KEYMAP
$(BUILD_DIR)/keymap.bin: $(KEYMAP_OBJS) $(KEYMAP_DEPS) cfg/keymap-$(MACHINE).cfg
	@mkdir -p $$(dirname $@)
	$(LD) -C cfg/keymap-$(MACHINE).cfg $(KEYMAP_OBJS) -o $@ -m $(BUILD_DIR)/keymap.map -Ln $(BUILD_DIR)/keymap.sym

# Bank 2 : CBDOS
$(BUILD_DIR)/cbdos.bin: $(CBDOS_OBJS) $(CBDOS_DEPS) cfg/cbdos-$(MACHINE).cfg
	@mkdir -p $$(dirname $@)
	$(LD) -C cfg/cbdos-$(MACHINE).cfg $(CBDOS_OBJS) -o $@ -m $(BUILD_DIR)/cbdos.map -Ln $(BUILD_DIR)/cbdos.sym

# Bank 3 : GEOS
$(BUILD_DIR)/geos.bin: $(GEOS_OBJS) $(GEOS_DEPS) cfg/geos-$(MACHINE).cfg
	@mkdir -p $$(dirname $@)
	$(LD) -C cfg/geos-$(MACHINE).cfg $(GEOS_OBJS) -o $@ -m $(BUILD_DIR)/geos.map -Ln $(BUILD_DIR)/geos.sym

# Bank 4 : BASIC
$(BUILD_DIR)/basic.bin: $(BASIC_OBJS) $(BASIC_DEPS) cfg/basic-$(MACHINE).cfg
	@mkdir -p $$(dirname $@)
	$(LD) -C cfg/basic-$(MACHINE).cfg $(BASIC_OBJS) -o $@ -m $(BUILD_DIR)/basic.map -Ln $(BUILD_DIR)/basic.sym

# Bank 5 : MONITOR
$(BUILD_DIR)/monitor.bin: $(MONITOR_OBJS) $(MONITOR_DEPS) cfg/monitor-$(MACHINE).cfg
	@mkdir -p $$(dirname $@)
	$(LD) -C cfg/monitor-$(MACHINE).cfg $(MONITOR_OBJS) -o $@ -m $(BUILD_DIR)/monitor.map -Ln $(BUILD_DIR)/monitor.sym

# Bank 6 : CHARSET
$(BUILD_DIR)/charset.bin: $(CHARSET_OBJS) $(CHARSET_DEPS) cfg/charset-$(MACHINE).cfg
	@mkdir -p $$(dirname $@)
	$(LD) -C cfg/charset-$(MACHINE).cfg $(CHARSET_OBJS) -o $@ -m $(BUILD_DIR)/charset.map -Ln $(BUILD_DIR)/charset.sym

$(BUILD_DIR)/rom_labels.h: $(BANK_BINS)
	./scripts/symbolize.sh 0 build/x16/kernal.sym   > $@
	./scripts/symbolize.sh 1 build/x16/keymap.sym  >> $@
	./scripts/symbolize.sh 2 build/x16/cbdos.sym   >> $@
	./scripts/symbolize.sh 3 build/x16/geos.sym    >> $@
	./scripts/symbolize.sh 4 build/x16/basic.sym   >> $@
	./scripts/symbolize.sh 5 build/x16/monitor.sym >> $@
	./scripts/symbolize.sh 6 build/x16/charset.sym >> $@
