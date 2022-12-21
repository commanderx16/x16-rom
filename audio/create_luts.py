#!/usr/bin/env python3

import numpy as np

lutfile = open("audio_luts.s","w")

# Create the PSG pitch tables 

notes = np.arange(0,127)

frequency_hz = 440 * 2**((notes-69)/12)
frequency_vera = frequency_hz * (2**17) / 48828.125

lutfile.write("; PSG pitch tables\n")
lutfile.write("midi2psg_l:\n")
lutfile.write("\t.byte ")

# LSBs
lutfile.write(','.join(['${:02x}'.format(x.astype(int) % 256) for x in frequency_vera]))

lutfile.write("\n")
lutfile.write("midi2psg_h:\n")
lutfile.write("\t.byte ")

# MSBs
lutfile.write(','.join(['${:02x}'.format(x.astype(int) // 256) for x in frequency_vera]))
lutfile.write("\n")

# Create the MIDI notes to FM KC table
lutfile.write("; MIDI to YM2151 KC\n")
lutfile.write("midi2ymkc:\n")
lutfile.write("\t.byte ")

kc = []
for n in range(0,127):
    if n < 13:
        kc.append(0x00)
    elif n > 108:
        kc.append(0x7E)
    else:
        kc.append((((n-13) // 12) << 4) | (0,1,2,4,5,6,8,9,10,12,13,14)[(n-1) % 12])
    
lutfile.write(','.join(['${:02x}'.format(x) for x in kc]))
lutfile.write("\n")
