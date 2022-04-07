#!/usr/bin/env python3
import sys

map = {}

filenames = sys.argv[1:]
for filename in filenames:
	for line in open(filename).readlines():
		if line[2] >= 'C':
			addr = int(line[2:6], 16)
			asm = line[24:].rstrip()
			asm = asm.replace('"', '\\"')
			if asm != '' and asm != ';':
				if addr in map:
					map[addr] += '\n'+asm
				else:
					map[addr] = asm
				#print(str(addr) + '|' + asm)

for addr in range(0xc000, 0x10000):
	if addr in map:
		print('\"' + map[addr] + '\",')
	else:
		print('\"\",')
