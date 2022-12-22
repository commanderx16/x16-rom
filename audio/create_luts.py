#!/usr/bin/env python3

import numpy as np
import statistics

lutfile = open("audio_luts.s","w")

# Create the PSG pitch tables 

notes = np.arange(0,128)

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
for n in range(128):
    if n < 13:
        kc.append(0x00)
    elif n > 108:
        kc.append(0x7E)
    else:
        kc.append((((n-13) // 12) << 4) | (0,1,2,4,5,6,8,9,10,12,13,14)[(n-1) % 12])
    
lutfile.write(','.join(['${:02x}'.format(x) for x in kc]))
lutfile.write("\n")

# Create the KF diff tables
kf = []

for vi in range(128):
    # Calculate all of the VERA frequencies for the 64 KF values starting at note v
    # At this point, v is still a float
    vf = list(frequency_vera[vi] * 2**(x/768) for x in range(64))
    for bf in range(6):
        # for each significant KF bit, find the median difference in value
        # between the bit being cleared and the bit being set
        tmp_diffs = []
        for i in range(64):
            with_bit = (i | 2**bf)
            without_bit = with_bit - 2**bf

            tmp_diffs.append(vf[with_bit] - vf[without_bit])
        try:
            kf[bf]
        except:
            kf.append([])
        try:
            kf[bf][vi]
        except:
            kf[bf].append([])
        kf[bf][vi] = statistics.median(tmp_diffs)


for bf in range(6):
    # Create the KF conversion bitfield tables (High)
    lutfile.write("; KF bit {:d} delta per MIDI note (high)\n".format(bf+2))
    lutfile.write("kfdelta{:d}_h:\n".format(bf+2))
    lutfile.write("\t.byte ")
    lutfile.write(','.join(['${:02x}'.format(int(x) // 256) for x in kf[bf]]))
    lutfile.write("\n")


for bf in range(6):
    # Create the KF conversion bitfield tables (Low)
    lutfile.write("; KF bit {:d} delta per MIDI note (low)\n".format(bf+2))
    lutfile.write("kfdelta{:d}_l:\n".format(bf+2))
    lutfile.write("\t.byte ")
    lutfile.write(','.join(['${:02x}'.format(int(x) & 0xff) for x in kf[bf]]))
    lutfile.write("\n")





