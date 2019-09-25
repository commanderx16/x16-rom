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
cbdos/spi_rw_byte.o \
cbdos/spi_select_device.o \
cbdos/spi_deselect.o \
cbdos/main.o \
keymap/keymap.o \
charset/charset.o \
charset/iso-8859-15.o \

.PHONY : all x16 c64
all : x16 c64
x16 : rom.bin
c64 : basic-c64.bin kernal-c64.bin rom-c64.bin

# C64

rom-c64.bin : DEFINES=$(VERSION_DEFINE)
rom-c64.bin rom-c64.txt : $(ROM_C64_OBJ) rom-c64.cfg
	ld65 -C rom-c64.cfg -o $@ $(ROM_C64_OBJ) -Ln rom-c64.txt

basic-c64.bin : rom-c64.bin
	dd if=$< of=$@ bs=8k skip=0 count=1

kernal-c64.bin : rom-c64.bin
	dd if=$< of=$@ bs=8k skip=1 count=1

%-c64.o : %.s
	ca65 $(ARGS) -DC64 $(DEFINES) -o $@ $^

# X16

rom.bin : DEFINES=-DPS2 -DCBDOS -DMACHINE_X16=1 -DCPU_65C02=1
rom.bin rom.txt : $(ROM_X16_OBJ) rom.cfg
	ld65 -C rom.cfg -o $@ $(ROM_X16_OBJ) -Ln rom.txt

charset/iso-8859-15.o : charset/iso-8859-15.s
	cat $^ | sed -e "s/$(echo -e "\xE2\x96\x88")/1/g" | sed -e s/_/0/g > charset/iso-8859-15.tmp.s
	ca65 $(ARGS) $(DEFINES) -o $@ charset/iso-8859-15.tmp.s

# Rules

%.o : %.asm
	ca65 $(ARGS) $(DEFINES) -o $@ $^

%.o : %.s
	ca65 $(ARGS) $(DEFINES) -o $@ $^

.PHONY : clean
clean:
	-rm -f $(ROM_C64_OBJ) $(ROM_X16_OBJ)
	-rm -f charset/iso-8859-15.tmp.s
	-rm -f rom.bin rom.txt
	-rm -f basic-c64.bin kernal-c64.bin rom-c64.bin rom-c64.txt
