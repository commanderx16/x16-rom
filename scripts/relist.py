#!/usr/bin/env python3
from dataclasses import dataclass
import os
import sys
import re
from typing import *
import glob

@dataclass
class Segment:
    name: str = ""
    offset: int = 0
    size: int = 0

class Module:
    def __init__(self, module_name):
        self.name = module_name
        self.segments = {}

    def add_segment(self, name: str, offset: int, size: int):
        self.segments[name] = Segment(name, offset, size)

    def get_unique_name(self) -> str:
        segs = list(self.segments.values())
        segs.sort(key= lambda v: v.name)
        segment_name_size = ([f"{s.name}_{s.size}" for s in segs])
        return f"{self.name}_{'_'.join(segment_name_size)}"

    def get_segment_offset(self, segment_name):
        return self.segments[segment_name].offset

# Scan the map file for modules and segments. Note that module names do not uniquely identify a module. See scan_lst below.
# TODO: It's probably more efficient for scan map to return a map of all modules, not just the one we're interested during
#       this iteration.
def scan_map(map_filename: str, lst_filename:str) -> Tuple[Dict[str,Segment],Dict[str,Module]]:
    segment_matcher = re.compile("^([A-Z][A-Z0-9_]*) *([0-9A-F]{6})  ([0-9A-F]{6})  ([0-9A-F]{6})  ([0-9A-F]{5})$")
    segment_map: Dict[str,Segment] = {}
    module_map: Dict[str,Module] = {}
    lst_matcher = re.compile("^    ([A-Z][A-Z0-9_]*) *Offs=([0-9A-F]{6})  Size=([0-9A-F]{6})  Align=([0-9A-F]{5})  Fill=([0-9A-F]{4})$")
    obj_filename = f"{os.path.basename(os.path.splitext(lst_filename)[0])}.o:"

    # print(f"Looking for {os.path.basename(os.path.splitext(lst_filename)[0])}.o")

    with open(map_filename) as f:
        line_num = 0
        reading_segments = False
        reading_module_segments = False
        cur_module: Module = None
        for line in f:
            line_num += 1

            if line.rstrip() == obj_filename:
                module_name = os.path.splitext(obj_filename)[0]
                if not module_name in module_map:
                    module_map[module_name] = []
                cur_module = Module(module_name)
                module_map[module_name].append(cur_module)
                # print(f"Found module {obj_filename} on line {line_num}")
                reading_module_segments = True
            elif reading_module_segments:
                match = lst_matcher.match(line)
                if match:
                    name, _offs, _size, _, _ = match.groups()
                    offs = int(_offs, 16)
                    size = int(_size, 16)
                    s = Segment(name, offs, size)
                    cur_module.add_segment(name, offs, size)
                    # print(f"Found module segment {name}")
                else:
                    reading_module_segments = False
                    cur_module = None
            elif line.rstrip() == "Segment list:":
                # print(f"Found segment list on line {line_num}")
                reading_segments = True
            elif reading_segments:
                if line.rstrip() == "":
                    # print(f"Segment list finished on line {line_num}")
                    reading_segments = False
                match = segment_matcher.match(line)
                if match:
                    name, _start, _, _size, _ = match.groups()
                    start = int(_start, 16)
                    size = int(_size, 16)
                    segment_map[name] = Segment(name, start, size)
                    # print(f"Found segment {name}")
        # print(f"Done reading {line_num} lines")
        return segment_map, module_map

