all:
	ca65 -g fat32.asm
	ca65 -g util.asm
	ca65 -g support.asm
	ca65 -g matcher.asm
	ld65 -C cbdos.cfg support.o fat32.o util.o matcher.o -o rom.bin -Ln rom.txt

clean:
	rm -f *.bin *.o
