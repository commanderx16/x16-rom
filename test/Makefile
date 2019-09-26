.PHONY: all clean

all: test.prg

test.prg: test_jsrfar.s test.cfg
	cl65 -C test.cfg -o test.prg test_jsrfar.s

clean:
	rm *.o *.prg
