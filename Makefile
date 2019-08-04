all:
	ca65 -g -DC64 -DPS2 -o basic/basic-c64.o basic/basic.s
	ca65 -g -DC64 -DPS2 -o kernal/kernal-c64.o kernal/kernal.s
	ld65 -C rom-c64.cfg -o rom-c64.bin basic/basic-c64.o kernal/kernal-c64.o -Ln rom-c64.txt
	dd if=rom-c64.bin of=basic-c64.bin bs=8k count=1
	dd if=rom-c64.bin of=kernal-c64.bin bs=8k skip=1 count=1

	ca65 -g -DPS2 -o basic/basic.o basic/basic.s
	ca65 -g -DPS2 -o kernal/kernal.o kernal/kernal.s
	ld65 -C rom.cfg -o rom.bin basic/basic.o kernal/kernal.o -Ln rom.txt

clean:
	rm -f basic/basic-c64.o kernal/kernal-c64.o rom-c64.bin basic-c64.bin kernal-c64.bin
	rm -f basic/basic.o kernal/kernal.o rom.bin
