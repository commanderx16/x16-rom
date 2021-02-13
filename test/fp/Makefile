ROM_NEW  = ~/git/MJoergen/x16-rom/build/x16/rom.bin
ROM_ORIG = ~/git/commanderx16/x16-rom/build/x16/rom.bin

X16EMU = ~/git/commanderx16/x16-emulator/x16emu

all: math.diff.txt perf.diff.txt add.diff.txt mult.diff.txt


math.diff.txt: math.orig.txt math.txt
	-diff math.orig.txt math.txt > math.diff.txt

perf.diff.txt: perf.orig.txt perf.txt
	-diff perf.orig.txt perf.txt > perf.diff.txt

add.diff.txt: add.orig.txt add.txt
	-diff add.orig.txt add.txt > add.diff.txt

mult.diff.txt: mult.orig.txt mult.txt
	-diff mult.orig.txt mult.txt > mult.diff.txt


math.txt: $(ROM_NEW) math.bas
	$(X16EMU) -rom $(ROM_NEW) -bas math.bas -echo -run | grep -v Dumped | tee math.txt

perf.txt: $(ROM_NEW) perf.bas
	$(X16EMU) -rom $(ROM_NEW) -bas perf.bas -echo -run | grep -v Dumped | tee perf.txt

add.txt: $(ROM_NEW) add.bas
	$(X16EMU) -rom $(ROM_NEW) -bas add.bas -echo -run | grep -v Dumped | tee add.txt

mult.txt: $(ROM_NEW) mult.bas
	$(X16EMU) -rom $(ROM_NEW) -bas mult.bas -echo -run | grep -v Dumped | tee mult.txt


math.orig.txt: $(ROM_ORIG) math.bas
	$(X16EMU) -rom $(ROM_ORIG) -bas math.bas -echo -run | grep -v Dumped | tee math.orig.txt

perf.orig.txt: $(ROM_ORIG) perf.bas
	$(X16EMU) -rom $(ROM_ORIG) -bas perf.bas -echo -run | grep -v Dumped | tee perf.orig.txt

add.orig.txt: $(ROM_ORIG) add.bas
	$(X16EMU) -rom $(ROM_ORIG) -bas add.bas -echo -run | grep -v Dumped | tee add.orig.txt

mult.orig.txt: $(ROM_ORIG) mult.bas
	$(X16EMU) -rom $(ROM_ORIG) -bas mult.bas -echo -run | grep -v Dumped | tee mult.orig.txt

clean:
	-rm math.orig.txt math.txt
	-rm perf.orig.txt perf.txt
	-rm add.orig.txt add.txt
	-rm mult.orig.txt mult.txt
	-rm math.diff.txt perf.diff.txt add.diff.txt mult.diff.txt
	-rm dump*.bin