# Because the map file stores modules by object file name with no path, we need to determine which lst files go with which
# module file. We do this by creating a "hopefully unique" fingerprint of the module consisting of the module name, and
# each segment and the size of the segment for that module. E.g.: the module
# memory.o:
#    MEMDRV            Offs=000000  Size=00011E  Align=00001  Fill=0000
#    KERNRAM           Offs=000000  Size=00001E  Align=00001  Fill=0000
#    KERNRAM2          Offs=000000  Size=000037  Align=00001  Fill=0000
# should get the "hopefully unique" name 'memory_KERNRAM_30_KERNRAM2_52_MEMDRV_286'. The order of the segments is sorted
# so that they should always match.
#
# This shortcoming of ld65 is the entire reason we need to perform this scan.
def scan_lst(lst_filename) -> Module:
    # I really hope these regex's continue working in the future.
    lst_matcher = re.compile("^([0-9A-F]{6})r \\d  ([0-9A-F][0-9A-F] |   |xx )([0-9A-F][0-9A-F] |   |xx )([0-9A-F][0-9A-F] |   |xx )([0-9A-F][0-9A-F] |   |xx ) $")
    seg_matcher = re.compile(r'^\s*\.segment "([A-Z_][A-Z0-9_]*)"')
    base_lst_filename = os.path.basename(os.path.splitext(lst_filename)[0])
    module = Module(base_lst_filename)
    with open(lst_filename) as f:
        line_num = 0
        cur_segment = None
        cur_size = 0
        for line in f:
            line_num += 1
            lst_part = line[0:24]
            code_part = line[24:]
            segment_match = seg_matcher.match(code_part)
            if segment_match:
                if cur_segment != None:
                    # print(f"Creating new segment {cur_segment} of size {cur_size}")
                    s = Segment(cur_segment, 0, cur_size)
                    module.add_segment(cur_segment, 0, cur_size)
                cur_segment = segment_match.groups()[0]
                cur_size = 0
                # print(f"Scanning new segment {cur_segment}")
            else:
                lst_match = lst_matcher.match(lst_part)
                if lst_match:
                    ops = [x for x in lst_match.groups()[1:] if x.strip() != '']
                    if len(ops) > 0:
                        cur_size = int(lst_match.groups()[0], 16) + len(ops)
        if cur_segment != None:
            # print(f"Creating new segment {cur_segment} of size {cur_size}")
            s = Segment(cur_segment, 0, cur_size)
            module.add_segment(cur_segment, 0, cur_size)
    # print(f"Done scanning {lst_filename}")
    return module

# re-lst the lst file with offsets.
def relst(lst_filename,module,rlst_file) -> None:
    # for k,v in module.segments.items():
    #     print(f"key = {k}, value = {v}")
    lst_matcher = re.compile("^([0-9A-F]{6})r \\d  ([0-9A-F][0-9A-F] |   )([0-9A-F][0-9A-F] |   )([0-9A-F][0-9A-F] |   )([0-9A-F][0-9A-F] |   ) $")
    seg_matcher = re.compile(r'^\s*\.segment "([A-Z_][A-Z0-9_]*)"')
    with open(lst_filename) as f:
        line_num = 0
        cur_segment:Segment = None
        for line in f:
            line_num += 1
            lst_part = line[0:24]
            code_part = line[24:]
            segment_match = seg_matcher.match(code_part)
            if segment_match:
                match_name = segment_match.group(1)
                if match_name in module.segments:
                    # print(f"Found segment match for {match_name}")
                    cur_segment = module.segments[segment_match.group(1)]
                else:
                    # print(f"WARNING: Could not find segment matching '{match_name}' in {module.segments.items()}")
                    cur_segment = None
            elif cur_segment:
                lst_match = lst_matcher.match(lst_part)
                if lst_match:
                    # Found a normal lst file line, replace its relative offset with the absolute offset.
                    location = int(lst_match.group(1),16) + cur_segment.offset
                    rlst_file.write(f"{location:06X} a {line[9:].rstrip()}\n")
                    # print(f"{location:06X} a {line[9:].rstrip()}")

# Process a map and lst file.
def process(map_filename, lst_filename):
    # print(f"Processing {lst_filename}")
    module_base_name = os.path.basename(os.path.splitext(lst_filename)[0])
    # Scan map file
    sm, mm = scan_map(map_filename, lst_filename)
    module_map: Dict[str,Module] = mm
    segment_map: Dict[str,Segment] = sm
    # Scan lst file
    module:Module = scan_lst(lst_filename)
    # print(f"Found module {module.get_unique_name()}")
    for m in module_map[module_base_name]:
        if m.get_unique_name() == module.get_unique_name():
            # print("Found matching map entry")
            for segment in module.segments.values():
                offset = segment_map[segment.name].offset + segment.offset
                # print(f"Segment {segment.name} offset ${offset:04x} ({segment_map[segment.name].offset}+{segment.offset})")
                module.segments[segment.name].offset = offset

    rlst_filename = os.path.splitext(lst_filename)[0]+".rlst"
    with open(rlst_filename, "w") as rlst_file:
        # print(f"Writing relisting to {rlst_filename}")
        relst(lst_filename, module, rlst_file)

if __name__ == "__main__":
    # Note: no command line safety here - don't make a mistake!
    map_filename = sys.argv[1]
    lst_path = sys.argv[2]
    glob_pattern = os.sep.join([lst_path,"**", "*.lst"])
    # print(f"glob pattern = {glob_pattern}")
    all_lst = glob.glob(glob_pattern, recursive=True)
    for lst in all_lst:
        process(map_filename, lst)
