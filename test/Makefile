all: math.diff.txt perf.diff.txt add.diff.txt mult.diff.txt

math.diff.txt: math.orig.txt math.txt
	-diff math.orig.txt math.txt > math.diff.txt

perf.diff.txt: perf.orig.txt perf.txt
	-diff perf.orig.txt perf.txt > perf.diff.txt

add.diff.txt: add.orig.txt add.txt
	-diff add.orig.txt add.txt > add.diff.txt

mult.diff.txt: mult.orig.txt mult.txt
	-diff mult.orig.txt mult.txt > mult.diff.txt


math.txt: ../rom.bin math.bas
	x16emu-orig -rom ../rom.bin -bas math.bas -echo | tee math.txt

perf.txt: ../rom.bin perf.bas
	x16emu-orig -rom ../rom.bin -bas perf.bas -echo | tee perf.txt

add.txt: ../rom.bin add.bas
	x16emu-orig -rom ../rom.bin -bas add.bas -echo | tee add.txt

mult.txt: ../rom.bin mult.bas
	x16emu-orig -rom ../rom.bin -bas mult.bas -echo | tee mult.txt


math.orig.txt: ~/bin/rom-orig.bin math.bas
	x16emu-orig -rom ~/bin/rom-orig.bin -bas math.bas -echo | tee math.orig.txt

perf.orig.txt: ~/bin/rom-orig.bin perf.bas
	x16emu-orig -rom ~/bin/rom-orig.bin -bas perf.bas -echo | tee perf.orig.txt

add.orig.txt: ~/bin/rom-orig.bin add.bas
	x16emu-orig -rom ~/bin/rom-orig.bin -bas add.bas  -echo | tee add.orig.txt

mult.orig.txt: ~/bin/rom-orig.bin mult.bas
	x16emu-orig -rom ~/bin/rom-orig.bin -bas mult.bas  -echo | tee mult.orig.txt

clean:
	-rm math.orig.txt math.txt
	-rm perf.orig.txt perf.txt
	-rm add.orig.txt add.txt
	-rm mult.orig.txt mult.txt
	-rm math.diff.txt perf.diff.txt add.diff.txt mult.diff.txt
	-rm dump*.bin
