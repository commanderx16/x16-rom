ifdef RELEASE_VERSION
	VERSION_DEFINE="-DRELEASE_VERSION=$(RELEASE_VERSION)"
endif
ifdef PRERELEASE_VERSION
	VERSION_DEFINE="-DPRERELEASE_VERSION=$(PRERELEASE_VERSION)"
endif

ARGS:=-g

ROM_C64_OBJ := \
basic/basic-c64.o \
kernal/kernal-c64.o

ROM_X16_OBJ := \
basic/basic.o \
kernal/kernal.o \
monitor/monitor.o \
cbdos/fat32.o \
cbdos/util.o \
cbdos/matcher.o \
cbdos/sdcard.o \
cbdos/spi_r_byte.o \
cbdos/spi_rw_byte.o \
cbdos/spi_select_device.o \
cbdos/spi_deselect.o \
cbdos/main.o \
keymap/keymap.o \
charset/charset.o

.PHONY : all
all: rom.bin rom-c64.bin

# C64

rom-c64.bin : DEFINES=$(VERSION_DEFINE)
rom-c64.bin : $(ROM_C64_OBJ) rom-c64.txt rom-c64.cfg
	ld65 -C rom-c64.cfg -o $@ $(ROM_C64_OBJ) -Ln rom-c64.txt

basic-c64.bin : rom-c64.bin
	dd if=$< of=$@ bs=8k skip=0 count=1

kernal-c64.bin : rom-c64.bin
	dd if=$< of=$@ bs=8k skip=1 count=1

%-c64.o : %.s
	ca65 $(ARGS) -DC64 $(DEFINES) -o $@ $^

# X16

rom.bin : DEFINES=-DPS2 -DCBDOS -DMACHINE_X16=1 -DCPU_65C02=1
rom.bin : $(ROM_X16_OBJ) rom.cfg rom.txt
	ld65 -C rom.cfg -o $@ $(ROM_X16_OBJ) -Ln rom.txt

# Rules

%.o : %.asm
	ca65 $(ARGS) $(DEFINES) -o $@ $^

%.o : %.s
	ca65 $(ARGS) $(DEFINES) -o $@ $^

.PHONY : clean
clean:
	-rm -f $(ROM_C64_OBJ) $(ROM_X16_OBJ)
