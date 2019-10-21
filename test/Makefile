all: perf.diff.txt add.diff.txt

perf.diff.txt: perf.orig.txt perf.txt
	-diff perf.orig.txt perf.txt > perf.diff.txt

add.diff.txt: add.orig.txt add.txt
	-diff add.orig.txt add.txt > add.diff.txt

perf.txt: ../rom.bin perf.bas
	x16emu -rom ../rom.bin -bas perf.bas -echo | tee perf.txt

add.txt: ../rom.bin add.bas
	x16emu -rom ../rom.bin -bas add.bas -echo | tee add.txt

perf.orig.txt: ~/bin/rom-orig.bin perf.bas
	x16emu -rom ~/bin/rom-orig.bin -bas perf.bas -echo | tee perf.orig.txt

add.orig.txt: ~/bin/rom-orig.bin add.bas
	x16emu -rom ~/bin/rom-orig.bin -bas add.bas  -echo | tee add.orig.txt

clean:
	-rm perf.orig.txt perf.txt
	-rm add.orig.txt add.txt
	-rm perf.diff.txt add.diff.txt
	-rm dump*.bin
