all:
	ca65 -g -DC64 -DPS2 -o basic/basic-c64.o basic/basic.s
	ca65 -g -DC64 -DPS2 -o kernal/kernal-c64.o kernal/kernal.s
	ld65 -C rom-c64.cfg -o rom-c64.bin basic/basic-c64.o kernal/kernal-c64.o -Ln rom-c64.txt
	dd if=rom-c64.bin of=basic-c64.bin bs=8k count=1
	dd if=rom-c64.bin of=kernal-c64.bin bs=8k skip=1 count=1

	ca65 -DPS2 -o basic/basic.o basic/basic.s
	ca65 -g -DPS2 -DCBDOS -o kernal/kernal.o kernal/kernal.s
	ca65 -DMACHINE_X16=1 -DCPU_65C02=1 monitor/monitor.s -o monitor/monitor.o
	ca65 -g -o cbdos/fat32.o cbdos/fat32.asm
	ca65 -g -o cbdos/util.o cbdos/util.asm
	ca65 -g -o cbdos/matcher.o cbdos/matcher.asm
	ca65 -g -o cbdos/main.o cbdos/main.asm
	ld65 -C rom.cfg -o rom.bin basic/basic.o kernal/kernal.o monitor/monitor.o cbdos/fat32.o cbdos/util.o cbdos/matcher.o cbdos/main.o -Ln rom.txt


clean:
	rm -f basic/basic-c64.o kernal/kernal-c64.o rom-c64.bin basic-c64.bin kernal-c64.bin
	rm -f basic/basic.o kernal/kernal.o rom.bin
	rm -f monitor/monitor.o monitor/monitor_support.o
	rm -f cbdos/*.o
