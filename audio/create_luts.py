#!/usr/bin/env python3

# Generation script for creating lookup tables for the 
# audio bank in Commander X16 KERNAL ROM
# by MooingLemur (c) 2022

import numpy as np
import statistics
import math

def chunks(lst, n):
    """Yield successive n-sized chunks from lst."""
    for i in range(0, len(lst), n):
        yield lst[i:i + n]

def list_to_dotbyte_strings(lst):
    result = []
    for chunk in chunks(lst, 12):
        result.append("\t.byte " + ','.join(['${:02x}'.format(int(x)) for x in chunk]) + "\n")
    return result

lutfile = open("audio_luts.s","w")

# Create the PSG pitch tables 

notes = np.arange(0,128)

frequency_hz = 440 * 2**((notes-69)/12)
frequency_vera = frequency_hz * (2**17) / 48828.125

lutfile.write("; X16 audio lookup tables\n")
lutfile.write("; Most of the space is used by pitch translation tables for VERA\n\n")
lutfile.write("; LUT table created by create_luts.py by MooingLemur (c) 2022\n\n")

lutfile.write(".export kfdelta2_h,kfdelta3_h,kfdelta4_h,kfdelta5_h,kfdelta6_h,kfdelta7_h\n")
lutfile.write(".export kfdelta2_l,kfdelta3_l,kfdelta4_l,kfdelta5_l,kfdelta6_l,kfdelta7_l\n")
lutfile.write(".export midi2psg_h,midi2psg_l\n")
lutfile.write(".export midi2ymkc\n")
lutfile.write(".export ymkc2midi\n")
lutfile.write(".export midi2bas\n")
lutfile.write(".export bas2midi\n")
lutfile.write(".export fm_op_alg_carrier\n")


lutfile.write("\n.segment \"LUTS\"\n\n")

# Output the PSG pitch tables
lutfile.write("; PSG pitch tables\n")
lutfile.write("midi2psg_l:\n")

# LSBs
lutfile.write("".join(list_to_dotbyte_strings([(x.astype(int) % 256) for x in frequency_vera])))

lutfile.write("midi2psg_h:\n")

