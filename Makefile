all:
	ca65 -g basic/basic.s
	ca65 -g kernal/kernal.s
	ld65 -C rom.cfg -o rom.bin basic/basic.o kernal/kernal.o -Ln rom.txt
	#python checksum.py --new basic.bin 0xa0 0x1f52
	#python checksum.py --new kernal.bin 0xe0 0x4ac

clean:
	rm -f basic/basic.o kernal/kernal.o rom.bin
