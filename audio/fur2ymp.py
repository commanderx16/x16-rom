#!/usr/bin/env python3

# Generation script for creating YM2151 patches for the
# audio bank in Commander X16 KERNAL ROM
# 
# It parses .fur and .fui files for OPM and OPN instruments
# and outputs "YMP" data as ca65 source to stdout
#
# by MooingLemur (c) 2022


import sys
import zlib
import argparse
import re
from struct import unpack, pack

def chunks(lst, n):
    """Yield successive n-sized chunks from lst."""
    for i in range(0, len(lst), n):
        yield lst[i:i + n]

def list_to_dotbyte_strings(lst):
    result = []
    for chunk in chunks(lst, 8):
        result.append("\t.byte " + ','.join(['${:02X}'.format(int(x)) for x in chunk]) + "\n")
    return result

def extract_instrument_v127(ins):
    format_version = unpack("<H",ins[0:2])[0]
    instrument_type = unpack("<H",ins[2:4])[0]
    instrument_name = "Untitled"
    instrument_has_macros = False
    instrument_affected_by_lfo = False
    instrument_uses_eg = False

    ympdata = [0]*26

    if instrument_type == 1 or instrument_type == 33: # OPN, OPM
        ins = ins[4:]
        while len(ins) >= 4:
            feature = ins[0:2]
            feature_length = unpack("<H",ins[2:4])[0]
            if feature == b'NA': # Instrument name
                tmpnam = (ins[4:].split(b'\x00'))[0]
                instrument_name = tmpnam.decode('utf-8')
                if debug:
                    sys.stderr.write("Instrument name is '{}'\n".format(instrument_name))
                ins = ins[4+feature_length:]
                continue
            elif feature == b'MA': # Macros
                if debug:
                    sys.stderr.write("MA: Macros\n")
                instrument_has_macros = True
            elif feature == b'O1': # Macros
                if debug:
                    sys.stderr.write("O1: Macros\n")
                instrument_has_macros = True
            elif feature == b'O2': # Macros
                if debug:
                    sys.stderr.write("O2: Macros\n")
                instrument_has_macros = True
            elif feature == b'O3': # Macros
                if debug:
                    sys.stderr.write("O3: Macros\n")
                instrument_has_macros = True
            elif feature == b'O4': # Macros
                if debug:
                    sys.stderr.write("O4: Macros\n")
                instrument_has_macros = True
            elif feature == b'FM': # FM data, the meat
                # [4] Flags: Skip 
                # [5] ALG and FB.  Combine with RL turned on
                tmp = ins[5]
                ympdata[0] = (0xC0 | ((tmp & 0x07) << 3) | ((tmp & 0x70) >> 4))
                # [6] PMS and AMS
                tmp = ins[6]
                ympdata[1] = (((tmp & 0x07) << 4) | ((tmp & 0x18) >> 3))
                if (ympdata[1] & 0x70) > 0:
                    instrument_affected_by_lfo = True
                # [7] AM2|4|LLPatch: Skip
                for i in range(4):
                    x = i*8
                    y = i
                    # [8,16,24,32] DT1 and MUL
                    tmp = ins[8+x]
                    ympdata[2+y] = (tmp & 0x7F)
                    # [9,17,25,33] TL
                    tmp = ins[9+x]
                    ympdata[6+y] = (tmp & 0x7F)
                    # [10,18,26,34] KS and AR
                    tmp = ins[10+x]
                    ympdata[10+y] = (tmp & 0xDF)
                    # [11,19,27,35] AMSEN and D1R
                    tmp = ins[11+x]
                    ympdata[14+y] = (tmp & 0x9F)
                    if (ympdata[1] & 0x07) > 0 and (ympdata[14+y] & 0x80):
                        instrument_affected_by_lfo = True
                    # [12,20,28,36] D2R (we get DT2 later)
                    tmp = ins[12+x]
                    ympdata[18+y] = (tmp & 0x1F)
                    if (tmp & 0x80) > 0:
                        instrument_uses_eg = True
                    # [13,21,29,37] D1L and RR
                    tmp = ins[13+x]
                    ympdata[22+y] = tmp
                    # [14,22,30,38] Parameters not on OPM: Skip
                    # [15,23,31,39] DT2
                    tmp = ins[15+x]
                    ympdata[18+y] = ympdata[18+y] | ((tmp & 0x18) << 3)

            else:
                if debug:
                    sys.stderr.write("Skipping unsupported feature: '{}'\n".format(feature.decode('utf-8')))
            ins = ins[4+feature_length:]
            continue
        print("\n; {}".format(instrument_name))
        if instrument_has_macros:
            print("; WARNING: Instrument has macros")
        if instrument_uses_eg:
            print("; WARNING: Instrument uses OPN SSG-EG")
        if instrument_affected_by_lfo:
            print("; Instrument is affected by LFO")
        print("{}:".format(re.sub("^([0-9])",r"M\1",re.sub("[^A-Za-z0-9]","_",instrument_name))))
        print("".join(list_to_dotbyte_strings(ympdata[0:2])), end='')
        print("".join(list_to_dotbyte_strings(ympdata[2:])), end='')

    else:
        if debug:
            sys.stderr.write("Skipping instrument type {}\n".format(instrument_type))
    return



parser = argparse.ArgumentParser()
inputgroup = parser.add_mutually_exclusive_group()
inputgroup.add_argument("-i", metavar="input.fur", type=argparse.FileType('rb'), help='Input FUR/FUI file')

args = parser.parse_args()

debug = False

if args.i is not None:
    fur = args.i.read()

    # zlib uncompress if it is compressed
    try:
        z = zlib.decompress(fur)
        fur = z
    except:
        pass

    while len(fur) > 0:
        # Check for chunk type
        if fur[0:16] == b'-Furnace module-':
            if debug:
                sys.stderr.write(".fur module\n")
            fur = fur[32:]
            continue
        elif fur[0:4] == b'INS2':
            if debug:
                sys.stderr.write("INS2 (v127+ instrument)\n")
            blocklen = unpack("<L",fur[4:8])[0]
            extract_instrument_v127(fur[8:8+blocklen])
            fur = fur[8+blocklen:]
            continue
        elif fur[0:4] == b'FINS':
            if debug:
                sys.stderr.write("FINS (v127+ standalone instrument)\n")
            extract_instrument_v127(fur[4:])
            fur = fur[len(fur):]
            continue        
        else:
            if debug:
                sys.stderr.write("Skipped {:s} Block\n".format(fur[0:4].decode('utf-8')))
            blocklen = unpack("<L",fur[4:8])[0]
            fur = fur[8+blocklen:]
            continue   