# MSBs
lutfile.write("".join(list_to_dotbyte_strings([(x.astype(int) // 256) for x in frequency_vera])))

# Create the MIDI notes to FM KC table
lutfile.write("; MIDI to YM2151 KC\n")
lutfile.write("midi2ymkc:\n")

kc = []
for n in range(128):
    if n < 13:
        kc.append(0xFF)
    elif n > 108:
        kc.append(0xFF)
    else:
        kc.append((((n-13) // 12) << 4) | (0,1,2,4,5,6,8,9,10,12,13,14)[(n-1) % 12])
    
lutfile.write("".join(list_to_dotbyte_strings(kc)))

# Create the MIDI notes to BAS table
lutfile.write("; MIDI to BAS\n")
lutfile.write("midi2bas:\n")

bc = []
for n in range(128):
    if n < 12:
        bc.append(0xFF)
    elif n > 107:
        bc.append(0xFF)
    else:
        bc.append((((n-12) // 12) << 4) | (n % 12)+1)
    
lutfile.write("".join(list_to_dotbyte_strings(bc)))


# Create the FM KC to MIDI notestable
lutfile.write("; YM2151 KC to MIDI\n")
lutfile.write("ymkc2midi:\n")

midinote = []
for n in range(128):
    octave = (n >> 4) & 7
    note = 13 + (octave * 12)
    code = (0,1,2,2,3,4,5,5,6,7,8,8,9,10,11,11)[n & 0x0f]
    note += code
    midinote.append(note)

lutfile.write("".join(list_to_dotbyte_strings(midinote)))

# Create the BAS to MIDI notestable
lutfile.write("; BAS to MIDI\n")
lutfile.write("bas2midi:\n")

midinote = []
for n in range(128):
    octave = (n >> 4) & 7
    note = 12 + (octave * 12)
    code = (n & 0x0F)-1
    if code < 0 or code > 11:
        note = 0xFF # error
    else:
        note += code
    midinote.append(note)

lutfile.write("".join(list_to_dotbyte_strings(midinote)))



# Create the KF delta tables
kf = []

for vi in range(128):
    # Calculate all of the VERA frequencies for the 256 KF values starting at note frequency_vera[vi]
    # At this point, frequency_vera[vi] is still a float
    vf = list(frequency_vera[vi] * 2**(x/3072) for x in range(256))
    for bf in range(8):
        # for each significant KF bit, find the median difference in value
        # between the bit being cleared and the bit being set
        tmp_diffs = []
        for i in range(256):
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
    # Find the error amount (in cents) for each kf and show the worst
    ec = []
    v2 = []
    for ei in range(256):
        v1 = 0
        if ei & 0x01 > 0:
            v1 += kf[0][vi]
        if ei & 0x02 > 0:
            v1 += kf[1][vi]
        if ei & 0x04 > 0:
            v1 += kf[2][vi]
        if ei & 0x08 > 0:
            v1 += kf[3][vi]
        if ei & 0x10 > 0:
            v1 += kf[4][vi]
        if ei & 0x20 > 0:
            v1 += kf[5][vi]
        if ei & 0x40 > 0:
            v1 += kf[6][vi]
        if ei & 0x80 > 0:
            v1 += kf[7][vi]
        error_cents = 100*math.log(int(frequency_vera[vi]+v1) / int(vf[ei]),2**(1/12))
        ec.append(error_cents)
        v2.append(v1)
    max_value = max(ec)
    max_index = ec.index(max_value)
    print("Note: {}, Median Deviation {:+.02f} Worst KF: ${:02x}, Deviation: {:+.02f} cents, PSG freq: Base: {:d} Calculated: {:d} Base+KF Delta: {:d}".format(vi,statistics.median(ec),max_index,max_value,int(frequency_vera[vi]),int(vf[max_index]),int(frequency_vera[vi]+v2[max_index])))
    # print(["{:+02.02f}".format(x) for x in ec[0::4]])
    # print(["{:d}".format(int(x)) for x in v2[0::4]])




# Output the KF delta tables cleverly
#
# Fortunately the high tables are either all zeroes (so those can completely overlap)
# or they share values with the beginning of the low tables but with leading zeroes
# (so they can be placed cleverly for maximum overlap)

# Start with the low bytes of bitfield 7
low7 = [(int(x) & 0xff) for x in kf[7]]
# Count the number of 0 values that we need to add so that there are 128 leading 0s
zcnt = 128 - low7.count(0)
# insert that many 0's to the beginning of low0 and make a new list
overlap = ([0]*zcnt) + low7

# Output the KF delta conversion bitfield tables (High)

# Print the first label
lutfile.write("; KF bit {:d} delta per MIDI note (high)\n".format(0))
lutfile.write("kfdelta{:d}_h:\n".format(0))

# Handle the data and the rest of the high labels
for bf in range(1,8):
    thishigh = [(int(x) // 256) for x in kf[bf]]
    z = []
    while thishigh != overlap[0:128]:
        try:
            z.append(overlap.pop(0))
        except:
            raise Exception("We expected proper overlap and we didn't get it.")
    if len(z) > 0:
        lutfile.write("".join(list_to_dotbyte_strings([int(x) for x in z])))
    lutfile.write("; KF bit {:d} delta per MIDI note (high)\n".format(bf))
    lutfile.write("kfdelta{:d}_h:\n".format(bf))

# Output the KF delta conversion bitfield tables (Low)

for bf in range(8):
    thislow = [(int(x) & 0xff) for x in kf[bf]]
    z = []
    while thislow != overlap[0:128]:
        try:
            z.append(overlap.pop(0))
        except:
            raise Exception("We expected proper overlap and we didn't get it.")
    if len(z) > 0:
        lutfile.write("".join(list_to_dotbyte_strings([int(x) for x in z])))
    lutfile.write("; KF bit {:d} delta per MIDI note (low)\n".format(bf))
    lutfile.write("kfdelta{:d}_l:\n".format(bf))

if overlap != low7:
    raise Exception("The remainder of the nonoverlapping bytes should match the final data block, but for some reason it does not.")

# Output final bytes
lutfile.write("".join(list_to_dotbyte_strings([int(x) for x in overlap])))

# FM alg+op -> carrier
lutfile.write("""
; Lookup table to find whether op is a carrier, per alg
fm_op_alg_carrier:
\t; ALG   0   1   2   3   4   5   6   7
\t.byte $00,$00,$00,$00,$00,$00,$00,$01 ; M1 (1)
\t.byte $00,$00,$00,$00,$00,$01,$01,$01 ; M2 (3)
\t.byte $00,$00,$00,$00,$01,$01,$01,$01 ; C1 (2)
\t.byte $01,$01,$01,$01,$01,$01,$01,$01 ; C2 (4)
\t; alg 0  1->2->3->4
\t; alg 1  (1+2)->3->4
\t; alg 2  (1+(2->3))->4
\t; alg 3  ((1->2)+3)->4
\t; alg 4  1->2, 3->4
\t; alg 5  1->(2+3+4)
\t; alg 6  1->2, 3, 4
\t; alg 7  1, 2, 3, 4

""")
