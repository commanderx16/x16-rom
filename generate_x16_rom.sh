#!/bin/bash

dd if=/dev/zero bs=8k count=1 status=none | tr "\000" "\377" > bank_empty.bin
dd if=rom.bin of=bankh_kernal.bin bs=8k count=1 skip=1 status=none

rm -f x16rom.bin
for x in 0 2 3 4 5 6 7 8
do
	dd if=rom.bin of=bankl_tmp.bin bs=8k count=1 skip=$x status=none
	if [ -s bankl_tmp.bin ]; then
		cat bankl_tmp.bin >> x16rom.bin
	else
		cat bank_empty.bin >> x16rom.bin
	fi
	cat bankh_kernal.bin >> x16rom.bin
done

rm -f bank_empty.bin bankh_kernal.bin bankl_tmp.bin
